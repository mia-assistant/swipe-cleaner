package com.manuelpa.swipecleaner

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Platform channel plugin for Storage Access Framework operations.
 *
 * Provides: directory picking via ACTION_OPEN_DOCUMENT_TREE,
 * file listing via DocumentsContract, file deletion, and
 * copying SAF content to local cache for thumbnail/display.
 */
class SAFPlugin(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.manuelpa.swipecleaner/saf"
        const val PICK_DIRECTORY_CODE = 9001
    }

    private var channel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null

    fun register(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickDirectory" -> pickDirectory(call, result)
            "listFiles" -> listFiles(call, result)
            "deleteDocument" -> deleteDocument(call, result)
            "copyToCache" -> copyToCache(call, result)
            else -> result.notImplemented()
        }
    }

    // ---- Directory picker ----

    private fun pickDirectory(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("ALREADY_ACTIVE", "A picker is already active", null)
            return
        }
        pendingResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            )

            val startWithDownloads = call.argument<Boolean>("startWithDownloads") ?: false
            if (startWithDownloads && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val downloadsUri = Uri.parse(
                    "content://com.android.externalstorage.documents/document/primary%3ADownload"
                )
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, downloadsUri)
            }
        }

        @Suppress("DEPRECATION")
        activity.startActivityForResult(intent, PICK_DIRECTORY_CODE)
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_DIRECTORY_CODE) return false

        val result = pendingResult ?: return true
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return true
        }

        val treeUri = data.data!!

        // Persist read+write access across reboots
        val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        activity.contentResolver.takePersistableUriPermission(treeUri, flags)

        val name = getTreeDisplayName(treeUri) ?: "Unknown"

        result.success(mapOf("uri" to treeUri.toString(), "name" to name))
        return true
    }

    private fun getTreeDisplayName(treeUri: Uri): String? {
        val docId = DocumentsContract.getTreeDocumentId(treeUri)
        val docUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)

        return activity.contentResolver.query(
            docUri,
            arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
            null, null, null
        )?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0) else null
        }
    }

    // ---- File listing ----

    private fun listFiles(call: MethodCall, result: MethodChannel.Result) {
        val treeUriString = call.argument<String>("treeUri") ?: run {
            result.error("INVALID_ARG", "treeUri is required", null)
            return
        }

        Thread {
            try {
                val treeUri = Uri.parse(treeUriString)
                val docId = DocumentsContract.getTreeDocumentId(treeUri)
                val childrenUri =
                    DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, docId)

                val projection = arrayOf(
                    DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                    DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                    DocumentsContract.Document.COLUMN_SIZE,
                    DocumentsContract.Document.COLUMN_LAST_MODIFIED,
                    DocumentsContract.Document.COLUMN_MIME_TYPE,
                )

                val files = mutableListOf<Map<String, Any>>()

                activity.contentResolver.query(
                    childrenUri, projection, null, null, null
                )?.use { cursor ->
                    val idIdx = cursor.getColumnIndexOrThrow(
                        DocumentsContract.Document.COLUMN_DOCUMENT_ID
                    )
                    val nameIdx = cursor.getColumnIndexOrThrow(
                        DocumentsContract.Document.COLUMN_DISPLAY_NAME
                    )
                    val sizeIdx = cursor.getColumnIndexOrThrow(
                        DocumentsContract.Document.COLUMN_SIZE
                    )
                    val modIdx = cursor.getColumnIndexOrThrow(
                        DocumentsContract.Document.COLUMN_LAST_MODIFIED
                    )
                    val mimeIdx = cursor.getColumnIndexOrThrow(
                        DocumentsContract.Document.COLUMN_MIME_TYPE
                    )

                    while (cursor.moveToNext()) {
                        val mimeType =
                            cursor.getString(mimeIdx) ?: "application/octet-stream"

                        // Skip directories
                        if (mimeType == DocumentsContract.Document.MIME_TYPE_DIR) continue

                        val childDocId = cursor.getString(idIdx)
                        val docUri = DocumentsContract.buildDocumentUriUsingTree(
                            treeUri, childDocId
                        )

                        files.add(
                            mapOf(
                                "uri" to docUri.toString(),
                                "name" to (cursor.getString(nameIdx) ?: ""),
                                "sizeBytes" to cursor.getLong(sizeIdx),
                                "modified" to cursor.getLong(modIdx),
                                "mimeType" to mimeType,
                            )
                        )
                    }
                }

                activity.runOnUiThread { result.success(files) }
            } catch (e: Exception) {
                activity.runOnUiThread {
                    result.error("LIST_ERROR", e.message, null)
                }
            }
        }.start()
    }

    // ---- File deletion ----

    private fun deleteDocument(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri") ?: run {
            result.error("INVALID_ARG", "uri is required", null)
            return
        }

        Thread {
            try {
                val uri = Uri.parse(uriString)
                val deleted =
                    DocumentsContract.deleteDocument(activity.contentResolver, uri)
                activity.runOnUiThread { result.success(deleted) }
            } catch (e: Exception) {
                activity.runOnUiThread {
                    result.error("DELETE_ERROR", e.message, null)
                }
            }
        }.start()
    }

    // ---- Copy to local cache ----

    private fun copyToCache(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri") ?: run {
            result.error("INVALID_ARG", "uri is required", null)
            return
        }
        val destPath = call.argument<String>("destPath") ?: run {
            result.error("INVALID_ARG", "destPath is required", null)
            return
        }

        Thread {
            try {
                val uri = Uri.parse(uriString)
                val inputStream = activity.contentResolver.openInputStream(uri)
                if (inputStream == null) {
                    activity.runOnUiThread {
                        result.error("READ_ERROR", "Cannot open file", null)
                    }
                    return@Thread
                }

                val destFile = File(destPath)
                destFile.parentFile?.mkdirs()

                inputStream.use { input ->
                    destFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }

                activity.runOnUiThread { result.success(destPath) }
            } catch (e: Exception) {
                activity.runOnUiThread {
                    result.error("COPY_ERROR", e.message, null)
                }
            }
        }.start()
    }
}
