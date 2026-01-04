package com.example.android_app

import android.app.*
import android.content.*
import android.media.MediaRecorder
import android.os.*
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.*

class RecordingForegroundService : Service() {
    private var recorder: MediaRecorder? = null
    private var isRecording = false
    private lateinit var filePath: String
    private var startTime: Long = 0
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var notificationManager: NotificationManager

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

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val phoneNumber = intent?.getStringExtra("phone_number") ?: "Unknown"
        
        // কল স্টপ করার জন্য পেন্ডিং ইনটেন্ট
        val stopIntent = Intent(this, StopServiceReceiver::class.java)
        val stopPendingIntent = PendingIntent.getBroadcast(
            this, 0, stopIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        startTime = System.currentTimeMillis()
        startMediaRecording()
        updateNotification(phoneNumber, "00:00", stopPendingIntent)
        startTimer(phoneNumber, stopPendingIntent)
        
        return START_STICKY
    }

    private fun startTimer(phoneNumber: String, stopIntent: PendingIntent) {
        handler.post(object : Runnable {
            override fun run() {
                if (isRecording) {
                    val millis = System.currentTimeMillis() - startTime
                    val seconds = (millis / 1000) % 60
                    val minutes = (millis / (1000 * 60)) % 60
                    val timeString = String.format("%02d:%02d", minutes, seconds)
                    
                    updateNotification(phoneNumber, timeString, stopIntent)
                    handler.postDelayed(this, 1000)
                }
            }
        })
    }

    private fun updateNotification(phoneNumber: String, time: String, stopIntent: PendingIntent) {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Recording Call: $phoneNumber")
            .setContentText("Duration: $time")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .setOnlyAlertOnce(true) // যাতে বারবার সাউন্ড না হয়
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop Recording", stopIntent)
            .build()

        startForeground(NOTIFICATION_ID, notification)
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
            isRecording = true
            // ফ্লার্টারকে জানানো যে রেকর্ডিং শুরু হয়েছে
            methodChannel?.invokeMethod("onRecordingStarted", null)
        } catch (e: Exception) { stopSelf() }
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

class StopServiceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // নোটিফিকেশনের স্টপ বাটনে ক্লিক করলে এই কোডটি সার্ভিস বন্ধ করে দেবে
        val stopServiceIntent = Intent(context, RecordingForegroundService::class.java)
        context.stopService(stopServiceIntent)
    }
}