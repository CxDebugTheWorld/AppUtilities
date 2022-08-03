//
//  File.swift
//  
//
//  Created by Jonas Zell on 03.08.22.
//

import SwiftUI

struct Format {
    /// The common formatter to use.
    static let formatter: NumberFormatter = NumberFormatter()
    
    /// The common date formatter to use.
    static let dateFormatter = DateFormatter()
    
    public static func format(_ fp: Float, decimalPlaces: Int = 2, minDecimalPlaces: Int = 0) -> String {
        return format(Double(fp), decimalPlaces: decimalPlaces, minDecimalPlaces: minDecimalPlaces)
    }
    
    public static func format(_ fp: CGFloat, decimalPlaces: Int = 2, minDecimalPlaces: Int = 0) -> String {
        return format(Double(fp), decimalPlaces: decimalPlaces, minDecimalPlaces: minDecimalPlaces)
    }
    
    public static func format(_ fp: Double, decimalPlaces: Int = 2, minDecimalPlaces: Int = 0, alwaysShowSign: Bool = false) -> String {
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = decimalPlaces
        formatter.minimumFractionDigits = minDecimalPlaces
        formatter.usesGroupingSeparator = true
        
        var result = formatter.string(from: NSNumber(value: fp)) ?? String(fp)
        if alwaysShowSign && fp >= 0 {
            result = "+" + result
        }
        
        return result
    }
    
    public static func format(_ fp: Decimal, decimalPlaces: Int = 2, minDecimalPlaces: Int = 0) -> String {
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = decimalPlaces
        formatter.minimumFractionDigits = minDecimalPlaces
        formatter.usesGroupingSeparator = true
        
        return formatter.string(from: NSDecimalNumber(decimal: fp))!
    }
    
