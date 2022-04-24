//
//  RKLogger.swift
//  RKLogger
//
//  Created by chzy on 2021/10/29.
//

import Foundation

@objc public enum RKLogLevel: Int {
    case none    = 0b0000
    case error   = 0b0001
    case warning = 0b0010
    case info    = 0b0100
    case verbose = 0b1111
}

@objcMembers
public class RKLogMgr: NSObject {
    
    public static let shared = RKLogMgr()
    // log 等级
    public var logLevel: RKLogLevel = .none
    
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    // 临时保存log
    var tempLog: String = ""
    // log 保存地址
    public var logPath: String = {
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let logDirPath = cachesPath.path + "/rksdk_logs/" + formatter.string(from: Date())
        if FileManager.default.fileExists(atPath: logDirPath) == false {
            do {
                try FileManager.default.createDirectory(atPath: logDirPath, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
        }
        formatter.dateFormat = "yyyyMMddHHmmss"
        
        return appendingPath(logDirPath, formatter.string(from: Date()) + ".log")
    }()
    
    public func saveSDKLog(_ text: String, atOnce: Bool = false) {
        
        guard text.isEmpty == false else {
            return
        }
        
        objc_sync_enter(self)
        tempLog += "\(text)\n"
        if atOnce == true || tempLog.count > 100000 {
            let writeLog = tempLog
            tempLog = ""
            do {
                if !FileManager.default.fileExists(atPath: logPath) {
                    FileManager.default.createFile(atPath: logPath, contents: nil)
                }
                
                let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: logPath))
                if let writeData = writeLog.data(using: String.Encoding.utf8) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(writeData)
                }
            } catch _ {
            }
        }
        objc_sync_exit(self)
    }
    
    class func appendingPath(_ dirPath: String, _ path: String) -> String {
        if let lastChar =  dirPath.last {
            let pathFirstChar = path.first
            return (lastChar == "/" || pathFirstChar == "/") ? dirPath.appending(path):dirPath.appending("/\(path)")
        }
        return path
    }
}

/// SDK debug 日志打印
/// - Parameter message: 消息体
public func RKLog<T>(_ message: T,
                     _ logLevel: RKLogLevel = .verbose,
                     _ fileName: String = #file,
                     _ funcName : String = #function,
                     _ line: Int = #line) {
    
    let file = (fileName as NSString).lastPathComponent
    let log = "RKLogger:[\(RKLogMgr.shared.formatter.string(from: Date()))][\(stringForLogLevel(logLevel: logLevel))] | \(message) | [\(file) \(line) \(funcName)\(getThreadName())]"
    RKLogMgr.shared.saveSDKLog(log)
    
    if logLevel.rawValue & RKLogMgr.shared.logLevel.rawValue != 0 {
        print(log)
    }
    
}

func stringForLogLevel(logLevel:RKLogLevel) -> String {
    switch logLevel {
    case .verbose:
        return "VERBOSE"
    case .info:
        return "INFO"
    case .warning:
        return "WARNING"
    case .error:
        return "ERROR"
    case .none:
        return "NONE"
    default: return ""
    }
}

func getThreadName() -> String {
    
#if os(Linux)
    // on 9/30/2016 not yet implemented in server-side Swift:
    // > import Foundation
    // > Thread.isMainThread
    return ""
#else
    if Thread.isMainThread {
        return ""
    } else {
        let name = __dispatch_queue_get_label(nil)
        let threadName = String(cString: name, encoding: .utf8) ?? Thread.current.description
        return " " + threadName
    }
#endif
}
