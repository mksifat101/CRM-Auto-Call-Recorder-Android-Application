package com.example.android_app

import android.app.*
import android.content.*
import android.content.pm.ServiceInfo
import android.media.MediaRecorder
import android.os.*
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import java.io.File

class RecordingForegroundService : Service() {
    private var recorder: MediaRecorder? = null
    private var isRecording = false
    private lateinit var filePath: String
    private var startTime: Long = 0
    private val handler = Handler(Looper.getMainLooper())

    companion object {
        const val CHANNEL_ID = "CallRecordChannel"
        const val NOTIFICATION_ID = 1002
        var methodChannel: MethodChannel? = null

        fun startService(context: Context, phoneNumber: String) {
            val intent = Intent(context, RecordingForegroundService::class.java).apply {
                putExtra("phone_number", phoneNumber)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stopService(context: Context) {
            context.stopService(Intent(context, RecordingForegroundService::class.java))
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val phoneNumber = intent?.getStringExtra("phone_number") ?: "Unknown"
        val action = intent?.action

        if (action == "START_RECORDING_ACTION") {
            startTime = System.currentTimeMillis()
            startMediaRecording()
            isRecording = true
            startTimer(phoneNumber) 
        } else {
            isRecording = false
            updateNotification(phoneNumber, "00:00", false)
        }
        return START_STICKY
    }

    private fun startTimer(phoneNumber: String) {
        handler.post(object : Runnable {
            override fun run() {
                if (isRecording) {
                    val millis = System.currentTimeMillis() - startTime
                    val seconds = (millis / 1000) % 60
                    val minutes = (millis / (1000 * 60)) % 60
                    val timeString = String.format("%02d:%02d", minutes, seconds)
                    updateNotification(phoneNumber, timeString, true)
                    handler.postDelayed(this, 1000)
                }
            }
        })
    }

    private fun updateNotification(phoneNumber: String, time: String, recordingActive: Boolean) {
        val stopIntent = Intent(this, StopServiceReceiver::class.java)
        val stopPendingIntent = PendingIntent.getBroadcast(this, 0, stopIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

        val recordNowIntent = Intent(this, StartRecordingReceiver::class.java)
        val recordPendingIntent = PendingIntent.getBroadcast(this, 1, recordNowIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Call with: $phoneNumber")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .setOnlyAlertOnce(true)

        if (!recordingActive) {
            builder.setContentText("Tap to start recording")
            builder.addAction(android.R.drawable.ic_media_play, "Record Now", recordPendingIntent)
        } else {
            builder.setContentText("Recording... $time")
            builder.addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop Recording", stopPendingIntent)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, builder.build(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        } else {
            startForeground(NOTIFICATION_ID, builder.build())
        }
    }

    private fun startMediaRecording() {
        try {
            val dir = File(getExternalFilesDir(null), "recordings")
            if (!dir.exists()) dir.mkdirs()
            filePath = "${dir.absolutePath}/call_${System.currentTimeMillis()}.m4a"

            recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(this) else MediaRecorder()
            recorder?.apply {
                setAudioSource(MediaRecorder.AudioSource.VOICE_COMMUNICATION)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setOutputFile(filePath)
                prepare()
                start()
            }
            methodChannel?.invokeMethod("onRecordingStarted", null)
        } catch (e: Exception) { e.printStackTrace() }
    }

    override fun onDestroy() {
        isRecording = false
        handler.removeCallbacksAndMessages(null)
        if (recorder != null) {
            try {
                recorder?.stop()
                recorder?.release()
                methodChannel?.invokeMethod("onRecordingFinished", filePath)
            } catch (e: Exception) {}
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}

// এই ক্লাসগুলো এখানে থাকলে কোনো Redeclaration এরর হবে না
class StopServiceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        RecordingForegroundService.stopService(context)
    }
}

class StartRecordingReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val serviceIntent = Intent(context, RecordingForegroundService::class.java).apply {
            action = "START_RECORDING_ACTION"
        }
        context.startService(serviceIntent)
    }
}