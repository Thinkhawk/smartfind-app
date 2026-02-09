import Foundation

class FileService {

    func readFile(filePath: String) -> [String: Any] {
        do {
            let fileURL = URL(fileURLWithPath: filePath)
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            return ["content": content]
        } catch {
            print("iOS Error reading file: \(error)")
            return ["content": ""]
        }
    }
}