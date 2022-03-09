//
//  RKLogger.swift
//  RKLogger
//
//  Created by chzy on 2021/10/29.
//

import Foundation



@objc public enum RKLogLevel: Int {
    case verbose
    case info
    case warning
    case error
    case none
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
//        logDirPath.appendingPath(path: formatter.string(from: Date()) + ".log")
    }()
    
    public func saveSDKLog(_ text: String, atOnce: Bool = false) {
        
        objc_sync_enter(self)
        RKLogMgr.shared.tempLog += "\(text)\n"
        objc_sync_exit(self)
        
        guard atOnce == true || RKLogMgr.shared.tempLog.count > 100000 else {
            return
        }
        
        do {
            if !FileManager.default.fileExists(atPath: RKLogMgr.shared.logPath) {
                FileManager.default.createFile(atPath: RKLogMgr.shared.logPath, contents: nil)
            }
            
            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: RKLogMgr.shared.logPath))
            let stringToWrite = RKLogMgr.shared.tempLog
            
            fileHandle.seekToEndOfFile()
            fileHandle.write(stringToWrite.data(using: String.Encoding.utf8)!)
            
            RKLogMgr.shared.tempLog = ""
            
        } catch _ {
        }
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
              _ logLevel: RKLogLevel = RKLogMgr.shared.logLevel,
              _ fileName: String = #file,
              _ funcName : String = #function,
              _ line: Int = #line) {
    if logLevel != .none {
        let file = (fileName as NSString).lastPathComponent
        let log = "RKLogger:[\(RKLogMgr.shared.formatter.string(from: Date()))][\(stringForLogLevel(logLevel: logLevel))] | \(message) | [\(file) \(line) \(funcName)\(getThreadName())]"
        print(log)
        RKLogMgr.shared.saveSDKLog(log)
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
