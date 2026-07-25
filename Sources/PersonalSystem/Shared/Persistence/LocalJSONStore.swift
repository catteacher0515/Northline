import Foundation

enum LocalJSONStore {
    static func applicationSupportDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("PersonalSystem", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func load<T: Decodable>(_ type: T.Type, from fileName: String) -> T? {
        do {
            let directory = try applicationSupportDirectory()
            let url = directory.appendingPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            return nil
        }
    }

    static func save<T: Encodable>(_ value: T, to fileName: String) {
        do {
            let directory = try applicationSupportDirectory()
            let url = directory.appendingPathComponent(fileName)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(value)
            try data.write(to: url, options: [.atomic])
        } catch {
            NSLog("LocalJSONStore save failed for %@: %@", fileName, String(describing: error))
        }
    }

    static func delete(_ fileName: String) {
        do {
            let directory = try applicationSupportDirectory()
            let url = directory.appendingPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: url.path) else {
                return
            }
            try FileManager.default.removeItem(at: url)
        } catch {
            NSLog("LocalJSONStore delete failed for %@: %@", fileName, String(describing: error))
        }
    }
}
