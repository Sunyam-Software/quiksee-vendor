package `in`.quiksee.dman

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.Ringtone
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import java.util.concurrent.Executors

/**
 * Plays ringtone/alarm + vibration from native code.
 * Transfer ring: MediaPlayer (looping) + Ringtone + ToneGenerator pulse so
 * OEM phones cannot leave silence after one ringtone cycle.
 */
object NativeOrderAlert {

    private const val TAG = "NativeOrderAlert"
    private const val PREFS = "FlutterSharedPreferences"
    private const val ALERT_ACTIVE_KEY = "flutter.new_order_alert_active_at"
    private const val MUTED_UNTIL_KEY = "flutter.new_order_alert_muted_until"
    private const val MUTED_OFFER_KEY = "flutter.new_order_alert_muted_offer_id"
    private const val STOP_REQUESTED_KEY = "flutter.native_alert_stop_requested"
    private const val WATCHDOG_MS = 500L

    private var mediaPlayer: MediaPlayer? = null
    private var fallbackRingtone: Ringtone? = null
    private var toneGenerator: ToneGenerator? = null
    private var vibrator: Vibrator? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    private val playerExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val loopWatchdog = object : Runnable {
        override fun run() {
            val ctx = watchdogContext ?: return
            if (!playing) return
            if (isSuppressed(ctx)) {
                stop(ctx)
                return
            }
            try {
                val prefs = ctx.applicationContext
                    .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                if (prefs.getBoolean(STOP_REQUESTED_KEY, false)) {
                    stop(ctx)
                    return
                }
            } catch (_: Exception) {
            }
            val mediaOk = try {
                mediaPlayer?.isPlaying == true
            } catch (_: Exception) {
                false
            }
            val ringOk = try {
                fallbackRingtone?.isPlaying == true
            } catch (_: Exception) {
                false
            }
            if (!mediaOk && !ringOk) {
                Log.w(TAG, "Loop dropped — restarting ringtone + tone pulse")
                playImmediateRingtone(ctx)
                startLoopingPlayer(ctx)
                pulseToneBackup()
            }
            if (playing) {
                mainHandler.postDelayed(this, WATCHDOG_MS)
            }
        }
    }

    @Volatile
    private var watchdogContext: Context? = null

    @Volatile
    private var playing = false

    fun isSuppressed(context: Context): Boolean {
        return try {
            val prefs = context.applicationContext
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val mutedUntil = readMutedUntilMs(prefs)
            if (mutedUntil > System.currentTimeMillis()) {
                Log.i(TAG, "Alert muted until $mutedUntil")
                return true
            }
            false
        } catch (_: Exception) {
            false
        }
    }

    private fun readMutedUntilMs(prefs: android.content.SharedPreferences): Long {
        return try {
            prefs.getLong(MUTED_UNTIL_KEY, 0L)
        } catch (_: ClassCastException) {
            try {
                prefs.getInt(MUTED_UNTIL_KEY, 0).toLong()
            } catch (_: Exception) {
                try {
                    prefs.getString(MUTED_UNTIL_KEY, null)?.toLongOrNull() ?: 0L
                } catch (_: Exception) {
                    0L
                }
            }
        }
    }

    /**
     * New offer must ring even after force-close. Clears mute unless the same
     * offer_id was just muted (prevents re-ring of the offer user just rejected).
     */
    fun clearMuteForNewOffer(context: Context, offerId: String?) {
        try {
            val prefs = context.applicationContext
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val mutedOffer = prefs.getString(MUTED_OFFER_KEY, null)
            val mutedUntil = readMutedUntilMs(prefs)
            val stillMuted = mutedUntil > System.currentTimeMillis()
            if (stillMuted &&
                !offerId.isNullOrBlank() &&
                mutedOffer != null &&
                mutedOffer == offerId
            ) {
                Log.i(TAG, "Keep mute for same offer_id=$offerId")
                return
            }
            prefs.edit()
                .remove(MUTED_UNTIL_KEY)
                .remove(MUTED_OFFER_KEY)
                .putBoolean(STOP_REQUESTED_KEY, false)
                .apply()
            Log.i(TAG, "Cleared mute for new offer offerId=$offerId")
        } catch (_: Exception) {
        }
    }

