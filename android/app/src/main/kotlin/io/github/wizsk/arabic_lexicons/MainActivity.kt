package io.github.wizsk.arabic_lexicons

import android.widget.Toast

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNELTOAST = "app/toast"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNELTOAST)
        .setMethodCallHandler { call, result ->
            if (call.method == "showToast") {
                val message = call.argument<String>("message") ?: ""
                val short = call.argument<Boolean>("short") ?: true
                Toast.makeText(
                    applicationContext,
                    message,
                    if (short) Toast.LENGTH_SHORT else Toast.LENGTH_LONG
                ).show()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}

