package com.sumizuri.app.feature.browse.extensions

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.sources.RepoProblem
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.add
import com.sumizuri.app.shared.resources.extensions_add_repo
import com.sumizuri.app.shared.resources.extensions_trust
import com.sumizuri.app.shared.resources.repo_problem_address
import com.sumizuri.app.shared.resources.sources_repo_address
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import org.jetbrains.compose.resources.stringResource

// Asks for the address of a repo. It says plainly that the sources in a repo are other people's code.
@Composable
internal fun AddRepoDialog(
    state: AddRepoState,
    onAddress: (String) -> Unit,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(Res.string.extensions_add_repo)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(stringResource(Res.string.extensions_trust), style = MaterialTheme.typography.bodyMedium)
                OutlinedTextField(
                    value = state.address,
                    onValueChange = onAddress,
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text(stringResource(Res.string.sources_repo_address)) },
                    singleLine = true,
                    isError = state.problem != null,
                    enabled = !state.busy,
                )
                when (val problem = state.problem) {
                    RepoProblem.NotAnAddress -> Problem(stringResource(Res.string.repo_problem_address))
                    is RepoProblem.Detail -> Problem(problem.text)
                    null -> if (state.busy) InkCircularProgressIndicator(strokeWidth = 2.dp)
                }
            }
        },
        confirmButton = {
            InkButton(
                onConfirm,
                enabled = !state.busy && state.address.isNotBlank(),
            ) { Text(stringResource(Res.string.add)) }
        },
        dismissButton = { CancelButton(onDismiss) },
    )
}

@Composable
private fun Problem(text: String) {
    Text(text, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
}
