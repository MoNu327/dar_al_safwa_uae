package com.example.daralsafwa_uae  // Make sure this matches your package name

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d("FCM", "Refreshed token: $token")
        // The Flutter side will handle token updates
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        // Let Flutter handle all messages to avoid duplicates
        Log.d("FCM", "Message received, delegating to Flutter")
    }
}