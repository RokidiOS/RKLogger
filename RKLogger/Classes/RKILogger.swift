//
//  RKILogger.swift
//  RKILogger
//
//  Created by Amos on 2022/5/7.
//

import Foundation
import CocoaLumberjack

@objcMembers
public class RKILogger: NSObject, RKLoggerInterface {
    
    fileprivate var fileLogger: DDFileLogger?
    
    public init(with logDirPath: String?) {
        super.init()
        
        var logsDirectory: String = logDirPath ?? ""
        if logsDirectory.isEmpty == true {
            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            logsDirectory = documentPath.path + "/RKILogger"
            if FileManager.default.fileExists(atPath: logsDirectory) == false {
                do {
                    try FileManager.default.createDirectory(atPath: logsDirectory, withIntermediateDirectories: true, attributes: nil)
                } catch _ {
                }
            }
        }
        
        let fileMannager = DDLogFileManagerDefault(logsDirectory: logsDirectory)
        fileLogger = DDFileLogger(logFileManager: fileMannager)
        guard let fileLogger = fileLogger else {
            return
        }
        
        fileLogger.doNotReuseLogFiles = false
        
        print("RKILoger: logFilePath: \(fileLogger.currentLogFileInfo?.filePath ?? "")")
        
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
            print("RKILoger: renameFile: \(logFileName)")
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
    
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

public func RKLogError<T>(_ message: T,
                          _ logger: RKILogger? = RKLogMgr.shared.iLogger,
                          _ alias: String = "RKILogger",
                          _ fileName: String = #file,
                          _ funcName : String = #function,
                          _ line: Int = #line) {
    RKILog(message, logger, .error, alias)
}

public func RKLogWarning<T>(_ message: T,
                            _ logger: RKILogger? = RKLogMgr.shared.iLogger,
                            _ alias: String = "RKILogger",
                            _ fileName: String = #file,
                            _ funcName : String = #function,
                            _ line: Int = #line) {
    RKILog(message, logger, .warning, alias)
}

public func RKLogInfo<T>(_ message: T,
                         _ logger: RKILogger? = RKLogMgr.shared.iLogger,
                         _ alias: String = "RKILogger",
                         _ fileName: String = #file,
                         _ funcName : String = #function,
                         _ line: Int = #line) {
    RKILog(message, logger, .info, alias)
}

public func RKLogVerbose<T>(_ message: T,
                            _ logger: RKILogger? = RKLogMgr.shared.iLogger,
                            _ alias: String = "RKILogger",
                            _ fileName: String = #file,
                            _ funcName : String = #function,
                            _ line: Int = #line) {
    RKILog(message, logger, .verbose, alias)
}

fileprivate func RKILog<T>(_ message: T,
                           _ logger: RKILogger? = RKLogMgr.shared.iLogger,
                           _ logLevel: RKLogLevel = .verbose,
                           _ alias: String = "RKILogger",
                           _ fileName: String = #file,
                           _ funcName : String = #function,
                           _ line: Int = #line) {
    
    guard let logger = logger,
          RKLogMgr.shared.logLevel != .None,
          logLevel != .None,
          logLevel.rawValue <= RKLogMgr.shared.logLevel.rawValue else {
        return
    }
    
    var useLogLevel: RKLogLevel = .None
    if logLevel.rawValue > RKLogLevel.None.rawValue {
        useLogLevel = logLevel
    } else if RKLogMgr.shared.logLevel.rawValue > useLogLevel.rawValue {
        useLogLevel = logger.logLevel
    }
    
    let file = (fileName as NSString).lastPathComponent
    let log = "\(alias):[\(logger.formatter.string(from: Date()))][\(stringForLogLevel(logLevel: useLogLevel))] | \(message) | [\(file) \(line) \(funcName)\(getThreadName())]"
    
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

extension RKILogger: DDLogFormatter {
    
    public func format(message logMessage: DDLogMessage) -> String? {
        return logMessage.message
    }
}
