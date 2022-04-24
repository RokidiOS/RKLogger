//
//  RKLogger.swift
//  RKLogger
//
//  Created by chzy on 2021/10/29.
//

import Foundation
import CocoaLumberjack

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
    
    public override init() {
        super.init()
        addLogers()
    }
    
    private func addLogers() {

        let fileMannager = DDLogFileManagerDefault(logsDirectory: logPath)
        let fileLogger = DDFileLogger(logFileManager: fileMannager)
        fileLogger.doNotReuseLogFiles = true
        fileLogger.currentLogFileInfo?.renameFile(to: formatter.string(from: Date()) + ".log")
        fileLogger.logFormatter = self
        DDLog.add(DDOSLogger.sharedInstance)
        DDLog.add(fileLogger)
        
    }
    
    // log 等级
    public var logLevel: RKLogLevel = .none
    
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

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
        return logDirPath
    }()
    
}

/// SDK debug 日志打印
/// - Parameter message: 消息体
public func RKLog<T>(_ message: T,
                     _ logLevel: RKLogLevel = .verbose,
                     _ fileName: String = #file,
                     _ funcName : String = #function,
                     _ line: Int = #line) {
    
    let file = (fileName as NSString).lastPathComponent
    var log: String?
    if logLevel.rawValue & RKLogMgr.shared.logLevel.rawValue != 0 {
        log = "RKLogger:[\(RKLogMgr.shared.formatter.string(from: Date()))][\(stringForLogLevel(logLevel: logLevel))] | \(message) | [\(file) \(line) \(funcName)\(getThreadName())]"
    }
    guard let log = log else { return }

    switch logLevel {
    case .none:
        print(log)
    case .error:
        DDLogError("❌" + log)
    case .warning:
        DDLogWarn("⚠️" + log)
    case .info:
        DDLogInfo("💾" + log)
    case .verbose:
        DDLogVerbose("🔎" + log)
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

extension RKLogMgr: DDLogFormatter {
    
   public func format(message logMessage: DDLogMessage) -> String? {
           return logMessage.message
       }
    
}
