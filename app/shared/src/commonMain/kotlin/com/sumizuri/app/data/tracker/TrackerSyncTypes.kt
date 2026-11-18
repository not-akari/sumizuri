package com.sumizuri.app.data.tracker

import com.sumizuri.app.data.model.Kind
import kotlinx.serialization.Serializable

// One field both sides changed since they last agreed, and which side was kept.
@Serializable
data class TrackerConflict(val name: String, val field: String, val keptHere: Boolean)

// One sync of a tracker as its details page lists it.
@Serializable
data class TrackerLogEntry(
    val at: Long,
    val ok: Boolean,
    val changedHere: Int = 0,
    val sent: Int = 0,
    val gone: Int = 0,
    val message: String = "",
    val conflicts: List<TrackerConflict> = emptyList(),
)

// An entry of the list of the person on a tracker, with its title and the kind of title it is.
data class OnTracker(val entry: RemoteEntry, val media: TrackerMedia, val kind: Kind)

// How the sync of a tracker went last.
sealed interface TrackerRun {
    data object Idle : TrackerRun

    data object Running : TrackerRun

    data class Done(val at: Long, val changedHere: Int, val sent: Int, val gone: Int) : TrackerRun

    data class Failed(val problem: TrackerProblem) : TrackerRun
}