    fun startInstant(context: Context, forceRestart: Boolean = false) {
        val appCtx = context.applicationContext
        if (isSuppressed(appCtx)) {
            Log.i(TAG, "Skip start — alert muted after accept/reject")
            stop(appCtx)
            return
        }
        // Soft or hard: only fall through when the player actually died.
        if (playing) {
            val mediaOk = try {
                mediaPlayer?.isPlaying == true
            } catch (_: Exception) {
                false
            }
            val ringOk = try {
                fallbackRingtone?.isPlaying == true
            } catch (_: Exception) {
                false
            }
            if (mediaOk || ringOk) {
                ensureWatchdog(appCtx)
                markAlertActive(appCtx)
                return
            }
        }

        stopPlaybackOnly()

        try {
            appCtx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(STOP_REQUESTED_KEY, false)
                .apply()
        } catch (_: Exception) {
        }

        startVibration(appCtx)
        markAlertActive(appCtx)
        playing = true

        boostStreamVolumes(appCtx)
        requestRingAudioFocus(appCtx)
        // waiting for async MediaPlayer prepare.
        playImmediateRingtone(appCtx)
        startLoopingPlayer(appCtx)
        // Immediate tone so there is never a silent gap before MediaPlayer prepare.
        pulseToneBackup()
        ensureWatchdog(appCtx)
    }

    private fun ensureWatchdog(appCtx: Context) {
        watchdogContext = appCtx
        mainHandler.removeCallbacks(loopWatchdog)
        mainHandler.postDelayed(loopWatchdog, WATCHDOG_MS)
    }

