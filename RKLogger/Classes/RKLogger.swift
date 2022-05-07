//
//  RKLogger.swift
//  RKLogger
//
//  Created by chzy on 2021/10/29.
//

import Foundation
import CocoaLumberjack

@objcMembers
public class RKLogMgr: NSObject, RKLoggerInterface {
    
    public static let shared = RKLogMgr()
    
    public override init() {
        super.init()
        addLogers()
    }
    
    fileprivate var fileLogger: DDFileLogger?
    
    private func addLogers() {
        
        let fileMannager = DDLogFileManagerDefault(logsDirectory: logsDirectory)
        fileLogger = DDFileLogger(logFileManager: fileMannager)
        guard let fileLogger = fileLogger else {
            return
        }
        
        fileLogger.doNotReuseLogFiles = false
        
        print("RKLoger: logFilePath: \(fileLogger.currentLogFileInfo?.filePath ?? "")")
        
        fileLogger.logFormatter = self
        DDLog.add(DDOSLogger.sharedInstance)
        DDLog.add(fileLogger)
        
        // 默认 10G
        maxFileSize = 10 * 1024 * 1024 * 1024
    }
    
    // log 等级
    public var logLevel: RKLogLevel = .None
    
    public var logFileName: String? {
        get {
            return fileLogger?.currentLogFileInfo?.fileName
        } set {
            guard let logFileName = newValue, logFileName.isEmpty == false else {
                return
            }
            fileLogger?.currentLogFileInfo?.renameFile(to: logFileName)
        }
    }
    
    public var maxFileSize: UInt64 = 0 {
        didSet {
            fileLogger?.maximumFileSize = UInt64(maxFileSize) * 1000
        }
    }
    
    public var rollingFrequency: TimeInterval = 0 {
        didSet {
            fileLogger?.rollingFrequency = rollingFrequency
        }
    }
    
    public func clearLogCache() {
        fileLogger?.currentLogFileInfo?.reset()
    }
    
    // MARK: - 自定义
    
    public var iLogger: RKILogger?
    
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    // log 保存地址
    fileprivate var logsDirectory: String = {
        let cachesPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logDirPath = cachesPath.path + "/RKLogger"
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
                     _ alias: String = "RKLogger",
                     _ fileName: String = #file,
                     _ funcName : String = #function,
                     _ line: Int = #line) {
    
    guard RKLogMgr.shared.logLevel != .None,
          logLevel != .None,
          logLevel.rawValue <= RKLogMgr.shared.logLevel.rawValue else {
        return
    }
    
    var useLogLevel: RKLogLevel = .None
    if logLevel.rawValue > RKLogLevel.None.rawValue {
        useLogLevel = logLevel
    } else if RKLogMgr.shared.logLevel.rawValue > useLogLevel.rawValue {
        useLogLevel = RKLogMgr.shared.logLevel
    }
    
    let file = (fileName as NSString).lastPathComponent
    let log = "\(alias):[\(RKLogMgr.shared.formatter.string(from: Date()))][\(stringForLogLevel(logLevel: useLogLevel))] | \(message) | [\(file) \(line) \(funcName)\(getThreadName())]"
    
    switch useLogLevel {
    case .error:
        DDLogError(log)
    case .warning:
        DDLogWarn(log)
    case .info:
        DDLogInfo(log)
    case .verbose:
        DDLogVerbose(log)
    default: break
    }
}

func stringForLogLevel(logLevel: RKLogLevel) -> String {
    switch logLevel {
    case .verbose:
        return "VERBOSE"
    case .info:
        return "INFO"
    case .warning:
        return "WARNING"
    case .error:
        return "ERROR"
    case .None:
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
