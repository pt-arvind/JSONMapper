//
//  JSON.swift
//  JSON
//
//  Created by Juan Alvarez on 2/11/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import Foundation

public typealias JSONDict = [String: AnyObject]
public typealias JSONArray = [JSONDict]

public protocol JSONMappable {
    init(mapper: JSONMapper<Self>)
}

public struct JSONDateFormatter {
    private static var formatters: [String: NSDateFormatter] = [:]
    
    static func registerDateFormatter(formatter: NSDateFormatter, withKey key: String) {
        formatters[key] = formatter
    }
    
    static func dateFormatterWith(key: String) -> NSDateFormatter? {
        return formatters[key]
    }
}

public class JSONMapper <N: JSONMappable> {
    
    var jsonObject: JSONDict!
    
    public init() {}
    
    public func map(jsonFileURL url: NSURL) -> [N]? {
        if let data = NSData(contentsOfURL: url) {
            return map(data: data)
        }
        
        return nil
    }
    
    public func map(#dictionary: JSONDict) -> N {
        jsonObject = dictionary
        
        let object = N(mapper: self)
        
        return object
    }
    
    public func map(#array: JSONArray) -> [N] {
        let results = array.map({ (json: JSONDict) -> N in
            return self.map(dictionary: json)
        })
        
        return results
    }
    
    public func map(#array: [AnyObject]) -> [N]? {
        if let array = array as? JSONArray {
            return self.map(array: array)
        }
        
        return nil
    }
    
    public func map(#data: NSData) -> [N]? {
        var error: NSError?
        
        if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: .allZeros, error: &error) {
            return map(object: json)
        }
        
        return nil
    }
    
    public func map(#object: AnyObject) -> [N]? {
        if let dict = object as? JSONDict {
            return [map(dictionary: dict)]
        }
        
        if let array = object as? JSONArray {
            return map(array: array)
        }
        
        return nil
    }
}

private extension JSONMapper {
    
    func valueFor(keyPath: String) -> AnyObject? {
        return valueFor(keyPath, dictionary: jsonObject)
    }
    
    func valueFor(keyPath: String, dictionary: JSONDict) -> AnyObject? {
        let keys = keyPath.componentsSeparatedByString(".")
        
        if let key = keys.first, let object: AnyObject = dictionary[key] {
            switch object {
            case is NSNull:
                return nil
            case let dict as JSONDict where keys.count > 1:
                let tail = Array(keys[1..<keys.count])
                let tailString = ".".join(tail)
                
                return valueFor(tailString, dictionary: dict)
            default:
                return object
            }
        }
        
        return nil
    }
}

// MARK: NSDate

extension JSONMapper {
    
    public typealias DateTransformerFromInt = (value: Int) -> NSDate?
    public typealias DateTransformerFromString = (value: String) -> NSDate?
    
    public func dateFromIntFor(keyPath: String, transform: DateTransformerFromInt) -> NSDate? {
        if let value = intFor(keyPath) {
            return transform(value: value)
        }
        
        return nil
    }
    
    public func dateFromStringFor(keyPath: String, transform: DateTransformerFromString) -> NSDate? {
        if let value = stringFor(keyPath) {
            return transform(value: value)
        }
        
        return nil
    }
    
    public func dateFromStringFor(keyPath: String, withFormatterKey formatterKey: String) -> NSDate? {
        if let value = stringFor(keyPath), let formatter = JSONDateFormatter.dateFormatterWith(formatterKey) {
            return formatter.dateFromString(value)
        }
        
        return nil
    }
}

// MARK: URL

extension JSONMapper {
    
    public func urlFrom(keyPath: String) -> NSURL? {
        if let value = stringFor(keyPath) where !value.isEmpty {
            return NSURL(string: value)
        }
        
        return nil
    }
    
    public func urlValueFrom(keyPath: String, defaultValue: NSURL) -> NSURL {
        if let url = urlFrom(keyPath) {
            return url
        }
        
        return defaultValue
    }
}

// MARK: String

extension JSONMapper {
    
    public func stringFor(keyPath: String) -> String? {
        return valueFor(keyPath) as? String
    }
    
    public func stringValueFor(keyPath: String, defaultValue: String = "") -> String {
        if let value = stringFor(keyPath) {
            return value
        }
        
        return defaultValue
    }
}