    /** Last-resort audible pulse when MediaPlayer + Ringtone both die (MIUI). */
    private fun pulseToneBackup() {
        try {
            if (toneGenerator == null) {
                toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
            }
            toneGenerator?.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 900)
        } catch (e: Exception) {
            Log.w(TAG, "ToneGenerator failed: ${e.message}")
            try {
                toneGenerator?.release()
            } catch (_: Exception) {
            }
            toneGenerator = null
        }
    }

    fun start(context: Context, forceRestart: Boolean = false) {
        startInstant(context, forceRestart)
    }

    private fun candidateUris(context: Context): List<Uri> {
        val uris = linkedSetOf<Uri>()
        listOf(
            RingtoneManager.TYPE_ALARM,
            RingtoneManager.TYPE_RINGTONE,
            RingtoneManager.TYPE_NOTIFICATION,
        ).forEach { type ->
            RingtoneManager.getDefaultUri(type)?.let { uris.add(it) }
            try {
                RingtoneManager.getActualDefaultRingtoneUri(context, type)?.let { uris.add(it) }
            } catch (_: Exception) {
            }
        }
        return uris.toList()
    }

    private fun playImmediateRingtone(context: Context) {
        try {
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                ?: return
            fallbackRingtone?.stop()
            RingtoneManager.getRingtone(context, uri)?.also { rt ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    rt.audioAttributes = AudioAttributes.Builder()
                        // ALARM survives silent/vibrate mode; RING often does not.
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                        .build()
                    rt.isLooping = true
                } else {
                    @Suppress("DEPRECATION")
                    rt.streamType = AudioManager.STREAM_ALARM
                }
                fallbackRingtone = rt
                rt.play()
                Log.i(TAG, "Immediate Ringtone.play() started")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Immediate ringtone failed: ${e.message}")
        }
    }

    private fun startLoopingPlayer(context: Context) {
        val uris = candidateUris(context)
        if (uris.isEmpty()) {
            Log.w(TAG, "No ringtone/alarm URI available")
            return
        }

        playerExecutor.execute {
            // which made transfer sound like a single chirp then silence.
            val usages = intArrayOf(
                AudioAttributes.USAGE_ALARM,
                AudioAttributes.USAGE_NOTIFICATION_RINGTONE,
            )
            for (uri in uris) {
                if (!playing) return@execute
                for (usage in usages) {
                    if (tryPlayUri(context, uri, usage)) {
                        return@execute
                    }
                }
            }
            mainHandler.post {
                if (playing) playFallbackRingtone(context, uris.first())
            }
        }
    }

    private fun tryPlayUri(context: Context, uri: Uri, usage: Int): Boolean {
        var player: MediaPlayer? = null
        return try {
            player = MediaPlayer().apply {
                setDataSource(context, uri)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(usage)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                            .build(),
                    )
                } else {
                    @Suppress("DEPRECATION")
                    setAudioStreamType(
                        if (usage == AudioAttributes.USAGE_ALARM) {
                            AudioManager.STREAM_ALARM
                        } else {
                            AudioManager.STREAM_RING
                        },
                    )
                }
                isLooping = true
                setVolume(1f, 1f)
                // Backup when OEM ignores isLooping for some ringtone URIs.
                setOnCompletionListener { mp ->
                    if (!playing) return@setOnCompletionListener
                    try {
                        mp.seekTo(0)
                        mp.start()
                    } catch (_: Exception) {
                        mainHandler.post {
                            if (playing) {
                                playImmediateRingtone(context)
                                startLoopingPlayer(context)
                            }
                        }
                    }
                }
                prepare()
            }
            if (!playing) {
                player.release()
                return false
            }
            // Swap on main thread to keep stop() safe.
            val ready = player
            mainHandler.post {
                if (!playing) {
                    try {
                        ready.release()
                    } catch (_: Exception) {
                    }
                    return@post
                }
                try {
                    mediaPlayer?.let {
                        if (it.isPlaying) it.stop()
                        it.reset()
                        it.release()
                    }
                } catch (_: Exception) {
                }
                try {
                    mediaPlayer = ready
                    ready.start()
                    Log.i(TAG, "Playing alert uri=$uri usage=$usage")
                    // Keep Ringtone fallback until MediaPlayer proves it is alive;
                    // stopping it immediately left a one-shot chirp on some OEMs.
                    mainHandler.postDelayed({
                        if (!playing) return@postDelayed
                        val ok = try {
                            mediaPlayer?.isPlaying == true
                        } catch (_: Exception) {
                            false
                        }
                        if (ok) {
                            try {
                                fallbackRingtone?.stop()
                            } catch (_: Exception) {
                            }
                            fallbackRingtone = null
                        }
                    }, 1200)
                } catch (e: Exception) {
                    Log.w(TAG, "start() failed: ${e.message}")
                }
            }
            true
        } catch (e: Exception) {
            Log.w(TAG, "Failed uri=$uri usage=$usage: ${e.message}")
            try {
                player?.release()
            } catch (_: Exception) {
            }
            false
        }
    }

    private fun playFallbackRingtone(context: Context, alarmUri: Uri) {
        if (!playing) return
        try {
            fallbackRingtone?.stop()
        } catch (_: Exception) {
        }
        try {
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM) ?: alarmUri
            RingtoneManager.getRingtone(context, uri)?.also { rt ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    rt.audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                        .build()
                    rt.isLooping = true
                } else {
                    @Suppress("DEPRECATION")
                    rt.streamType = AudioManager.STREAM_ALARM
                }
                fallbackRingtone = rt
                rt.play()
                Log.i(TAG, "Fallback Ringtone.play() started")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Fallback ringtone failed: ${e.message}")
        }
    }

    private fun boostStreamVolumes(context: Context) {
        try {
            val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager = am
            listOf(
                AudioManager.STREAM_RING,
                AudioManager.STREAM_ALARM,
                AudioManager.STREAM_NOTIFICATION,
                AudioManager.STREAM_MUSIC,
            ).forEach { stream ->
                try {
                    val maxVol = am.getStreamMaxVolume(stream)
                    val currentVol = am.getStreamVolume(stream)
                    if (maxVol > 0 && currentVol < (maxVol * 0.7).toInt()) {
                        am.setStreamVolume(stream, maxVol.coerceAtLeast(1), 0)
                    }
                } catch (_: Exception) {
                }
            }
        } catch (_: Exception) {
        }
    }

    private fun requestRingAudioFocus(context: Context) {
        try {
            val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager = am
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val attrs = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                    .setAudioAttributes(attrs)
                    .setAcceptsDelayedFocusGain(false)
                    .setWillPauseWhenDucked(false)
                    .build()
                audioFocusRequest = request
                am.requestAudioFocus(request)
            } else {
                @Suppress("DEPRECATION")
                am.requestAudioFocus(
                    null,
                    AudioManager.STREAM_ALARM,
                    AudioManager.AUDIOFOCUS_GAIN,
                )
            }
        } catch (_: Exception) {
        }
    }

    private fun abandonAlarmAudioFocus() {
        try {
            val am = audioManager ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
            } else {
                @Suppress("DEPRECATION")
                am.abandonAudioFocus(null)
            }
        } catch (_: Exception) {
        }
        audioFocusRequest = null
        audioManager = null
    }

    private fun markAlertActive(context: Context) {
        try {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putLong(ALERT_ACTIVE_KEY, System.currentTimeMillis())
                .apply()
        } catch (_: Exception) {
        }
    }

    private fun clearAlertActive(context: Context) {
        try {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .remove(ALERT_ACTIVE_KEY)
                .apply()
        } catch (_: Exception) {
        }
    }

    private fun startVibration(context: Context) {
        try {
            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                    as VibratorManager
                manager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }

            val pattern = longArrayOf(0, 800, 200, 800, 200, 1000)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(
                    VibrationEffect.createWaveform(pattern, 0),
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (_: Exception) {
        }
    }

    private fun stopPlaybackOnly() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) it.stop()
                it.reset()
                it.release()
            }
        } catch (_: Exception) {
        }
        mediaPlayer = null

        try {
            fallbackRingtone?.stop()
        } catch (_: Exception) {
        }
        fallbackRingtone = null

        try {
            toneGenerator?.stopTone()
            toneGenerator?.release()
        } catch (_: Exception) {
        }
        toneGenerator = null

        try {
            vibrator?.cancel()
        } catch (_: Exception) {
        }
        vibrator = null

        abandonAlarmAudioFocus()
    }

    fun stop(context: Context) {
        playing = false
        watchdogContext = null
        mainHandler.removeCallbacks(loopWatchdog)
        stopPlaybackOnly()
        clearAlertActive(context.applicationContext)
    }

    fun isPlaying(): Boolean = playing

    /**
     * True when an offer alert should still be audible (Accept/Deny not yet).
     * Used on Activity resume / cold start so splash cannot leave a silent gap.
     */
    fun shouldKeepAlertAlive(context: Context): Boolean {
        val appCtx = context.applicationContext
        if (isSuppressed(appCtx)) return false
        try {
            val prefs = appCtx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            if (prefs.getBoolean(STOP_REQUESTED_KEY, false)) return false
            if (playing) {
                val mediaOk = try {
                    mediaPlayer?.isPlaying == true
                } catch (_: Exception) {
                    false
                }
                val ringOk = try {
                    fallbackRingtone?.isPlaying == true
                } catch (_: Exception) {
                    false
                }
                if (mediaOk || ringOk) return true
                return true
            }
            val activeAt = try {
                prefs.getLong(ALERT_ACTIVE_KEY, 0L)
            } catch (_: ClassCastException) {
                prefs.getInt(ALERT_ACTIVE_KEY, 0).toLong()
            }
            // Match Flutter maxLoopUntilStoppedSeconds (120) + small buffer.
            if (activeAt > 0L &&
                System.currentTimeMillis() - activeAt < 125_000L
            ) {
                return true
            }
            val pendingOrder = prefs.getInt("flutter.pending_wake_order_id", 0)
            if (pendingOrder > 0) return true
        } catch (_: Exception) {
        }
        return false
    }

    fun reassertIfNeeded(context: Context) {
        if (!shouldKeepAlertAlive(context)) return
        startInstant(context, forceRestart = false)
    }
}
