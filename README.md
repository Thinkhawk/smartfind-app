# SmartFind: Adaptive Text File Manager

**Bridging the Semantic Gap in Mobile Storage**

SmartFind is an intelligent, offline-first file management application designed to transform how users interact with their digital archives. By moving beyond rigid filename-dependent architectures, SmartFind utilizes Natural Language Processing (NLP) to understand conceptual intent rather than just literal string matches.

---

## 🧠 The Problem: Digital Hoarding & Navigation Fatigue

Modern smartphones house thousands of heterogeneous files, leading to several critical pain points:
* **Filename Amnesia:** Users often struggle to retrieve documents like `scan_2023.pdf` when searching for conceptual terms like "Rent Agreement."
* **Semantic Gap:** The disconnect between how humans remember information and how computers traditionally store it.
* **Dark Data:** Images containing vital text (receipts, scans) remain "Black Boxes" that traditional managers cannot index.

---

## 💡 The Solution: Conceptual Intelligence

SmartFind acts as a proactive digital assistant through four foundational AI pillars:

### **1. Semantic Search Engine**
Uses high-dimensional vectorization to facilitate contextual retrieval. By converting content into mathematical embeddings, you can search for "Financial Support" and surface documents containing "Scholarship" or "Grant" even if the search term is missing from the filename.

The system calculates relevance using **Cosine Similarity**:
$$d_{cos}(\mathbf{A}, \mathbf{B}) = \frac{\mathbf{A} \cdot \mathbf{B}}{\|\mathbf{A}\| \|\mathbf{B}\|}$$

### **2. Automated Content Intelligence**
Eliminates the burden of manual organization. Utilizing a **Nearest Centroid Classifier**, SmartFind autonomously analyzes linguistic patterns to sort files into semantic categories like *Finance*, *Health*, or *Education*.

### **3. Intelligent Summarizer**
Leverages the **TextRank algorithm** to provide a "cognitive shortcut." It identifies the "center of gravity" within long-form reports or academic papers to extract the 3–5 most significant sentences instantly.

### **4. Context-Aware Recommendations**
Proactively identifies "look-alike" files within the local library. When viewing a document, the system suggests semantically related files (e.g., suggesting "Car Insurance" while viewing "Vehicle Registration") regardless of their physical folder location.

---

## 🛡️ Privacy & Data Sovereignty

SmartFind is engineered with a **Privacy-First local AI philosophy**:
* **100% Offline:** All vectorization, OCR extraction, and classification tasks occur entirely on-device.
* **No Cloud Dependency:** Sensitive financial, legal, or personal documents never leave the user's physical possession.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (for reactive, cross-platform UI).
* **Backend Intelligence:** Python 3.11 core integrated via the **Chaquopy bridge**.
* **AI/ML Libraries:** NumPy, Scikit-learn, Gensim (Word2Vec), and SpaCy.
* **Computer Vision:** Google ML Kit OCR pipeline for extracting text from "Dark Data" (images).

---

## 📊 Performance Benchmarks

* **Search Retrieval:** Achieved a perfect **Mean Reciprocal Rank (MRR) score of 1.0**.
* **Recommendation Precision:** Validated at **95.00% accuracy**.

---

Developed by **REVANTH V** as a Capstone Project at **PES University**, Bengaluru.