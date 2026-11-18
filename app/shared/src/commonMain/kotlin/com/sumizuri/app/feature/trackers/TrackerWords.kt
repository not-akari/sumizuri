package com.sumizuri.app.feature.trackers

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.tracker.TrackStatus
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.data.tracker.TrackerProblem
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_gone
import com.sumizuri.app.shared.resources.tracker_problem_ended
import com.sumizuri.app.shared.resources.tracker_problem_limited
import com.sumizuri.app.shared.resources.tracker_problem_no_key
import com.sumizuri.app.shared.resources.tracker_problem_offline
import com.sumizuri.app.shared.resources.tracker_problem_other
import com.sumizuri.app.shared.resources.tracker_problem_refused
import com.sumizuri.app.shared.resources.tracker_progress_chapter
import com.sumizuri.app.shared.resources.tracker_progress_chapter_of
import com.sumizuri.app.shared.resources.tracker_progress_episode
import com.sumizuri.app.shared.resources.tracker_progress_episode_of
import com.sumizuri.app.shared.resources.tracker_progress_none
import com.sumizuri.app.shared.resources.tracker_score_bad
import com.sumizuri.app.shared.resources.tracker_score_good
import com.sumizuri.app.shared.resources.tracker_score_none
import com.sumizuri.app.shared.resources.tracker_score_okay
import com.sumizuri.app.shared.resources.tracker_status_completed
import com.sumizuri.app.shared.resources.tracker_status_dropped
import com.sumizuri.app.shared.resources.tracker_status_paused
import com.sumizuri.app.shared.resources.tracker_status_planning
import com.sumizuri.app.shared.resources.tracker_status_reading
import com.sumizuri.app.shared.resources.tracker_status_rereading
import com.sumizuri.app.shared.resources.tracker_status_rewatching
import com.sumizuri.app.shared.resources.tracker_status_watching
import org.jetbrains.compose.resources.stringResource
import kotlin.math.abs

// A status in the words of the kind of title, so a show is watched and a book is read.
@Composable
internal fun statusLabel(status: TrackStatus, kind: Kind): String = stringResource(
    when (status) {
        TrackStatus.Current -> if (kind ==
            Kind.Anime
        ) {
            Res.string.tracker_status_watching
        } else {
            Res.string.tracker_status_reading
        }

        TrackStatus.Planning -> Res.string.tracker_status_planning

        TrackStatus.Completed -> Res.string.tracker_status_completed

        TrackStatus.Paused -> Res.string.tracker_status_paused

        TrackStatus.Dropped -> Res.string.tracker_status_dropped

        TrackStatus.Repeating -> if (kind ==
            Kind.Anime
        ) {
            Res.string.tracker_status_rewatching
        } else {
            Res.string.tracker_status_rereading
        }
    },
)

// The scores the person can give in the way they score on the tracker, each out of 100, where 0 is no score.
internal fun scoreChoices(format: String?): List<Int> = when (format) {
    "POINT_10" -> (0..10).map { it * 10 }
    "POINT_5" -> (0..5).map { it * 20 }
    "POINT_3" -> listOf(0, 35, 60, 85)
    else -> (0..20).map { it * 5 }
}

// The choice nearest to a score, as a score set on the site may sit between two choices.
internal fun nearestScore(score: Int, format: String?): Int = scoreChoices(format).minBy { abs(it - score) }

@Composable
internal fun scoreText(score: Int, format: String?): String {
    if (score <= 0) return stringResource(Res.string.tracker_score_none)
    return when (format) {
        "POINT_10" -> "${score / 10} / 10"

        "POINT_5" -> "${score / 20} / 5"

        "POINT_3" -> stringResource(
            when {
                score <= 35 -> Res.string.tracker_score_bad
                score <= 60 -> Res.string.tracker_score_okay
                else -> Res.string.tracker_score_good
            },
        )

        "POINT_10_DECIMAL" -> "${score / 10}.${score % 10} / 10"

        else -> "$score / 100"
    }
}

// How far a title is, in chapters or in episodes, out of how many when the tracker knows.
@Composable
internal fun progressText(progress: Int, total: Int?, kind: Kind): String {
    if (progress <= 0) return stringResource(Res.string.tracker_progress_none)
    val shows = kind == Kind.Anime
    return when {
        total == null || total <= 0 -> stringResource(
            if (shows) Res.string.tracker_progress_episode else Res.string.tracker_progress_chapter,
            progress,
        )

        shows -> stringResource(Res.string.tracker_progress_episode_of, progress, total)

        else -> stringResource(Res.string.tracker_progress_chapter_of, progress, total)
    }
}

// What a link holds in one line: its status, how far it is, and its score when it has one.
@Composable
internal fun linkLine(link: TrackerLinkEntity, tracker: TrackerId, format: String?): String {
    if (link.gone) return stringResource(Res.string.tracker_gone, tracker.label)
    val kind = Kind.fromCode(link.kind)
    val parts = listOf(
        statusLabel(TrackStatus.of(link.status), kind),
        progressText(link.progress, link.remoteTotal, kind),
    ) + if (link.score > 0) listOf(scoreText(link.score, format)) else emptyList()
    return parts.joinToString(" · ")
}

// The kind of a title on the tracker as it names it, such as ONE_SHOT, in plain words.
internal fun formatWords(format: String?): String? =
    format?.lowercase()?.replace('_', ' ')?.replaceFirstChar { it.uppercase() }

@Composable
internal fun problemText(problem: TrackerProblem, tracker: TrackerId, signedIn: Boolean = false): String =
    when (problem) {
        TrackerProblem.NoKey -> stringResource(Res.string.tracker_problem_no_key, tracker.label)

        TrackerProblem.Offline -> stringResource(Res.string.tracker_problem_offline, tracker.label)

        // A login that worked before has ended, which only logging in again mends.
        TrackerProblem.Refused -> stringResource(
            if (signedIn) Res.string.tracker_problem_ended else Res.string.tracker_problem_refused,
            tracker.label,
        )

        TrackerProblem.Limited -> stringResource(Res.string.tracker_problem_limited, tracker.label)

        is TrackerProblem.Other -> problem.message?.takeIf { it.isNotBlank() }
            ?: stringResource(Res.string.tracker_problem_other)
    }

// Why something with a signed in tracker did not work, in red.
@Composable
internal fun ProblemLine(problem: TrackerProblem, tracker: TrackerId) {
    Text(
        problemText(problem, tracker, signedIn = true),
        color = MaterialTheme.colorScheme.error,
        style = MaterialTheme.typography.bodyMedium,
    )
}
