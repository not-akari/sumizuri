package com.sumizuri.app.feature.sync.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.account.LibrarySyncer
import com.sumizuri.app.data.account.SyncAccount
import com.sumizuri.app.data.account.SyncAccountStore
import com.sumizuri.app.data.account.SyncClient
import com.sumizuri.app.data.account.SyncProblem
import com.sumizuri.app.data.account.SyncRun
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.feature.sync.data.ServerCopy
import com.sumizuri.app.feature.sync.signin.SyncViewModel
import com.sumizuri.sync.core.ErrorCodes
import com.sumizuri.sync.core.LibraryKeys
import com.sumizuri.sync.core.OpenLibrary
import com.sumizuri.sync.core.Role
import com.sumizuri.sync.core.SyncCrypto
import com.sumizuri.sync.core.UserChange
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.filterIsInstance
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

// The signed in sync page: the account and its devices, the library this profile links to, and the people and invites for the owner and admins. A server that does not answer is asked again after this long, then twice as long each time up to the most.
private const val RetryFirstMs = 10_000L
private const val RetryMostMs = 60_000L

class SyncHomeModel(
    private val account: SyncAccount,
    private val store: SyncAccountStore,
    private val settings: SettingsRepository,
    private val syncer: LibrarySyncer,
    private val client: SyncClient = SyncClient(),
) : ViewModel() {
    private val accountKey = SyncCrypto.fromBase64(account.accountKey)
    private val mutable = MutableStateFlow(SyncHome())
    val home: StateFlow<SyncHome> = mutable

    // What a person changes about their own account.
    val own = AccountChanges(account, store, client, accountKey, mutable) { block -> work(block = block) }

    // The role as this device keeps it now, which a hand over changes while the page is open.
    val role: Role get() = (store.account.value ?: account).role
    val isAdmin: Boolean get() = role == Role.Owner || role == Role.Admin
    val userId: Long get() = account.userId

    // The next check of a server that does not answer, and how long it waits.
    private var retry: Job? = null
    private var retryWait = RetryFirstMs / 2

    init {
        checkServer()
        load(SyncTab.Account)
    }

    // Any sync that ends, by the button, the timer or the first one after signing in, makes the copy the tabs show old, so the list of the server is read again, and the copy too where a data tab is open.
    init {
        viewModelScope.launch {
            syncer.run.drop(1).filterIsInstance<SyncRun.Done>().collect {
                mutable.update { state -> state.copy(copy = null, copyChecked = false) }
                work(quiet = true) {
                    fetchLibraries()
                    if (mutable.value.tab != SyncTab.Account && mutable.value.tab != SyncTab.Admin) loadCopy()
                }
            }
        }
    }

    fun open(tab: SyncTab) {
        mutable.update {
            it.copy(
                tab = tab,
                problem = null,
                newInvite = if (tab ==
                    SyncTab.Admin
                ) {
                    it.newInvite
                } else {
                    null
                },
            )
        }
        load(tab)
    }

    // Asks the server whether it answers. A server that does not is asked again on its own, waiting longer each time, and once it answers again the tab that is open loads again.
    fun checkServer() {
        retry?.cancel()
        val wasOffline = mutable.value.status is ServerStatus.Offline
        mutable.update { it.copy(status = ServerStatus.Checking) }
        viewModelScope.launch {
            val status = try {
                client
                    .info(account.server)
                    .also { info ->
                        mutable.update {
                            it.copy(info = info)
                        }
                    }.let { ServerStatus.Online(it.version) }
            } catch (problem: SyncProblem) {
                ServerStatus.Offline(problem)
            }
            mutable.update { it.copy(status = status, down = (status as? ServerStatus.Offline)?.problem) }
            if (status is ServerStatus.Offline) {
                retryWait = (retryWait * 2).coerceAtMost(RetryMostMs)
                retry = viewModelScope.launch {
                    delay(retryWait)
                    checkServer()
                }
            } else {
                retryWait = RetryFirstMs / 2
                if (wasOffline) load(mutable.value.tab)
            }
        }
    }

    fun removeDevice(id: Long) = work {
        client.removeDevice(account, id)
        mutable.update { home -> home.copy(devices = home.devices?.filterNot { it.id == id }) }
    }

    // Makes a library on the server and links this profile to it.
    fun makeLibrary(name: String) = work {
        val made = withContext(Dispatchers.Default) { LibraryKeys.make(name, accountKey) }
        val entry = client.newLibrary(account, made.request)
        mutable.update {
            it.copy(
                libraries =
                it.libraries.orEmpty() + OpenLibrary(entry.id, name.trim(), made.libraryKey),
            )
        }
        settings.setText(SettingKey.SyncLibraryId, entry.id.toString())
        mutable.update { it.copy(copy = null, copyChecked = false) }
    }

    // Links this profile to another library, whose copy the data tabs then fetch.
    fun link(id: Long) {
        mutable.update { it.copy(copy = null, copyChecked = false) }
        viewModelScope.launch { settings.setText(SettingKey.SyncLibraryId, id.toString()) }
    }

    // How the last sync of this profile went.
    val syncRun: StateFlow<SyncRun> = syncer.run

    // The syncs of this profile, newest first.
    val syncHistory = syncer.history

    // Forgets what this device and the server last agreed on and syncs, joining both without removing anything.
    fun syncFromScratch() = work {
        syncer.startOver()
        mutable.update { it.copy(copy = null, copyChecked = false) }
        fetchLibraries()
    }

    // Syncs this profile with its copy on the server now, by the same merge the app runs by itself. The copy the tabs show is fetched again when the sync ends.
    fun syncNow() = work {
        syncer.sync()
        fetchLibraries()
    }

    // Fetches the server's copy again, such as after another device sent a newer one.
    fun refreshCopy() = work {
        fetchLibraries()
        loadCopy()
    }

    fun makeInvite(days: Int?) = work {
        val made = client.newInvite(account, days)
        mutable.update { it.copy(newInvite = made.code, invites = listOf(made.invite) + it.invites.orEmpty()) }
    }

    fun removeInvite(id: String) = work {
        client.removeInvite(account, id)
        mutable.update { home -> home.copy(invites = home.invites?.filterNot { it.id == id }) }
    }

    // Signs this device out on the server, then forgets the account here. When the server cannot be reached the account is still forgotten here.
    fun signOut() {
        viewModelScope.launch {
            runCatching { client.signout(account) }
            store.clear()
        }
    }

    // Opens the page of one person with their devices and what they use.
    fun openPerson(id: Long) {
        mutable.update { it.copy(person = null) }
        work(quiet = true) { mutable.update { home -> home.copy(person = client.user(account, id)) } }
    }

    // Turns the open person off or on, or changes their role.
    fun changePerson(change: UserChange) = onPerson { id ->
        client.changeUser(account, id, change)
        reread(id)
    }

    fun signOutPerson() = onPerson { id ->
        client.signOutUser(account, id)
        reread(id)
    }

    // Turns off two-step sign in for the open person, who lost their authenticator app.
    fun turnOffTwoStepForPerson() = onPerson { id ->
        client.turnOffTwoStepFor(account, id)
        reread(id)
    }

    // Deletes the open person, then the page goes back to the list.
    fun deletePerson(onDone: () -> Unit) = onPerson { id ->
        client.deleteUser(account, id)
        mutable.update { it.copy(person = null) }
        refreshAdmin()
        onDone()
    }

    // Brings back the person open on the page, deleted in the last week.
    fun restorePerson() = onPerson { id ->
        client.restoreUser(account, id)
        reread(id)
    }

    // Hands the server over to the person open on the page. This account becomes an admin, as the account kept on this device then says.
    fun handOver(onDone: () -> Unit) = onPerson { id ->
        client.handOver(account, id)
        refreshRole()
        onDone()
    }

    // Runs a change on the person open on the page, when one is open.
    private fun onPerson(change: suspend (Long) -> Unit) {
        val id = mutable.value.person
            ?.user
            ?.id ?: return
        work { change(id) }
    }

    // Reads the open person and the lists of the admin page again after a change.
    private suspend fun reread(id: Long) {
        mutable.update { it.copy(person = client.user(account, id)) }
        refreshAdmin()
    }

    // Signs out every device of this account but this one.
    fun signOutOthers() = work {
        client.signOutOthers(account)
        mutable.update { it.copy(devices = client.devices(account)) }
    }

    // Reads the change log of the server.
    fun loadLog() = work(quiet = true) { mutable.update { it.copy(log = client.changeLog(account)) } }

    // Reads whether this account has two-step sign in, for a page that asks for the code with the password.
    fun loadTwoStep() = work(quiet = true) { refreshRole() }

    // The role and name of this account as the server has them now, kept on this device when they changed, such as after a hand over.
    private suspend fun refreshRole() {
        val now = client.account(account)
        mutable.update { it.copy(twoStep = now.twoStep, askCode = it.askCode || now.twoStep) }
        val kept = store.account.value ?: return
        if (kept.role != now.role ||
            kept.username != now.username
        ) {
            store.save(kept.copy(role = now.role, username = now.username))
        }
    }

    // Saves one live setting of the server. The server checks it again and turns down a pinned one.
    fun setServerSetting(key: String, value: String) = work {
        val settings = client.changeSetting(account, key, value)
        mutable.update { it.copy(serverSettings = settings, overview = client.overview(account)) }
    }

    private suspend fun refreshAdmin() {
        if (!isAdmin) return
        val users = client.users(account)
        val invites = client.invites(account)
        val overview = client.overview(account)
        val settings = client.serverSettings(account)
        mutable.update { it.copy(users = users, invites = invites, overview = overview, serverSettings = settings) }
    }

    fun dismissProblem() = mutable.update { it.copy(problem = null) }

    companion object {
        const val NoLibrary = "no_library"
        const val KeyMismatch = SyncViewModel.KeyMismatch
    }

    private fun load(tab: SyncTab) = work(quiet = true) {
        when (tab) {
            SyncTab.Account -> {
                mutable.update { it.copy(devices = client.devices(account)) }
                refreshRole()
                fetchLibraries()
            }

            // The three tabs of data share one copy, fetched once and kept while the page is open. The list of the server is read again first, as a sync since may have changed it.
            SyncTab.Library, SyncTab.Updates, SyncTab.History -> if (!mutable.value.copyChecked) {
                fetchLibraries()
                loadCopy()
            }

            SyncTab.Admin -> if (isAdmin) {
                refreshAdmin()
            }
        }
    }

    private suspend fun fetchLibraries() {
        val entries = client.libraries(account)
        val opened = withContext(Dispatchers.Default) { entries.mapNotNull { LibraryKeys.open(it, accountKey) } }
        mutable.update { it.copy(entries = entries, libraries = opened) }
    }

    // The library this profile links to, opened, or nothing while it links to none.
    private suspend fun linkedLibrary(): OpenLibrary? {
        if (mutable.value.libraries == null) fetchLibraries()
        val id = settings.textNow(SettingKey.SyncLibraryId)?.toLongOrNull() ?: return null
        return mutable.value.libraries?.firstOrNull { it.id == id }
    }

    // Fetches and opens the server's side of the linked library, its rows or an older copy. A library with nothing on the server yet leaves the tabs saying so.
    private suspend fun loadCopy() {
        val library = linkedLibrary()
        val entry = library?.let { open -> mutable.value.entries?.firstOrNull { it.id == open.id } }
        val at = entry?.rowsAt ?: entry?.snapshotAt
        val titles = if (library == null ||
            at == null
        ) {
            null
        } else {
            withContext(Dispatchers.Default) { syncer.serverTitles() }
        }
        val copy = titles?.let { ServerCopy(at ?: 0, it) }
        mutable.update { it.copy(copy = copy, copyChecked = true) }
    }

    // Runs a call to the server. A device the server signed out forgets its account, which takes the page back to signing in.
    private fun work(quiet: Boolean = false, block: suspend () -> Unit) {
        if (!quiet) mutable.update { it.copy(busy = true, problem = null) }
        viewModelScope.launch {
            try {
                block()
                mutable.update { it.copy(busy = false) }
            } catch (problem: SyncProblem) {
                if (problem.code == ErrorCodes.SignedOut) store.clear()
                // A server that does not answer shows as down above the tabs, and is asked again on its own, rather than as a problem with this one call.
                if (problem.code == SyncProblem.Unreachable) {
                    mutable.update {
                        it.copy(
                            busy = false,
                            packing = null,
                            status = ServerStatus.Offline(problem),
                            down = problem,
                        )
                    }
                    if (retry?.isActive != true) checkServer()
                    return@launch
                }
                if (problem.code == ErrorCodes.CodeNeeded) mutable.update { it.copy(askCode = true) }
                mutable.update { it.copy(busy = false, problem = problem, packing = null) }
            }
        }
    }
}
