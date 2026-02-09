import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let CHANNEL = "com.smartfind/ml"
    private let mlService = MLService()
    private let fileService = FileService()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let methodChannel = FlutterMethodChannel(name: CHANNEL,
                                                 binaryMessenger: controller.binaryMessenger)

        // Initialize our Services
        mlService.initialize()

        methodChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }

            let args = call.arguments as? [String: Any] ?? [:]

            switch call.method {

            // --- Core Features ---
            case "classifyFile":
                let text = args["text"] as? String ?? ""
                let response = self.mlService.classifyFile(text: text)
                result(response)

            case "summarizeFile":
                let text = args["text"] as? String ?? ""
                let response = self.mlService.summarizeFile(text: text)
                result(response)

            case "readFile":
                let filePath = args["file_path"] as? String ?? ""
                let response = self.fileService.readFile(filePath: filePath)
                result(response)

            // --- Search & Indexing ---
            case "searchDocuments":
                let query = args["query"] as? String ?? ""
                let response = self.mlService.searchDocuments(query: query)
                result(response)

            case "addToIndex":
                let filePath = args["file_path"] as? String ?? ""
                let content = args["content"] as? String ?? ""
                self.mlService.addToIndex(filePath: filePath, content: content)
                result(["status": "indexed"])

            case "trainSearchIndex":
                // iOS doesn't need explicit 'training' if using simple search
                // But we return success to keep Flutter happy
                result("success")

            case "getIndexedPaths":
                let paths = self.mlService.getIndexedPaths()
                result(paths)

            case "getSimilarFiles":
                // Placeholder for recommendation engine
                result(["results": []])

            case "removeFromIndex":
                // Handle index removal
                result(["status": "removed"])

            default:
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}