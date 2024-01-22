import Foundation

public struct CommandLineTool {
    
    static public func convertPath(_ path: String) -> String {
        return path == "." ? FileManager.default.currentDirectoryPath : path
    }
    
    @discardableResult
    static public func executeShell(command: String,
                      currentDirectoryPath: String? = nil,
                      environment: [String: String]? = nil) -> String {
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = ["-cl", command]
        process.launchPath = "/bin/zsh"
        process.environment = ["LANG": "en_US.UTF-8"]
        
        if let environment = environment {
            process.environment = environment
        }
        if let currentDirectoryPath = currentDirectoryPath {
            process.currentDirectoryPath = currentDirectoryPath
        }
        let outputHandler = pipe.fileHandleForReading
        outputHandler.waitForDataInBackgroundAndNotify()
        
        var output = ""

        process.terminationHandler = { returnedTask in
            NotificationCenter.default.removeObserver(outputHandler)
        }

        let dataNotificationName = NSNotification.Name.NSFileHandleDataAvailable
        NotificationCenter.default.addObserver(forName: dataNotificationName, object: outputHandler, queue: nil) {  notification in

            let data = outputHandler.availableData

            if let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !line.isEmpty {
                print(line)
                output = output + line + "\n"
            }
            outputHandler.waitForDataInBackgroundAndNotify()
        }

        process.launch()
        process.waitUntilExit()
        
        return output
    }
    
}
