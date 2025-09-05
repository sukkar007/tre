package com.flamingolive.hus

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.content.Intent
import android.net.Uri
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.widget.Toast
import android.os.Build
import android.provider.Settings
import android.content.Context
import android.media.AudioManager
import android.telephony.TelephonyManager
import android.app.NotificationManager
import android.app.NotificationChannel
import androidx.annotation.RequiresApi

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.flamingolive.hus/native"
    private val PERMISSION_REQUEST_CODE = 1001
    
    private val REQUIRED_PERMISSIONS = arrayOf(
        Manifest.permission.RECORD_AUDIO,
        Manifest.permission.CAMERA,
        Manifest.permission.READ_EXTERNAL_STORAGE,
        Manifest.permission.WRITE_EXTERNAL_STORAGE
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> {
                    requestPermissions()
                    result.success(true)
                }
                "checkPermissions" -> {
                    val hasPermissions = checkPermissions()
                    result.success(hasPermissions)
                }
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(true)
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        openUrl(url)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "URL is required", null)
                    }
                }
                "shareText" -> {
                    val text = call.argument<String>("text")
                    val subject = call.argument<String>("subject")
                    if (text != null) {
                        shareText(text, subject)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Text is required", null)
                    }
                }
                "getDeviceInfo" -> {
                    val deviceInfo = getDeviceInfo()
                    result.success(deviceInfo)
                }
                "setAudioMode" -> {
                    val mode = call.argument<String>("mode")
                    if (mode != null) {
                        setAudioMode(mode)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Audio mode is required", null)
                    }
                }
                "enableSpeakerphone" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    enableSpeakerphone(enable)
                    result.success(true)
                }
                "getNetworkInfo" -> {
                    val networkInfo = getNetworkInfo()
                    result.success(networkInfo)
                }
                "createNotificationChannel" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        createNotificationChannel()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Create notification channel for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel()
        }
        
        // Handle deep links
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent?.data?.let { uri ->
            // Handle deep link URI
            val deepLink = uri.toString()
            // Send to Flutter via method channel if needed
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("onDeepLink", deepLink)
            }
        }
    }

    private fun requestPermissions() {
        val permissionsToRequest = mutableListOf<String>()
        
        for (permission in REQUIRED_PERMISSIONS) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(permission)
            }
        }
        
        // Add Android 13+ permissions
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val android13Permissions = arrayOf(
                Manifest.permission.POST_NOTIFICATIONS,
                Manifest.permission.READ_MEDIA_AUDIO,
                Manifest.permission.READ_MEDIA_VIDEO,
                Manifest.permission.READ_MEDIA_IMAGES
            )
            
            for (permission in android13Permissions) {
                if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                    permissionsToRequest.add(permission)
                }
            }
        }
        
        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissionsToRequest.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
        }
    }

    private fun checkPermissions(): Boolean {
        for (permission in REQUIRED_PERMISSIONS) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                return false
            }
        }
        return true
    }

    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
        }
        startActivity(intent)
    }

    private fun openUrl(url: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            startActivity(intent)
        } catch (e: Exception) {
            Toast.makeText(this, "Cannot open URL", Toast.LENGTH_SHORT).show()
        }
    }

    private fun shareText(text: String, subject: String?) {
        try {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                if (subject != null) {
                    putExtra(Intent.EXTRA_SUBJECT, subject)
                }
            }
            startActivity(Intent.createChooser(intent, "مشاركة"))
        } catch (e: Exception) {
            Toast.makeText(this, "Cannot share text", Toast.LENGTH_SHORT).show()
        }
    }

    private fun getDeviceInfo(): Map<String, Any> {
        return mapOf(
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER,
            "version" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
            "brand" to Build.BRAND,
            "device" to Build.DEVICE,
            "board" to Build.BOARD,
            "hardware" to Build.HARDWARE,
            "product" to Build.PRODUCT,
            "fingerprint" to Build.FINGERPRINT,
            "host" to Build.HOST,
            "tags" to Build.TAGS,
            "type" to Build.TYPE,
            "user" to Build.USER,
            "display" to Build.DISPLAY,
            "id" to Build.ID
        )
    }

    private fun setAudioMode(mode: String) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        when (mode) {
            "normal" -> audioManager.mode = AudioManager.MODE_NORMAL
            "call" -> audioManager.mode = AudioManager.MODE_IN_CALL
            "communication" -> audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
            "ringtone" -> audioManager.mode = AudioManager.MODE_RINGTONE
        }
    }

    private fun enableSpeakerphone(enable: Boolean) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.isSpeakerphoneOn = enable
    }

    private fun getNetworkInfo(): Map<String, Any> {
        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as android.net.ConnectivityManager
        val activeNetwork = connectivityManager.activeNetworkInfo
        
        return mapOf(
            "isConnected" to (activeNetwork?.isConnected ?: false),
            "type" to (activeNetwork?.typeName ?: "Unknown"),
            "subtype" to (activeNetwork?.subtypeName ?: "Unknown"),
            "isWifi" to (activeNetwork?.type == android.net.ConnectivityManager.TYPE_WIFI),
            "isMobile" to (activeNetwork?.type == android.net.ConnectivityManager.TYPE_MOBILE)
        )
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotificationChannel() {
        val channelId = "hus_notifications"
        val channelName = "HUS Notifications"
        val channelDescription = "Notifications for HUS app"
        val importance = NotificationManager.IMPORTANCE_HIGH
        
        val channel = NotificationChannel(channelId, channelName, importance).apply {
            description = channelDescription
            enableLights(true)
            enableVibration(true)
            setShowBadge(true)
        }
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            
            // Send result to Flutter
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("onPermissionResult", allGranted)
            }
        }
    }
}

