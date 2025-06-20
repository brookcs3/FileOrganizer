#if canImport(AppIntents)
import AppIntents
#else
public struct DataEncoder {
    private var buffer = Data()
    public mutating func encode(_ data: Data) throws {
        buffer = data
    }
    public func encodedData() -> Data { buffer }
}

public struct DataDecoder {
    private var buffer: Data
    public init(data: Data) { self.buffer = data }
    public mutating func decode(_ type: Data.Type) throws -> Data {
        return buffer
    }
}

public protocol IntentValue: Codable {}
#endif
