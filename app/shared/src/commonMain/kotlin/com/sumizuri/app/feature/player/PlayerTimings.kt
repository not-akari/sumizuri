package com.sumizuri.app.feature.player

// How often the place is kept while playing, and how long a video may take to tell its length before it is called broken.
internal const val SaveEveryMs = 5000L
internal const val StartTimeoutMs = 30_000L

// How near its length an end must come to count as the end of the episode, a fiftieth of the length kept between these two, and what the log and the failure say when it comes before.
internal const val EndSlackMs = 15_000L
internal const val EndSlackMinMs = 2_000L

// A video shorter than this has no end the player trusts, since a broken stream reports lengths like that.
internal const val ShortestEpisodeMs = 60_000L
internal const val StoppedEarly = "The video stopped before its end, its stream could not be read"
