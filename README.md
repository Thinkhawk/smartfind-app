# SmartFind UI - Complete File Flow Walkthrough

## Overview

SmartFind is a **Flutter + Python hybrid application** that bridges the Flutter UI with Python ML models via **Chaquopy**. This document explains how data flows through the system.

---

## System Architecture

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                    FLUTTER UI LAYER                         â”‚
â”‚                   (lib/main.dart, screens/)                 â”‚
â”‚  - User Interface                                           â”‚
â”‚  - User Interactions                                        â”‚
â”‚  - State Management (Provider)                              â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                       â”‚ MethodChannel Communication
                       â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚              KOTLIN BRIDGE LAYER                            â”‚
â”‚           (MainActivity.kt)                                 â”‚
â”‚  - MethodChannel Handlers                                  â”‚
â”‚  - Python Module Loading                                   â”‚
â”‚  - Result Serialization                                    â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                       â”‚ Chaquopy Python Integration
                       â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                 PYTHON LAYER                                â”‚
â”‚      (android/app/src/main/python/)                        â”‚
â”‚  - File Processing                                         â”‚
â”‚  - Text Analysis                                           â”‚
â”‚  - Data Processing                                         â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

## File Structure

```
smartfind_ui_perplexity/
â”œâ”€â”€ lib/
â”‚   â”œâ”€â”€ main.dart                          # App entry point
â”‚   â”œâ”€â”€ screens/
â”‚   â”‚   â”œâ”€â”€ home_screen.dart               # Main UI screen
â”‚   â”‚   â”œâ”€â”€ file_browser_screen.dart       # File selection
â”‚   â”‚   â””â”€â”€ results_screen.dart            # Results display
â”‚   â”œâ”€â”€ services/
â”‚   â”‚   â”œâ”€â”€ ml_service.dart                # Python<->Flutter bridge
â”‚   â”‚   â”œâ”€â”€ file_service.dart              # File operations
â”‚   â”‚   â””â”€â”€ permission_service.dart        # Permissions handling
â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”œâ”€â”€ file_model.dart                # File data model
â”‚   â”‚   â””â”€â”€ classification_result.dart     # Result models
â”‚   â””â”€â”€ widgets/
â”‚       â”œâ”€â”€ file_card.dart                 # File display widget
â”‚       â””â”€â”€ result_card.dart               # Result display widget
â”‚
â”œâ”€â”€ android/
â”‚   â”œâ”€â”€ app/src/main/
â”‚   â”‚   â”œâ”€â”€ java/.../MainActivity.kt       # Kotlin bridge
â”‚   â”‚   â””â”€â”€ python/                        # Python modules
â”‚   â”‚       â”œâ”€â”€ __init__.py                # Package init
â”‚   â”‚       â”œâ”€â”€ classifier.py              # Classification logic
â”‚   â”‚       â”œâ”€â”€ summarizer.py              # Summarization logic
â”‚   â”‚       â”œâ”€â”€ file_reader.py             # File reading
â”‚   â”‚       â”œâ”€â”€ search_engine.py           # Search functionality
â”‚   â”‚       â””â”€â”€ recommender.py             # Recommendations
â”‚   â”œâ”€â”€ settings.gradle                    # Gradle settings
â”‚   â””â”€â”€ app/build.gradle                   # Gradle config
â”‚
â”œâ”€â”€ pubspec.yaml                           # Flutter dependencies
â””â”€â”€ assets/
    â””â”€â”€ models/                            # ML models (if any)
```

---

## FLOW 1: File Classification

### Step 1: User Interaction (Flutter UI)
**File: `lib/screens/home_screen.dart`**

```dart
// User taps "Classify" button
FloatingActionButton(
  onPressed: () async {
    // 1. Pick a file
    File? selectedFile = await FilePicker.pickFile();
    
    // 2. Read file content
    String content = await file_service.readFile(selectedFile.path);
    
    // 3. Call ML service
    await ml_service.classifyFile(content);
  }
)
```

**What happens:**
- User selects a file from device
- File service reads the file content as text
- ML service is invoked with the text

---

### Step 2: Flutter â†’ Kotlin Bridge
**File: `lib/services/ml_service.dart`**

```dart
class MLService {
  static const platform = MethodChannel('com.smartfind/ml');
  
  Future<ClassificationResult> classifyFile(String text) async {
    try {
      // 1. Call Kotlin method via MethodChannel
      final result = await platform.invokeMethod('classifyFile', {
        'text': text,
      });
      
      // 2. Parse returned result
      return ClassificationResult.fromMap(result);
    } catch (e) {
      print('Error: $e');
    }
  }
}
```