    public static func format(_ value: Int) -> String {
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
    
    public static func format(_ value: Int, alwaysShowSign: Bool) -> String {
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        
        var result = formatter.string(from: NSNumber(value: value)) ?? String(value)
        if alwaysShowSign && value >= 0 {
            result = "+" + result
        }
        
        return result
    }
    
    public static func formatYear(_ value: Int) -> String {
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
    
    public static func formatPercentage(_ p: Double, decimalPlaces: Int = 2, minDecimalPlaces: Int = 0) -> String {
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = decimalPlaces
        formatter.minimumFractionDigits = minDecimalPlaces
        
        return "\(formatter.string(from: NSNumber(value: p * 100)) ?? String(p))%"
    }
    
    public static func formatOrdinal(_ value: Int) -> String {
        formatter.numberStyle = .ordinal
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
    
    public static func formattedTimeView(_ timeLimit: TimeInterval,
                                         fontSize: CGFloat,
                                         fontColor: Color) -> some View {
        let minutes = Int(timeLimit) / 60 % 60
        let seconds = Int(timeLimit) % 60
        
        return HStack {
            if minutes > 0 || (minutes == 0 && seconds == 0) {
                HStack(spacing: 0) {
                    Text(verbatim: "\(minutes)")
                        .font(.system(size: fontSize).monospacedDigit())
                        .foregroundColor(fontColor)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text("ui.minute.short")
                        .font(.system(size: fontSize * 0.75).smallCaps())
                        .foregroundColor(fontColor)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            
            if seconds > 0 {
                HStack(spacing: 0) {
                    Text(verbatim: "\(seconds)")
                        .font(.system(size: fontSize).monospacedDigit())
                        .foregroundColor(fontColor)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text("ui.second.short")
                        .font(.system(size: fontSize * 0.75).smallCaps())
                        .foregroundColor(fontColor)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
    }
    
    public static func formatTimeForSentence(_ timeLimit: TimeInterval) -> String {
        let hours = Int(timeLimit) / (60 * 60)
        let minutes = Int(timeLimit) / 60 % 60
        let seconds = Int(timeLimit) % 60
        
        if hours == 0, minutes == 0 {
            if seconds == 1 {
                return "1 \(String(NSLocalizedString("ui.second", comment: "")))"
            }
            
            return String.localizedStringWithFormat(NSLocalizedString("ui.n-seconds", comment: ""), seconds)
        }
        
        if hours == 0, seconds == 0 {
            if minutes == 1 {
                return "1 \(String(NSLocalizedString("ui.minute", comment: "")))"
            }
            
            return String.localizedStringWithFormat(NSLocalizedString("ui.n-minutes", comment: ""), minutes)
        }
        
        var str: String = ""
        if hours == 1 {
            str += "1 \(String(NSLocalizedString("ui.hour", comment: "")))"
            
            if minutes > 0  && seconds > 0 {
                str += ", "
            }
            else if minutes > 0 || seconds > 0 {
                str += " \(String(NSLocalizedString("ui.and", comment: ""))) "
            }
        }
        else if hours > 0 {
            str += String.localizedStringWithFormat(NSLocalizedString("ui.n-hours", comment: ""), hours)
            
            if minutes > 0  && seconds > 0 {
                str += ", "
            }
            else if minutes > 0 || seconds > 0 {
                str += " \(String(NSLocalizedString("ui.and", comment: ""))) "
            }
        }
        
        if minutes == 1 {
            str += "1 \(String(NSLocalizedString("ui.minute", comment: "")))"
            
            if seconds > 0 {
                str += " \(String(NSLocalizedString("ui.and", comment: ""))) "
            }
        }
        else if minutes > 0 {
            str += String.localizedStringWithFormat(NSLocalizedString("ui.n-minutes", comment: ""), minutes)
            
            if seconds > 0 {
                str += " \(String(NSLocalizedString("ui.and", comment: ""))) "
            }
        }
        
        if seconds == 1 {
            str += "1 \(String(NSLocalizedString("ui.second", comment: "")))"
        }
        else if seconds > 0 {
            str += String.localizedStringWithFormat(NSLocalizedString("ui.n-seconds", comment: ""), seconds)
        }
        
        return str
    }
    
    /// Format a time limit for display.
    public static func formatTimeLimit(_ timeLimit: TimeInterval, includeMilliseconds: Bool? = true) -> String {
        let hours = Int(timeLimit) / (60 * 60)
        let minutes = Int(timeLimit) / 60 % 60
        let seconds = Int(timeLimit) % 60
        let rest = timeLimit - timeLimit.rounded(.towardZero)
        
        let includeMilliseconds = includeMilliseconds ?? (timeLimit < 1)
        if hours > 0 {
            return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        }
        else {
            if includeMilliseconds {
                let milliseconds = Int(rest * 1000) / 100
                return String(format: "%02i:%02i.%01i", minutes, seconds, milliseconds)
            }
            
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
    
    /// Format a date for display.
    public static func formatDate(_ date: Date, timeZone: TimeZone = .current, usePhrases: Bool = false) -> String {
        if usePhrases {
            let today = Date().convertToTimeZone(timeZone: timeZone)
            let currentDay = Int((today.timeIntervalSinceReferenceDate / (24 * 60 * 60)).rounded(.towardZero))
            let otherDay = Int((date.timeIntervalSinceReferenceDate / (24 * 60 * 60)).rounded(.towardZero))
            
            if currentDay == otherDay {
                return String.localizedStringWithFormat(NSLocalizedString("ui.today", comment: ""))
            }
            if currentDay == otherDay + 1 {
                return String.localizedStringWithFormat(NSLocalizedString("ui.yesterday", comment: ""))
            }
            if currentDay - otherDay <= 5 && currentDay > otherDay {
                return String.localizedStringWithFormat(NSLocalizedString("ui.n-days-ago", comment: ""), currentDay - otherDay)
            }
            if currentDay == otherDay - 1 {
                return String.localizedStringWithFormat(NSLocalizedString("ui.tomorrow", comment: ""))
            }
        }
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = timeZone
        
        return dateFormatter.string(from: date)
    }
    
    /// Format a date for display.
    public static func formatDateTime(_ date: Date, timeZone: TimeZone = .current) -> String {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = timeZone
        
        return dateFormatter.string(from: date)
    }
    
    /// Format a time for display.
    public static func formatTime(_ date: Date, timeZone: TimeZone = .current) -> String {
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = timeZone
        
        return dateFormatter.string(from: date)
    }
}

