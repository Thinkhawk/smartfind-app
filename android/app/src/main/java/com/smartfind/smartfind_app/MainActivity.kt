package com.smartfind.smartfind_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.chaquo.python.Python
import com.chaquo.python.PyObject
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
        copyModelsFromAssets()
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
                        "searchKeyword" -> handleSearchKeyword(call.arguments as Map<*, *>, result)
                        "addToIndex" -> handleAddToIndex(call.arguments as Map<*, *>, result)
                        "getRecommendations" -> handleGetRecommendations(call.arguments as Map<*, *>, result)
                        "trainRecommender" -> handleTrainRecommender(call.arguments as Map<*, *>, result)
                        "trainSearchIndex" -> handleTrainSearchIndex(call.arguments as Map<*, *>, result)
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

    private fun handleTrainSearchIndex(args: Map<*, *>, result: MethodChannel.Result) {
        try {
            @Suppress("UNCHECKED_CAST")
            val files = args["files"] as? Map<String, String> ?: emptyMap<String, String>()

            val dataDir = applicationContext.filesDir.absolutePath
            val module = python.getModule("search_engine")

            // FIX: Convert Map to JSON String manually to avoid Chaquopy type issues
            // Using standard org.json library which is always available in Android
            val jsonObject = org.json.JSONObject(files)
            val jsonString = jsonObject.toString()

            // Run training on background thread
            Thread {
                try {
                    // Pass the JSON string instead of the Map
                    val pyResult = module.callAttr("train_local_index", dataDir, jsonString)
                    runOnUiThread {
                        val status = pyResult?.callAttr("get", "status")?.toString()
                        result.success(status)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error in python training", e)
                    runOnUiThread {
                        result.error("PY_EXEC_ERROR", e.message, null)
                    }
                }
            }.start()

        } catch (e: Exception) {
            Log.e(TAG, "Error initiating training", e)
            result.error("TRAIN_ERROR", e.message, null)
        }
    }

    private fun handleClassifyFile(args: Map<*, *>, result: MethodChannel.Result) {
        try {
            val text = args["text"] as? String ?: ""
            val modelDir = getModelDir()

            val module = python.getModule("classifier")
            val pyResult = module.callAttr("classify_file", modelDir, text)

            // Safe extraction from PyObject dict
            val topicNumberStr = pyResult?.callAttr("get", "topic_number")?.toString()
            val confidenceStr = pyResult?.callAttr("get", "confidence")?.toString()

            val topicNumber = topicNumberStr?.toIntOrNull() ?: -1
            val confidence = confidenceStr?.toDoubleOrNull() ?: 0.0

            val response = mapOf(
                "topic_number" to topicNumber,
                "confidence" to confidence
            )

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

            val summary = pyResult?.callAttr("get", "summary")?.toString() ?: ""
            val response = mapOf("summary" to summary)
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

            val content = pyResult?.callAttr("get", "content")?.toString() ?: ""
            val response = mapOf("content" to content)
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
            val pyResult = module.callAttr("search_semantic", dataDir, query)
            // Extract list from PyObject
            val pyList = pyResult?.callAttr("get", "results")?.asList() ?: emptyList<PyObject>()
            val results = pyList.map { it.toString() }

            val response = mapOf("results" to results)
            result.success(response)
        } catch (e: Exception) {
            Log.e(TAG, "Error searching documents", e)
            result.error("SEARCH_ERROR", e.message, null)
        }
    }

    private fun handleSearchKeyword(args: Map<*, *>, result: MethodChannel.Result) {
        try {
            val query = args["query"] as? String ?: ""
            val dataDir = applicationContext.filesDir.absolutePath
            val module = python.getModule("search_engine")

            val pyResult = module.callAttr("search_keyword", dataDir, query)

            // Extract result list
            val pyList = pyResult?.callAttr("get", "results")?.asList() ?: emptyList<PyObject>()
            val results = pyList.map { it.toString() }

            val response = mapOf("results" to results)
            result.success(response)
        } catch (e: Exception) {
            Log.e(TAG, "Error in keyword search", e)
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
            val response = mapOf("status" to "indexed")
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

            val pyList = pyResult?.callAttr("get", "recommendations")?.asList() ?: emptyList<PyObject>()
            val recommendations = pyList.map { it.toString() }

            val response = mapOf("recommendations" to recommendations)
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
            val response = mapOf("status" to "trained")
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

    private fun copyModelsFromAssets() {
        val targetDir = File(getModelDir())
        if (!targetDir.exists()) {
            targetDir.mkdirs()
        }

        try {
            val modelFiles = applicationContext.assets.list("models")

            if (!modelFiles.isNullOrEmpty()) {
                for (fileName in modelFiles) {
                    val outFile = File(targetDir, fileName)
                    if (!outFile.exists()) {
                        try {
                            applicationContext.assets.open("models/$fileName").use { input ->
                                outFile.outputStream().use { output ->
                                    input.copyTo(output)
                                }
                            }
                            Log.i(TAG, "Copied asset: $fileName")
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to copy asset $fileName: ${e.message}")
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error listing assets: ${e.message}")
        }
    }

    private fun getModelDir(): String {
        return File(applicationContext.filesDir, "models").absolutePath
    }
}