**What happens:**
- Creates a `MethodChannel` named `'com.smartfind/ml'`
- Calls Kotlin's `classifyFile` method with file text
- Waits for Kotlin to return results
- Parses the JSON response into a Dart object

---

### Step 3: Kotlin Receives Call
**File: `android/app/src/main/java/.../MainActivity.kt`**

```kotlin
private fun setupMLChannel(flutterEngine: FlutterEngine) {
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ML_CHANNEL)
        .setMethodCallHandler { call, result ->
            when (call.method) {
                // 1. Receive the call from Flutter
                "classifyFile" -> handleClassifyFile(call.arguments as Map<*, *>, result)
            }
        }
}

private fun handleClassifyFile(args: Map<*, *>, result: MethodChannel.Result) {
    try {
        // 2. Extract arguments
        val text = args["text"] as? String ?: ""
        val modelPath = getModelPath()
        
        // 3. Load Python module
        val module = python.getModule("classifier")
        
        // 4. Call Python function
        val pyResult = module.callAttr("classify_file", modelPath, text)
        val pyMap: Map<String, Any?> = pyResult.asMap() as Map<String, Any?>
        
        // 5. Build response
        val response: MutableMap<String, Any> = mutableMapOf()
        response["topic_number"] = (pyMap["topic_number"]?.toString()?.toIntOrNull() ?: -1)
        response["confidence"] = (pyMap["confidence"]?.toString()?.toDoubleOrNull() ?: 0.0)
        
        // 6. Send back to Flutter
        result.success(response)
    } catch (e: Exception) {
        result.error("CLASSIFY_ERROR", e.message, null)
    }
}
```

**What happens:**
- Kotlin receives the MethodChannel call
- Extracts the text from arguments
- Loads the Python `classifier` module via Chaquopy
- Calls Python's `classify_file()` function
- Gets back Python dict with results
- Converts to Kotlin map and sends to Flutter

---

### Step 4: Python Processing
**File: `android/app/src/main/python/classifier.py`**

```python
def classify_file(model_path, text):
    """Classify document using keyword matching"""
    try:
        if not text or len(text.strip()) < 10:
            return {"topic_number": -1, "confidence": 0.0}
        
        text_lower = text.lower()
        
        # Simple keyword matching
        categories = {
            0: (["finance", "money", "budget"], "Finance"),
            1: (["work", "project", "task"], "Work"),
            2: (["personal", "diary", "note"], "Personal"),
            3: (["research", "paper", "study"], "Research"),
        }
        
        scores = {}
        for topic_num, (keywords, name) in categories.items():
            matches = sum(1 for kw in keywords if kw in text_lower)
            if matches > 0:
                scores[topic_num] = matches / len(keywords)
        
        if not scores:
            return {"topic_number": -1, "confidence": 0.0}
        
        best_topic = max(scores.items(), key=lambda x: x[1])
        return {
            "topic_number": best_topic[0], 
            "confidence": min(best_topic[1], 1.0)
        }
    except Exception as e:
        print(f"Classification error: {e}")
        return {"topic_number": -1, "confidence": 0.0}
```

**What happens:**
- Python receives text and model path
- Analyzes text for keywords (currently simple matching)
- Scores each category based on keyword matches
- Returns the best matching category with confidence score
- Returns dict with `topic_number` and `confidence`

---

### Step 5: Result Returns to Flutter
**Kotlin â†’ Flutter â†’ UI**

```
Kotlin result.success(response)
    â†“
MethodChannel sends JSON back
    â†“
Flutter ml_service.classifyFile() receives result
    â†“
ClassificationResult.fromMap(result) parses it
    â†“
UI updates with classification results
```

**File: `lib/models/classification_result.dart`**

```dart
class ClassificationResult {
  final int topicNumber;
  final double confidence;
  
  ClassificationResult({
    required this.topicNumber,
    required this.confidence,
  });
  
  factory ClassificationResult.fromMap(Map<dynamic, dynamic> map) {
    return ClassificationResult(
      topicNumber: map['topic_number'] ?? -1,
      confidence: map['confidence'] ?? 0.0,
    );
  }
}
```

---

## FLOW 2: File Reading

### Step 1: User Selects File
**User interaction â†’ `file_service.readFile(filePath)`**

---

### Step 2: Kotlin Bridge
**File: `android/app/src/main/java/.../MainActivity.kt`**

