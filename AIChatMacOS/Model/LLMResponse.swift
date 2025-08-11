//
//  LLMResponse.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 12.08.2025.
//

import Foundation

// MARK: - Universal JSON value

public enum JSONValue: Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode(Double.self) { self = .number(v) }
        else if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode([String: JSONValue].self) { self = .object(v) }
        else if let v = try? c.decode([JSONValue].self) { self = .array(v) }
        else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let b): try c.encode(b)
        case .number(let d): try c.encode(d)
        case .string(let s): try c.encode(s)
        case .array(let a): try c.encode(a)
        case .object(let o): try c.encode(o)
        }
    }

    // Convenience accessors
    public var string: String? { if case .string(let s) = self { s } else { nil } }
    public var double: Double? { if case .number(let d) = self { d } else { nil } }
    public var bool: Bool? { if case .bool(let b) = self { b } else { nil } }
    public var array: [JSONValue]? { if case .array(let a) = self { a } else { nil } }
    public var object: [String: JSONValue]? { if case .object(let o) = self { o } else { nil } }
}

// MARK: - Enums with forward-compat "unknown" case

public enum LLMStatus: Equatable, Codable {
    case success
    case needsClarification
    case error
    case unknown(String)

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "success": self = .success
        case "needs_clarification": self = .needsClarification
        case "error": self = .error
        default: self = .unknown(raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .success: try c.encode("success")
        case .needsClarification: try c.encode("needs_clarification")
        case .error: try c.encode("error")
        case .unknown(let s): try c.encode(s)
        }
    }
}

public enum LLMTaskType: Equatable, Codable {
    case qa, summarize, rewrite, classify, extract, plan, code, calc, other
    case unknown(String)

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "qa": self = .qa
        case "summarize": self = .summarize
        case "rewrite": self = .rewrite
        case "classify": self = .classify
        case "extract": self = .extract
        case "plan": self = .plan
        case "code": self = .code
        case "calc": self = .calc
        case "other": self = .other
        default: self = .unknown(raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .qa: try c.encode("qa")
        case .summarize: try c.encode("summarize")
        case .rewrite: try c.encode("rewrite")
        case .classify: try c.encode("classify")
        case .extract: try c.encode("extract")
        case .plan: try c.encode("plan")
        case .code: try c.encode("code")
        case .calc: try c.encode("calc")
        case .other: try c.encode("other")
        case .unknown(let s): try c.encode(s)
        }
    }
}

// MARK: - Models

public struct LLMResponse: Codable, Equatable {
    public let version: String
    public let status: LLMStatus
    public let taskType: LLMTaskType
    public let answer: LLMAnswer
    public let citations: [String]
    public let followUpQuestions: [String]
    public let clarificationsNeeded: [String]
    public let error: LLMResponseError
    public let meta: LLMMeta
}

public struct LLMAnswer: Codable, Equatable {
    public let text: String?
    public let items: [JSONValue]        // списки/пункты любого типа
    public let structured: JSONValue     // произвольная доменная структура (обычно .object)
}

public struct LLMResponseError: Codable, Equatable {
    public let code: String?
    public let message: String?
}

public struct LLMMeta: Codable, Equatable {
    public let language: String
    public let confidence: Double
}

// MARK: - JSON helpers

public enum JSONCoding {
    public static func decoding() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase // task_type -> taskType
        return d
    }

    public static func encoding(pretty: Bool = true) -> JSONEncoder {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase   // taskType -> task_type
        if pretty { e.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys] }
        return e
    }
}
