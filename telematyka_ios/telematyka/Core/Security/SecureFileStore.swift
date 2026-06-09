import CryptoKit
import Foundation

enum SecureFileStore {
    private static let magic = "TMENC1"

    private static var storageKey: SymmetricKey {
        let hash = SHA256.hash(data: Data("telematyka-local-db-key-v1".utf8))
        return SymmetricKey(data: Data(hash))
    }

    static func encrypt(_ data: Data) throws -> Data {
        let sealed = try AES.GCM.seal(data, using: storageKey)
        guard let combined = sealed.combined else {
            throw NSError(domain: "SecureFileStore", code: 1)
        }
        var payload = Data(magic.utf8)
        payload.append(combined)
        return payload
    }

    static func decrypt(_ payload: Data) throws -> Data {
        let magicData = Data(magic.utf8)
        guard payload.count > magicData.count,
              payload.prefix(magicData.count) == magicData else {
            return payload
        }
        let cipher = payload.dropFirst(magicData.count)
        let box = try AES.GCM.SealedBox(combined: cipher)
        return try AES.GCM.open(box, using: storageKey)
    }
}
