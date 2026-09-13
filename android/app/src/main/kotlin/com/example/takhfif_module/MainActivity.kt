package com.example.takhfif_module

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.khatoon/contacts"
    private val PICK_CONTACT_REQUEST = 2026
    private val PERMISSION_REQUEST_CODE = 2027
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickContact") {
                if (pendingResult != null) {
                    result.error("BUSY", "Contact picker is active", null)
                    return@setMethodCallHandler
                }
                pendingResult = result

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && checkSelfPermission(Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
                    requestPermissions(arrayOf(Manifest.permission.READ_CONTACTS), PERMISSION_REQUEST_CODE)
                } else {
                    launchContactPicker()
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun launchContactPicker() {
        try {
            val intent = Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)
            startActivityForResult(intent, PICK_CONTACT_REQUEST)
        } catch (e: Exception) {
            val res = pendingResult
            pendingResult = null
            res?.error("UNAVAILABLE", e.message, null)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.size > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                launchContactPicker()
            } else {
                val res = pendingResult
                pendingResult = null
                res?.error("PERMISSION_DENIED", "دسترسی به مخاطبین تأیید نشد", null)
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_CONTACT_REQUEST) {
            val result = pendingResult
            pendingResult = null
            if (result == null) return

            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                var cursor: Cursor? = null
                try {
                    val contactUri: Uri = data.data!!
                    val projection = arrayOf(
                        ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                        ContactsContract.CommonDataKinds.Phone.NUMBER
                    )
                    cursor = contentResolver.query(contactUri, projection, null, null, null)
                    if (cursor != null && cursor.moveToFirst()) {
                        val nameIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                        val numberIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)

                        val name = if (nameIndex >= 0) cursor.getString(nameIndex) else ""
                        val phone = if (numberIndex >= 0) cursor.getString(numberIndex) else ""

                        val resultMap = HashMap<String, String>()
                        resultMap["name"] = name ?: ""
                        resultMap["phone"] = phone ?: ""
                        result.success(resultMap)
                    } else {
                        result.success(null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                } finally {
                    cursor?.close()
                }
            } else {
                result.success(null)
            }
        }
    }
}
