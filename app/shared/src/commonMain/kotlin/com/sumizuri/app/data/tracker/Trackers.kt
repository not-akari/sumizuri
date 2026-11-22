package com.sumizuri.app.data.tracker

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.text.nowMillis
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

private const val Tag = "tracker"

// How long the app waits for the person to come back from the site of a tracker. A token that comes later, or when nobody asked to sign in, is not taken.
private const val WaitMs = 10 * 60 * 1000L

// Where signing in to a tracker stands: nothing going on, the browser open on the site of the tracker, the token being checked, or why it did not work.
sealed interface SignIn {
    data object Idle : SignIn

    data object Waiting : SignIn

    data object Checking : SignIn

    data class Failed(val problem: TrackerProblem) : SignIn
}

// The trackers of a profile: who is signed in where, and signing in and out.
class Trackers(
    private val accounts: TrackerAccounts,
    private val scope: CoroutineScope,
    private val apis: TrackerApis,
    private val onSignedOut: suspend (TrackerId) -> Unit,
    private val onSignedIn: (TrackerId) -> Unit,
) {

    val signedIn: Flow<Map<TrackerId, TrackerAccount>> = accounts.accounts

    private val mutable = MutableStateFlow<Map<TrackerId, SignIn>>(emptyMap())
    val signIn: StateFlow<Map<TrackerId, SignIn>> = mutable

    // Whether this build can sign in to the tracker at all.
    fun canSignIn(tracker: TrackerId): Boolean = apis.of(tracker).hasKey

    // Whether the person signs in on the site of the tracker or with a form here.
    fun way(tracker: TrackerId): SignInWay = apis.of(tracker).signInWay

    // Starts signing in, and gives the address of the tracker to open in the browser, or null when this build cannot.
    suspend fun begin(tracker: TrackerId): String? {
        if (!canSignIn(tracker)) {
            set(tracker, SignIn.Failed(TrackerProblem.NoKey))
            return null
        }
        // The check comes back with the answer, so an answer meant for another request is never taken.
        val check = randomCheck()
        accounts.markAsked(tracker, check)
        set(tracker, SignIn.Waiting)
        return apis.of(tracker).signInAddress(check)
    }

    // The person gave up waiting for the browser.
    suspend fun cancel(tracker: TrackerId) {
        accounts.takeAsked(tracker)
        set(tracker, SignIn.Idle)
    }

    // Takes what the tracker opened the app with. Only an answer the person just asked for is taken, so a link from somewhere else can never sign the app in to an account of someone else.
    fun finish(tracker: TrackerId, answer: Map<String, String>) {
        scope.launch {
            val asked = accounts.takeAsked(tracker)
            if (asked == null || nowMillis() - asked.first > WaitMs) {
                AppLog.warn(Tag, "a sign in link for ${tracker.id} came that nobody asked for, and was left alone")
                return@launch
            }
            signInWith(tracker) { apis.of(tracker).accountFromLink(answer, asked.second) }
        }
    }

    // Signs in with an email and a password, for a tracker that has no sign in on its site. They go to the tracker only and are not kept.
    fun signInWithPassword(tracker: TrackerId, name: String, password: String) {
        scope.launch { signInWith(tracker) { apis.of(tracker).accountFromPassword(name, password) } }
    }

    // Signs in with a token the person made on the site of the tracker.
    fun signInWithToken(tracker: TrackerId, token: String) {
        scope.launch { signInWith(tracker) { apis.of(tracker).accountFromToken(token) } }
    }

    // The page of the tracker where the person makes a token.
    fun tokenPage(tracker: TrackerId): String? = apis.of(tracker).tokenPage

    // Renews the token of an account that ends soon, for the accounts kept on this device.
    suspend fun renew(tracker: TrackerId, account: TrackerAccount): TrackerAccount? = apis.of(tracker).refresh(account)

    private suspend fun signInWith(tracker: TrackerId, open: suspend () -> TrackerAccount) {
        set(tracker, SignIn.Checking)
        val state = try {
            val account = open()
            accounts.save(tracker, account)
            AppLog.info(Tag, "signed in to ${tracker.id} as ${account.name}")
            onSignedIn(tracker)
            SignIn.Idle
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            AppLog.warn(Tag, "could not sign in to ${tracker.id}, ${error.message}")
            SignIn.Failed(TrackerProblem.from(error))
        }
        set(tracker, state)
    }

    suspend fun signOut(tracker: TrackerId) {
        accounts.remove(tracker)
        onSignedOut(tracker)
        set(tracker, SignIn.Idle)
        AppLog.info(Tag, "signed out of ${tracker.id}")
    }

    // Keeps the accounts another device of the same person handed over, as if signed in here, and starts their sync. A tracker this profile is signed in to already keeps its own account. Gives how many were taken.
    suspend fun takeHanded(handed: Map<TrackerId, TrackerAccount>): Int {
        val mine = accounts.accounts.first()
        var taken = 0
        for ((tracker, account) in handed) {
            if (tracker in mine) continue
            accounts.save(tracker, account)
            onSignedIn(tracker)
            taken++
        }
        return taken
    }

    private fun set(tracker: TrackerId, state: SignIn) = mutable.update { it + (tracker to state) }
}
