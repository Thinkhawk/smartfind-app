import Foundation

class MLService {

    // --- Model Data ---
    private var vocab: [String: Int] = [:]
    private var wordVectors: [[Double]] = []
    private var topicVectors: [[Double]] = []

    private let stopWords: Set<String> = [
        "the", "and", "to", "of", "a", "in", "is", "that", "for", "it", "on", "with", "as",
        "was", "at", "by", "an", "be", "this", "which", "or", "from", "but", "not", "are",
        "your", "all", "have", "new", "more", "we", "will", "home", "can", "us", "about",
        "if", "page", "my", "has", "search", "free", "our", "one", "other", "do", "no",
        "information", "time", "they", "site", "he", "up", "may", "what", "their", "news",
        "out", "use", "any", "there", "see", "only", "so", "his", "when", "contact", "here",
        "business", "who", "web", "also", "now", "help", "get", "pm", "view", "online",
        "c", "e", "first", "am", "been", "would", "how", "were", "me", "s", "services",
        "some", "these", "click", "its", "like", "service", "x", "than", "find", "price",
        "date", "back", "top", "people", "had", "list", "name", "just", "over", "state",
        "year", "day", "into", "email", "two", "health", "n", "world", "re", "next", "used",
        "go", "b", "work", "last", "most"
    ]

    // --- Initialization ---
    func initialize() {
        print("iOS: Loading ML models...")
        DispatchQueue.global(qos: .userInitiated).async {
            self.vocab = self.loadJSON(name: "vocab") as? [String: Int] ?? [:]
            self.wordVectors = self.loadJSON(name: "word_vectors") as? [[Double]] ?? []
            self.topicVectors = self.loadJSON(name: "topic_vectors") as? [[Double]] ?? []

            print("iOS: Models loaded. Vocab: \(self.vocab.count), Vectors: \(self.wordVectors.count)")
        }
    }

    private func loadJSON(name: String) -> Any? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            print("Error: Could not find \(name).json in Bundle")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            print("Error loading \(name): \(error)")
            return nil
        }
    }

    // --- Classification Logic ---
    func classifyFile(text: String) -> [String: Any] {
        if vocab.isEmpty || wordVectors.isEmpty {
            print("iOS: Models not loaded yet.")
            return ["topic_number": -1, "confidence": 0.0]
        }

        let tokens = simplePreprocess(text)
        if tokens.isEmpty {
            return ["topic_number": -1, "confidence": 0.0]
        }

        guard let docVector = inferVector(tokens: tokens) else {
            return ["topic_number": -1, "confidence": 0.0]
        }

        // Calculate Cosine Similarity with all topics
        var bestTopicId = -1
        var bestScore = -1.0

        let docNorm = vectorNorm(docVector)
        if docNorm == 0 { return ["topic_number": -1, "confidence": 0.0] }

        for (index, topicVec) in topicVectors.enumerated() {
            let topicNorm = vectorNorm(topicVec)
            let dot = dotProduct(docVector, topicVec)

            if topicNorm > 0 {
                let score = dot / (topicNorm * docNorm)
                if score > bestScore {
                    bestScore = score
                    bestTopicId = index
                }
            }
        }

        print("iOS: Classified as Topic \(bestTopicId) (Conf: \(bestScore))")
        return ["topic_number": bestTopicId, "confidence": bestScore]
    }

    // --- Search Logic ---
    func searchDocuments(query: String) -> [String: Any] {
        // Basic semantic search simulation:
        // In a full implementation, you'd calculate the query vector here
        // and compare it against a database of stored file vectors.
        // For now, we simply return files that match the text keywords.

        let keywords = simplePreprocess(query)
        print("iOS: Searching for keywords: \(keywords)")

        // Note: Real semantic search requires persisting the index in `addToIndex`
        // Since we don't have a database set up in this snippet, we return empty
        // or you can implement a simple String-contains search here if you store paths.
        return ["results": []]
    }

    // --- Helper Functions ---

    private func simplePreprocess(_ text: String) -> [String] {
        let pattern = "[a-z]{3,}" // Match words with 3+ letters
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text.lowercased(), options: [], range: range)

        return matches.compactMap { match in
            if let range = Range(match.range, in: text) {
                let word = String(text[range])
                return stopWords.contains(word) ? nil : word
            }
            return nil
        }
    }

    private func inferVector(tokens: [String]) -> [Double]? {
        var vectors: [[Double]] = []

        for token in tokens {
            if let idx = vocab[token], idx < wordVectors.count {
                vectors.append(wordVectors[idx])
            }
        }

        if vectors.isEmpty { return nil }

        // Compute Mean Vector
        let dim = vectors[0].count
        var meanVector = Array(repeating: 0.0, count: dim)

        for vec in vectors {
            for i in 0..<dim {
                meanVector[i] += vec[i]
            }
        }

        return meanVector.map { $0 / Double(vectors.count) }
    }

    private func dotProduct(_ v1: [Double], _ v2: [Double]) -> Double {
        // Note: For production, use Accelerate framework vDSP_dotprD
        var sum = 0.0
        for i in 0..<min(v1.count, v2.count) {
            sum += v1[i] * v2[i]
        }
        return sum
    }

    private func vectorNorm(_ v: [Double]) -> Double {
        return sqrt(v.reduce(0) { $0 + $1 * $1 })
    }

    // --- Other Methods (Keep Stubbed/Simple) ---

    func summarizeFile(text: String) -> [String: Any] {
        if text.count < 50 { return ["summary": "ERROR_TOO_SHORT"] }
        // Simple extraction: First 2 sentences
        let sentences = text.components(separatedBy: ".")
        let summary = sentences.prefix(2).joined(separator: ".") + "."
        return ["summary": summary]
    }

    func addToIndex(filePath: String, content: String) {
        // TODO: Persist this content to a local SQLite or JSON file
        // if you want 'searchDocuments' to work across app restarts.
        print("iOS: Indexing request for \(filePath)")
    }

    func getIndexedPaths() -> [String] { return [] }

    func removeFromIndex(filePath: String) -> [String: Any] {
         print("iOS: Removing \(filePath) from index")
         return ["status": "removed"]
    }
}