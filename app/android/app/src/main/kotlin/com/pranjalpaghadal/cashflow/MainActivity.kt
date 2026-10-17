package com.pranjalpaghadal.cashflow

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// local_auth (fingerprint) needs a FragmentActivity.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Export files (FR-C2): made on the phone, saved to Downloads, opened or shared only by the user.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cashflow/files").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "saveToDownloads" -> result.success(
                        saveToDownloads(call.argument<String>("name")!!, call.argument<String>("mime")!!, call.argument<ByteArray>("bytes")!!),
                    )
                    "open" -> {
                        startActivity(
                            Intent.createChooser(
                                Intent(Intent.ACTION_VIEW).setDataAndType(Uri.parse(call.argument<String>("uri")), call.argument<String>("mime"))
                                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION),
                                null,
                            ),
                        )
                        result.success(null)
                    }
                    "share" -> {
                        val send = Intent(Intent.ACTION_SEND)
                            .setType(call.argument<String>("mime"))
                            .putExtra(Intent.EXTRA_STREAM, Uri.parse(call.argument<String>("uri")))
                            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        startActivity(Intent.createChooser(send, null))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("files", e.javaClass.simpleName, null)
            }
        }
        // Settings (FR-G1, FR-R5): app version, this app's system settings page, and plain web links.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cashflow/system").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "appVersion" -> result.success(packageManager.getPackageInfo(packageName, 0).versionName)
                    "openAppSettings" -> {
                        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null)))
                        result.success(null)
                    }
                    "openUrl" -> {
                        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(call.argument<String>("url"))))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("system", e.javaClass.simpleName, null)
            }
        }
    }

    /// Android 10+: public Downloads through MediaStore (no storage permission). Older phones: the
    /// app's own Downloads folder, shared through FileProvider. Returns the content URI.
    private fun saveToDownloads(name: String, mime: String, bytes: ByteArray): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values) ?: error("insert failed")
            contentResolver.openOutputStream(uri)!!.use { it.write(bytes) }
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            return uri.toString()
        }
        val dir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: filesDir
        val file = File(dir, name)
        file.writeBytes(bytes)
        return FileProvider.getUriForFile(this, "$packageName.files", file).toString()
    }
}