```kotlin
private fun handleReadFile(args: Map<*, *>, result: MethodChannel.Result) {
    try {
        val filePath = args["file_path"] as? String ?: ""
        
        // Load Python module
        val module = python.getModule("file_reader")
        
        // Call Python function
        val pyResult = module.callAttr("read_file", filePath)
        val pyMap: Map<String, Any?> = pyResult.asMap() as Map<String, Any?>
        val content = pyMap["content"]?.toString() ?: ""
        
        // Return to Flutter
        val response: MutableMap<String, Any> = mutableMapOf()
        response["content"] = content
        result.success(response)
    } catch (e: Exception) {
        result.error("READ_ERROR", e.message, null)
    }
}
```

---

### Step 3: Python Reads File
**File: `android/app/src/main/python/file_reader.py`**

```python
def read_file(file_path):
    """Read file and extract text"""
    try:
        if not file_path:
            return {"content": ""}
        
        file_path = file_path.strip()
        
        # Text files
        if file_path.endswith(('.txt', '.md')):
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                return {"content": content[:5000]}
        
        # PDF files
        elif file_path.endswith('.pdf'):
            from PyPDF2 import PdfReader
            with open(file_path, 'rb') as f:
                pdf = PdfReader(f)
                text = ''
                for page in pdf.pages[:10]:
                    text += page.extract_text()
                return {"content": text[:5000]}
        
        # DOCX files
        elif file_path.endswith('.docx'):
            from docx import Document
            doc = Document(file_path)
            text = '\n'.join([p.text for p in doc.paragraphs])
            return {"content": text[:5000]}
        
        else:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                return {"content": content[:5000]}
    except Exception as e:
        print(f"File reading error: {e}")
        return {"content": ""}
```

**What happens:**
- Detects file type by extension
- Uses appropriate library (PyPDF2 for PDF, python-docx for DOCX, etc.)
- Extracts text content
- Limits to 5000 chars for performance
- Returns dict with `content` key

---

## FLOW 3: File Summarization

### Step 1: User Action
```
User selects file â†’ reads content â†’ calls summarizeFile()
```

---

### Step 2: Kotlin Bridge
```kotlin
private fun handleSummarizeFile(args: Map<*, *>, result: MethodChannel.Result) {
    val text = args["text"] as? String ?: ""
    val module = python.getModule("summarizer")
    val pyResult = module.callAttr("summarize_file", text)
    // ... parse and return
}
```

---

### Step 3: Python Summarizes
**File: `android/app/src/main/python/summarizer.py`**

```python
def summarize_file(text, max_sentences=3):
    """Extract key sentences for summary"""
    import re
    
    sentences = re.split(r'[.!?]+', text)
    sentences = [s.strip() for s in sentences if len(s.strip()) > 20]
    
    # Score sentences by position and length
    scored = []
    for i, sent in enumerate(sentences):
        position_score = 1.0 if i < 2 else 0.5
        length_score = min(len(sent.split()) / 20.0, 1.0)
        score = (position_score * 0.6 + length_score * 0.4)
        scored.append((sent, score))
    
    # Get top sentences
    top = sorted(scored, key=lambda x: x[1], reverse=True)[:max_sentences]
    summary = '. '.join([s[0] for s in top]) + '.'
    return {"summary": summary[:300]}
```

---

## Data Flow Diagram

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ 1. USER INTERACTION (Flutter)                              â”‚
â”‚    - Taps button                                            â”‚
â”‚    - Selects file                                           â”‚
â”‚    - Enters query                                           â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                       â”‚
                       â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ 2. SERVICE CALL (ml_service.dart)                          â”‚
