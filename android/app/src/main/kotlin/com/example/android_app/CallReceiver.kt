package com.example.android_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager

class CallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // ১. আউটগোয়িং কল (ডায়াল করার সাথে সাথে)
        if (intent.action == Intent.ACTION_NEW_OUTGOING_CALL) {
            val phoneNumber = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
            RecordingForegroundService.startService(context, phoneNumber ?: "Outgoing Call")
        }

        // ২. ইনকামিং কল (ফোন বাজার সাথে সাথে)
        if (intent.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

            if (state == TelephonyManager.EXTRA_STATE_RINGING) {
                RecordingForegroundService.startService(context, number ?: "Incoming Call")
            } 
            // কল শেষ হলে স্টপ করা
            else if (state == TelephonyManager.EXTRA_STATE_IDLE) {
                RecordingForegroundService.stopService(context)
            }
        }
    }
}