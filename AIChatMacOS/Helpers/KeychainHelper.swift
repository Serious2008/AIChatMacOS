//
//  KeychainHelper.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 10.08.2025.
//

import Foundation

// MARK: - Keychain helper (simple)
final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    private let service = "MacChatLLM"
    private let account = "openai_api_key"

//    var apiKey: String? { get() }

    func saveAPIKey(_ key: String) {
        let data = Data(key.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "MacChatLLM",
            kSecAttrAccount: "openai_api_key"
        ]
        let attrsToUpdate: [CFString: Any] = [
            kSecValueData: data
            // kSecAttrAccessible трогать не нужно при апдейте
        ]
        let status = SecItemUpdate(query as CFDictionary, attrsToUpdate as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    func getAPIKey() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data, let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
}

extension KeychainHelper {
    var apiKeyComputed: String? { getAPIKey() }
    static var sharedKey: String? { shared.getAPIKey() }
}

extension KeychainHelper {
    // Convenience computed to use in DI closure
    var apiKey: String? { getAPIKey() }
}