â”‚    - Creates MethodChannel call                            â”‚
â”‚    - Passes arguments                                      â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                       â”‚
                       â–¼ MethodChannel (JSON)
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ 3. KOTLIN HANDLER (MainActivity.kt)                        â”‚
â”‚    - Receives MethodChannel call                           â”‚
â”‚    - Parses arguments                                      â”‚
â”‚    - Loads Python module                                   â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                       â”‚
                       â–¼ Chaquopy
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ 4. PYTHON PROCESSING (*.py files)                          â”‚
â”‚    - Processes data                                        â”‚
â”‚    - Returns dict result                                   â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                       â”‚
                       â–¼ Python dict
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ 5. KOTLIN SERIALIZATION (MainActivity.kt)                  â”‚
â”‚    - Converts dict to Kotlin Map                           â”‚
â”‚    - Calls result.success()                                â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                       â”‚
                       â–¼ MethodChannel (JSON)
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ 6. FLUTTER PARSING (ml_service.dart)                       â”‚
â”‚    - Receives result from MethodChannel                    â”‚
â”‚    - Parses JSON to Dart model                             â”‚
â”‚    - Returns to calling screen                             â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                       â”‚
                       â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ 7. UI UPDATE (screens/*.dart)                              â”‚
â”‚    - Updates State                                         â”‚
â”‚    - Rebuilds widgets                                      â”‚
â”‚    - Displays results                                      â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

## Communication Protocol

### MethodChannel Format

**Flutter â†’ Kotlin:**
```dart
await platform.invokeMethod('classifyFile', {
  'text': 'sample text content',
});
```

**Converts to JSON:**
```json
{
  "method": "classifyFile",
  "arguments": {
    "text": "sample text content"
  }
}
```

**Kotlin receives and parses:**
```kotlin
val args = call.arguments as Map<*, *>
val text = args["text"] as String
```

**Kotlin returns result:**
```kotlin
result.success(mapOf("topic_number" to 2, "confidence" to 0.85))
```

**Converts back to JSON:**
```json
{
  "topic_number": 2,
  "confidence": 0.85
}
```

**Flutter receives and parses:**
```dart
final result = await platform.invokeMethod(...);
final topicNumber = result['topic_number']; // 2
final confidence = result['confidence'];     // 0.85
```

---

## Key Files and Their Roles

| File | Purpose | Language |
|------|---------|----------|
| `main.dart` | App entry point, routing | Dart |
| `ml_service.dart` | MethodChannel communication | Dart |
| `file_service.dart` | File operations, permissions | Dart |
| `MainActivity.kt` | Kotlin-Python bridge | Kotlin |
| `classifier.py` | Classification logic | Python |
| `file_reader.py` | File reading (PDF, DOCX, TXT) | Python |
| `summarizer.py` | Text summarization | Python |
| `search_engine.py` | Document search indexing | Python |
| `recommender.py` | File recommendations | Python |
| `pubspec.yaml` | Flutter dependencies | YAML |
| `build.gradle` | Python packages & Android config | Groovy |

---

## Dependency Flow

```
pubspec.yaml (Flutter packages)
    â†“
    â”œâ”€ provider (state management)
    â”œâ”€ permission_handler (file access)
    â”œâ”€ open_file (file opening)
    â””â”€ path_provider (file paths)

build.gradle (Python packages)
    â†“
    â”œâ”€ requests (HTTP)
    â”œâ”€ PyPDF2 (PDF reading)
    â”œâ”€ python-docx (DOCX reading)
    â”œâ”€ chardet (encoding detection)
    â””â”€ jsonlines (JSON processing)
```

---

## Error Handling Flow

```
User action
    â†“ (if error)
try-catch in Flutter screen
    â†“
logs error
    â†“
shows SnackBar/Dialog to user

OR

try-catch in ml_service.dart
    â†“
catches MethodChannel error
    â†“
returns error object
    â†“
screen handles error

OR

try-catch in MainActivity.kt
    â†“
catches Python error
    â†“
result.error() sends back to Flutter
    â†“
ml_service catches and handles

OR

try-except in Python
    â†“
logs error
    â†“
returns error dict
    â†“
Kotlin parses and returns to Flutter
```

---

## Summary

**SmartFind's Architecture:**

1. **User interacts** with Flutter UI (button tap, file selection)
2. **Flutter calls** ML service method
3. **ML service uses** MethodChannel to communicate with Kotlin
4. **Kotlin receives** call and loads Python module via Chaquopy
5. **Python processes** the data (classify, summarize, read, search)
6. **Python returns** results as dictionary
7. **Kotlin converts** dict to Kotlin Map and sends back
8. **Flutter receives** JSON via MethodChannel
9. **Flutter parses** and updates UI with results

This hybrid approach allows you to:
- âœ… Use Flutter for beautiful, responsive UI
- âœ… Use Python for heavy ML/data processing
- âœ… Access device files and permissions via Kotlin
- âœ… Leverage pure-Python packages via Chaquopy

---

## Next Steps

To extend this architecture:

1. **Add ML Models**: Place trained models in `assets/models/`
2. **Add More Python Functions**: Create new `.py` files and call via MethodChannel
3. **Improve Classification**: Replace keyword matching with real ML models (Top2Vec, etc.) for production
4. **Add Remote API**: Call backend servers for heavy processing
5. **Implement Search**: Use full-text search with indexed documents
6. **Add UI Features**: More screens, animations, offline support