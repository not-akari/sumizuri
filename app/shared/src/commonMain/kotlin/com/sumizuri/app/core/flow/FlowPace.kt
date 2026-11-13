package com.sumizuri.app.core.flow

import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.conflate
import kotlinx.coroutines.flow.flow

// Passes the first value at once and then at most one value in each gap, always the latest, so a burst of changes is handled a few times instead of once for each.
fun <T> Flow<T>.atMostEvery(gapMs: Long): Flow<T> = flow {
    this@atMostEvery.conflate().collect { value ->
        emit(value)
        delay(gapMs)
    }
}
