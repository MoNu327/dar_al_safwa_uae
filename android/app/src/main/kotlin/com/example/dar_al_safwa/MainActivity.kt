package com.majan.app

import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.majan.app/file_opener"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            openFile(path)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e("FileOpener", "Error opening file: ${e.message}")
                            result.error("OPEN_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PATH", "File path is null", null)
                    }
                }
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            scanFile(path)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e("FileOpener", "Error scanning file: ${e.message}")
                            result.error("SCAN_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PATH", "File path is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openFile(filePath: String) {
        val file = File(filePath)
        
        if (!file.exists()) {
            throw Exception("File does not exist: $filePath")
        }
        
        Log.d("FileOpener", "Opening file: $filePath")
        
        val uri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            file
        )

        Log.d("FileOpener", "File URI: $uri")

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/pdf")
            flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
        }

        try {
            startActivity(Intent.createChooser(intent, "Open PDF"))
        } catch (e: Exception) {
            Log.e("FileOpener", "No app available to open PDF: ${e.message}")
            throw Exception("No app available to open PDF files")
        }
    }

    private fun scanFile(filePath: String) {
        val file = File(filePath)
        
        if (!file.exists()) {
            Log.e("MediaScanner", "File does not exist: $filePath")
            return
        }
        
        Log.d("MediaScanner", "Scanning file: $filePath")
        
        MediaScannerConnection.scanFile(
            this,
            arrayOf(filePath),
            arrayOf("application/pdf")
        ) { path, uri ->
            Log.d("MediaScanner", "Scanned $path successfully. URI: $uri")
        }
    }
}