package com.sumizuri.app.ui.text

// A count as it fits beside a name or on a badge: 950, 1.2k, 34k, 1.5m.
internal fun compactCount(count: Int): String = when {
    count < 1_000 -> count.toString()
    count < 1_000_000 -> shortened(count / 1_000.0) + "k"
    else -> shortened(count / 1_000_000.0) + "m"
}

// One figure after the point below ten, and none from ten up.
private fun shortened(value: Double): String = if (value >= 10) {
    value.toInt().toString()
} else {
    ((value * 10).toInt() / 10.0).let { if (it % 1.0 == 0.0) it.toInt().toString() else it.toString() }
}
