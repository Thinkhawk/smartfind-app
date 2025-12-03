package com.smartfind.smartfind_ui_perplexity

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import java.io.File

class MainActivity: FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val ML_CHANNEL = "com.smartfind/ml"
        private const val PERMISSION_CHANNEL = "com.example.smartfind/permissions"
    }

    private lateinit var python: Python

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initializePython()
        copyModelFromAssets()
        setupMLChannel(flutterEngine)
        setupPermissionsChannel(flutterEngine)
    }

    private fun initializePython() {
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(this))
            Log.i(TAG, "Python runtime initialized")
        }
        python = Python.getInstance()
    }

    private fun setupMLChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ML_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "classifyFile" -> handleClassifyFile(call.arguments as Map<*, *>, result)
                        "summarizeFile" -> handleSummarizeFile(call.arguments as Map<*, *>, result)
                        "readFile" -> handleReadFile(call.arguments as Map<*, *>, result)
                        "searchDocuments" -> handleSearchDocuments(call.arguments as Map<*, *>, result)
                        "addToIndex" -> handleAddToIndex(call.arguments as Map<*, *>, result)
                        "getRecommendations" -> handleGetRecommendations(call.arguments as Map<*, *>, result)
                        "trainRecommender" -> handleTrainRecommender(call.arguments as Map<*, *>, result)
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error in ML operation: ${call.method}", e)
                    result.error("ML_ERROR", e.message, null)
                }
            }
    }

    private fun setupPermissionsChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openAllFilesAccessSettings") {
                    openAllFilesAccessSettings(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun handleClassifyFile(args: Map<*, *>, result: MethodChannel.Result) {
        try {
            val text = args["text"] as? String ?: ""
            val modelPath = getModelPath()
            val module = python.getModule("classifier")
            val pyResult = module.callAttr("classify_file", modelPath, text)
            val pyMap: Map<String, Any?> = pyResult.asMap() as Map<String, Any?>

            val response: MutableMap<String, Any> = mutableMapOf()
            response["topic_number"] = (pyMap["topic_number"]?.toString()?.toIntOrNull() ?: -1)
            response["confidence"] = (pyMap["confidence"]?.toString()?.toDoubleOrNull() ?: 0.0)

            result.success(response)
        } catch (e: Exception) {
            Log.e(TAG, "Error classifying file", e)
            result.error("CLASSIFY_ERROR", e.message, null)
        }
    }

    private fun handleSummarizeFile(args: Map<*, *>, result: MethodChannel.Result) {
        try {
            val text = args["text"] as? String ?: ""
            val module = python.getModule("summarizer")
            val pyResult = module.callAttr("summarize_file", text)
            val pyMap: Map<String, Any?> = pyResult.asMap() as Map<String, Any?>
            val summary = pyMap["summary"]?.toString() ?: ""

            val response: MutableMap<String, Any> = mutableMapOf()
            response["summary"] = summary

            result.success(response)
        } catch (e: Exception) {
            Log.e(TAG, "Error summarizing file", e)
            result.error("SUMMARIZE_ERROR", e.message, null)
        }
    }

    private fun handleReadFile(args: Map<*, *>, result: MethodChannel.Result) {
        try {
            val filePath = args["file_path"] as? String ?: ""
            val module = python.getModule("file_reader")
            val pyResult = module.callAttr("read_file", filePath)
            val pyMap: Map<String, Any?> = pyResult.asMap() as Map<String, Any?>
            val content = pyMap["content"]?.toString() ?: ""

            val response: MutableMap<String, Any> = mutableMapOf()
            response["content"] = content

            result.success(response)
        } catch (e: Exception) {
            Log.e(TAG, "Error reading file", e)
            result.error("READ_ERROR", e.message, null)
        }
    }

    private fun handleSearchDocuments(args: Map<*, *>, result: MethodChannel.Result) {
        try {
            val query = args["query"] as? String ?: ""
            val dataDir = applicationContext.filesDir.absolutePath
            val module = python.getModule("search_engine")
            val pyResult = module.callAttr("search_documents", dataDir, query)
            val pyMap: Map<String, Any?> = pyResult.asMap() as Map<String, Any?>
            val results = (pyMap["results"] as? List<*>)?.map { it.toString() } ?: emptyList()

            val response: MutableMap<String, Any> = mutableMapOf()
            response["results"] = results

            result.success(response)
        } catch (e: Exception) {
            Log.e(TAG, "Error searching documents", e)
            result.error("SEARCH_ERROR", e.message, null)
        }
    }

    private fun handleAddToIndex(args: Map<*, *>, result: MethodChannel.Result) {
        try {
            val filePath = args["file_path"] as? String ?: ""
            val content = args["content"] as? String ?: ""
            val dataDir = applicationContext.filesDir.absolutePath
            val module = python.getModule("search_engine")
            module.callAttr("add_to_index", dataDir, filePath, content)

            val response: MutableMap<String, Any> = mutableMapOf()
            response["status"] = "indexed"

            result.success(response)
        } catch (e: Exception) {
            Log.e(TAG, "Error adding to index", e)
            result.error("INDEX_ERROR", e.message, null)
        }
    }

    private fun handleGetRecommendations(args: Map<*, *>, result: MethodChannel.Result) {
        try {
            val month = args["month"] as? Int ?: 1
            val weekday = args["weekday"] as? Int ?: 1
            val hour = args["hour"] as? Int ?: 12
            val dataDir = applicationContext.filesDir.absolutePath
            val module = python.getModule("recommender")
            val pyResult = module.callAttr("get_recommendations", dataDir, month, weekday, hour)
            val pyMap: Map<String, Any?> = pyResult.asMap() as Map<String, Any?>
            val recommendations = (pyMap["recommendations"] as? List<*>)?.map { it.toString() } ?: emptyList()

            val response: MutableMap<String, Any> = mutableMapOf()
            response["recommendations"] = recommendations

            result.success(response)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting recommendations", e)
            result.error("RECOMMEND_ERROR", e.message, null)
        }
    }

    private fun handleTrainRecommender(args: Map<*, *>, result: MethodChannel.Result) {
        try {
            val logPath = args["log_path"] as? String ?: ""
            val dataDir = applicationContext.filesDir.absolutePath
            val module = python.getModule("recommender")
            module.callAttr("train_recommender", dataDir, logPath)

            val response: MutableMap<String, Any> = mutableMapOf()
            response["status"] = "trained"

            result.success(response)
        } catch (e: Exception) {
            Log.e(TAG, "Error training recommender", e)
            result.error("TRAIN_ERROR", e.message, null)
        }
    }

    private fun openAllFilesAccessSettings(result: MethodChannel.Result) {
        try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                    data = Uri.parse("package:$packageName")
                }
            } else {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                }
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening settings", e)
            result.success(false)
        }
    }

    private fun copyModelFromAssets() {
        val modelFile = File(getModelPath())

        if (!modelFile.exists()) {
            try {
                val assetManager = applicationContext.assets
                // Try to copy .pkl file first
                try {
                    assetManager.open("models/classifier_model.pkl").use { input ->
                        modelFile.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }
                    Log.i(TAG, "Model copied to: ${modelFile.absolutePath}")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to copy .pkl model: ${e.message}")
                    // Fallback: try .top2vec
                    assetManager.open("models/classifier_model.top2vec").use { input ->
                        modelFile.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error copying model: ${e.message}")
            }
        }
    }

    private fun getModelPath(): String {
        return "${applicationContext.filesDir.absolutePath}/classifier_model.pkl"
    }

}