// MARK: Int

extension JSONMapper {
    
    public func intFor(keyPath: String) -> Int? {
        return valueFor(keyPath) as? Int
    }
    
    public func intValueFor(keyPath: String, defaultValue: Int = 0) -> Int {
        if let value = intFor(keyPath) {
            return value
        }
        
        return defaultValue
    }
}

// MARK: Bool

extension JSONMapper {
    
    public func boolFor(keyPath: String) -> Bool? {
        if let value = valueFor(keyPath) as? Bool {
            return value
        }
        
        if let value = valueFor(keyPath) as? String {
            switch value.lowercaseString {
            case "true": return true
            case "false": return false
            case "yes": return true
            case "no": return false
            case "1": return true
            case "0": return false
            default:
                return nil
            }
        }
        
        return nil
    }
    
    public func boolValueFor(keyPath: String, defaultValue: Bool = false) -> Bool {
        if let value = boolFor(keyPath) {
            return value
        }
        
        return defaultValue
    }
}

// MARK: Double

extension JSONMapper {
    
    public func doubleFor(keyPath: String) -> Double? {
        return valueFor(keyPath) as? Double
    }
    
    public func doubleValueFor(keyPath: String, defaultValue: Double = 0.0) -> Double {
        if let value = doubleFor(keyPath) {
            return value
        }
        
        return defaultValue
    }
}

// MARK: Float

extension JSONMapper {
    
    public func floatFor(keyPath: String) -> Float? {
        return valueFor(keyPath) as? Float
    }
    
    public func floatValueFor(keyPath: String, defaultValue: Float = 0.0) -> Float {
        if let value = floatFor(keyPath) {
            return value
        }
        
        return defaultValue
    }
}

// MARK: Array

extension JSONMapper {
    
    public func arrayFor<T>(keyPath: String) -> [T]? {
        return valueFor(keyPath) as? [T]
    }
    
    public func arrayValueFor<T>(keyPath: String) -> [T] {
        if let value: [T] = arrayFor(keyPath) {
            return value
        }
        
        return []
    }
}

// MARK: Dictionary

extension JSONMapper {
    
    public func dictionaryFor(keyPath: String) -> JSONDict? {
        return valueFor(keyPath) as? JSONDict
    }
    
    public func dictionaryValueFor(keyPath: String) -> JSONDict {
        if let value = dictionaryFor(keyPath) {
            return value
        }
        
        return [:]
    }
}

// MARK: Object: JSONMappable

extension JSONMapper {
    
    public func objectFor<T: JSONMappable>(keyPath: String) -> T? {
        if let dict = dictionaryFor(keyPath) {
            let mapper = JSONMapper<T>()
            
            let object = mapper.map(dictionary: dict)
            
            return object
        }
        
        return nil
    }
    
    public func objectArrayFor<T: JSONMappable>(keyPath: String) -> [T]? {
        if let arrayValues = valueFor(keyPath) as? JSONArray {
            let mapper = JSONMapper<T>()
            
            return mapper.map(array: arrayValues)
        }
        
        return nil
    }
    
    public func objectArrayValueFor<T: JSONMappable>(keyPath: String) -> [T] {
        if let values: [T] = objectArrayFor(keyPath) {
            return values
        }
        
        return []
    }
    
    public func objectSetFor<T: JSONMappable>(keyPath: String) -> Set<T>? {
        if let values: [T] = objectArrayFor(keyPath) {
            return Set<T>(values)
        }
        
        return nil
    }
    
    public func objectSetValueFor<T: JSONMappable>(keyPath: String) -> Set<T> {
        if let values: Set<T> = objectSetFor(keyPath) {
            return values
        }
        
        return Set<T>()
    }
}

// MARK: Transforms

extension JSONMapper {
    public func transform<T, U>(keyPath: String, block: (value: T) -> U?) -> U? {
        if let aValue = valueFor(keyPath) as? T {
            return block(value: aValue)
        }
        
        return nil
    }
    
    public func transformValue<T, U>(keyPath: String, defaultValue: U, block: (value: T) -> U) -> U {
        if let aValue = valueFor(keyPath) as? T {
            return block(value: aValue)
        }
        
        return defaultValue
    }
}
