//
//  RKLoggerInterface.swift
//  RKILogger
//
//  Created by Amos on 2022/5/6.
//

import Foundation

@objc public enum RKLogLevel: Int {
    case None    = 0    // 关闭日志打印
    case error   = 1    // 打印错误日志
    case warning = 2    // 打印警告日志
    case info    = 3    // 打印info日志
    case verbose = 4    // 打印全量日志
}

@objc public protocol RKLoggerInterface: NSObjectProtocol {
    
    // log 等级 @RKLogLevel 默认None 关闭
    @objc var logLevel: RKLogLevel { get set }
    // log 文件名，带路径
    @objc var logFileName: String? { get set }
    // log 最大容量（kb），默认不限，超过将会回滚， 和周期哪个先触发 先生效
    @objc var maxFileSize: UInt64 { get set }
    // log 回滚周期（s），默认24小时，超过将会回滚， 和最大容量哪个先触发 先生效
    @objc var rollingFrequency: TimeInterval { get set }
    // 清除日志缓存
    @objc func clearLogCache()
}
