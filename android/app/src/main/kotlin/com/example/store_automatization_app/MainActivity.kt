package com.example.store_automatization_app

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val ocrChannelName = "store_automatization_app/ocr"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ocrChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "recognizeText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("bad_arguments", "Falta la ruta de la imagen.", null)
                    return@setMethodCallHandler
                }

                recognizeText(path, result)
            }
    }

    private fun recognizeText(path: String, result: MethodChannel.Result) {
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

        try {
            val image = InputImage.fromFilePath(applicationContext, Uri.fromFile(File(path)))
            recognizer.process(image)
                .addOnSuccessListener { text ->
                    result.success(text.text)
                    recognizer.close()
                }
                .addOnFailureListener { error ->
                    result.error("ocr_failed", error.message, null)
                    recognizer.close()
                }
        } catch (error: Exception) {
            result.error("invalid_image", error.message, null)
            recognizer.close()
        }
    }
}
