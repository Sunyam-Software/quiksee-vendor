package `in`.quiksee.dman

/**
 * Tracks whether [MainActivity] is resumed so FCM can skip the small heads-up
 * popup that blocks touches on the in-app offer sheet.
 */
object AppForegroundState {
    @Volatile
    var isResumed: Boolean = false
        private set

    fun markResumed() {
        isResumed = true
    }

    fun markPaused() {
        isResumed = false
    }
}
