//
// Copyright (c) Vatsal Manot
//

import Foundation
import SQLite3

actor Kasa {
    typealias Storable = Codable & Identifiable
    
    var database: OpaquePointer
    let sqliteTransient = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)
    
    init(name: String) async throws {
        try await self.init(databasePath: Kasa.databasePath(for: name))
    }
    
    init(databasePath: String) async throws {
        var databasePointer: OpaquePointer?
        let isFirstTimeInitialization = !FileManager.default.fileExists(atPath: databasePath)
        let openResult = sqlite3_open_v2(databasePath, &databasePointer, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_NOMUTEX, nil)
        if openResult == SQLITE_OK && databasePointer != nil {
            database = databasePointer!
            
            sqlite3_busy_timeout(database, 1000)
            
            if isFirstTimeInitialization {
                try? await execute(sql: "PRAGMA journal_mode = WAL")
            }
        } else {
            throw NSError(domain: "sqlite3_open_v2 failed with code: \(openResult)", code: -1, userInfo: nil)
        }
    }
    
    deinit {
        sqlite3_close(database)
    }
}

extension Kasa {
    enum Predicate {
        case property(key: String, value: Any)
        indirect case and(Predicate, Predicate)
        indirect case or(Predicate, Predicate)
    }

    public func objects<T: Codable>(
        ofType type: T.Type,
        matching predicate: Predicate,
        orderBy: String? = nil,
        limit: Int32? = nil
    ) async throws -> [T] {
        let typeName = "\(type)"
        var sql = "SELECT value FROM \(typeName)"
        
        let (whereClause, parameters) = convertPredicateToSQL(predicate)
        if !whereClause.isEmpty {
            sql += " WHERE " + whereClause
        }
        
        if let orderBy = orderBy {
            sql += " ORDER BY " + replaceJsonValuesWithFunction(orderBy)
        }
        
        if let limit = limit {
            sql += " LIMIT \(limit)"
        }
        
        let statement = try prepareStatement(sql: sql, parameters: parameters)
        let dataArray = try query(statement: statement)
        
        return try dataArray.map { try JSONDecoder().decode(type, from: $0) }
    }
    
    private func convertPredicateToSQL(
        _ predicate: Predicate
    ) -> (String, [Any]) {
        var whereClause = ""
        var parameters: [Any] = []
        
        switch predicate {
            case let .property(key, value):
                whereClause = "json_extract(value, '$.\(key)') = ?"
                parameters.append(value)
            case let .and(left, right):
                let (leftClause, leftParameters) = convertPredicateToSQL(left)
                let (rightClause, rightParameters) = convertPredicateToSQL(right)
                whereClause = "(\(leftClause)) AND (\(rightClause))"
                parameters = leftParameters + rightParameters
            case let .or(left, right):
                let (leftClause, leftParameters) = convertPredicateToSQL(left)
                let (rightClause, rightParameters) = convertPredicateToSQL(right)
                whereClause = "(\(leftClause)) OR (\(rightClause))"
                parameters = leftParameters + rightParameters
        }
        
        return (whereClause, parameters)
    }
}

extension Kasa {
    private func createTableIfNeeded(withName name: String) async throws {
        let sql = """
            CREATE TABLE IF NOT EXISTS \(name)(
              uuid TEXT PRIMARY KEY NOT NULL,
              value BLOB
            );
        """
        try await execute(sql: sql)
        try await createIndex(named: "\(name)Index", on: name, expression: "uuid")
    }
    
    func createIndex(
        named indexName: String,
        on tableName: String,
        expression: String
    ) async throws {
        let sanitizedExpression = replaceJsonValuesWithFunction(expression)
        
        try await execute(sql: "CREATE UNIQUE INDEX IF NOT EXISTS \(indexName) ON \(tableName)(\(sanitizedExpression));")
    }
}

// MARK: - Public API
extension Kasa {
    public func save<T: Storable>(
        _ object: T
    ) async throws {
        let typeName = "\(T.self)"
        do {
            let value = try JSONEncoder().encode(object)
            let sql = "INSERT or REPLACE INTO \(typeName) (uuid, value) VALUES (?, ?);"
            let statement = try prepareStatement(sql: sql, parameters: [object.id, value])
            try await execute(statement: statement)
        } catch let error {
            guard error.localizedDescription.contains("no such table") else { throw error }
            try await createTableIfNeeded(withName: typeName)
            return try await save(object)
        }
    }
    
    public func object<T: Codable>(
        ofType type: T.Type,
        withId id: String
    ) async throws -> T? {
        let typeName = "\(type)"
        let sql = "SELECT value FROM \(typeName) WHERE uuid = ?;"
        let statement = try prepareStatement(sql: sql, parameters: [id])
        let dataArray = try query(statement: statement)
        
        guard let data = dataArray.first else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    public func objects<T: Codable>(
        ofType type: T.Type,
        matching filter: String? = nil,
        parameters: [Any] = [],
        orderBy: String? = nil,
        limit: Int32? = nil
    ) async throws -> [T] {
        let typeName = "\(type)"
        var sql = "SELECT value FROM \(typeName)"
        
        if let filter = filter {
            sql += " WHERE " + replaceJsonValuesWithFunction(filter)
        }
        
        if let orderBy = orderBy {
            sql += " ORDER BY " + replaceJsonValuesWithFunction(orderBy)
        }
        
        if let limit = limit {
            sql += " LIMIT \(limit)"
        }
        
        let statement = try prepareStatement(sql: sql, parameters: parameters)
        let dataArray = try query(statement: statement)
        
        return try dataArray.map { try JSONDecoder().decode(type, from: $0) }
    }
    
    public func remove<T: Codable>(
        objectOfType type: T.Type,
        withId id: String
    ) async throws {
        let typeName = "\(type)"
        let sql = "DELETE FROM \(typeName) WHERE uuid = ?;"
        let statement = try prepareStatement(sql: sql, parameters: [id])
        try await execute(statement: statement)
    }
    
    public func removeAll<T: Codable>(
        ofType type: T.Type
    ) async throws {
        let typeName = "\(type)"
        try await execute(sql: "DELETE FROM \(typeName)")
    }
}

extension Kasa {
    public func beginTransaction() async throws {
        try await execute(sql: "BEGIN EXCLUSIVE TRANSACTION;")
    }
    
    public func commitTransaction() async throws {
        try await execute(sql: "COMMIT TRANSACTION;")
    }
    
    public func rollbackTransaction() async throws {
        try await execute(sql: "ROLLBACK TRANSACTION;")
    }
}

// MARK: - Utilities
extension Kasa {
    private func prepareStatement(sql: String, parameters: [Any]) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw lastError()
        }
        
        try bindParameters(statement: statement, parameters: parameters)
        
        return statement
    }
    
    private func bindParameters(statement: OpaquePointer?, parameters: [Any]) throws {
        var index: Int32 = 1
        for parameter in parameters {
            switch parameter {
                case let stringParameter as String:
                    if sqlite3_bind_text(statement, index, stringParameter, -1, sqliteTransient) != SQLITE_OK {
                        throw lastError()
                    }
                case let intParameter as Int32:
                    if sqlite3_bind_int(statement, index, intParameter) != SQLITE_OK {
                        throw lastError()
                    }
                case let dataParameter as Data:
                    try dataParameter.withUnsafeBytes { pointer in
                        if sqlite3_bind_blob(statement, index, pointer.baseAddress, Int32(pointer.count), sqliteTransient) != SQLITE_OK {
                            throw lastError()
                        }
                    }
                default:
                    throw NSError(domain: "Unsupported parameter type: Support more types if prepareStatement func becomes public", code: -1, userInfo: nil)
            }
            
            index += 1
        }
    }
    
    private func execute(sql: String) async throws {
        guard sqlite3_exec(database, sql.cString(using: .utf8), nil, nil, nil) == SQLITE_OK else {
            throw lastError()
        }
    }
    
    private func execute(statement: OpaquePointer?) async throws {
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw lastError()
        }
    }
    
    private func query(statement: OpaquePointer?) throws -> [Data] {
        defer { sqlite3_finalize(statement) }
        
        var dataArray = [Data]()
        while sqlite3_step(statement) == SQLITE_ROW {
            let data = try getData(from: statement, at: 0)
            dataArray.append(data)
        }
        
        return dataArray
    }
    
    private func getString(from statement: OpaquePointer?, at index: Int32) throws -> String {
        guard let cString = sqlite3_column_text(statement, index) else {
            throw lastError()
        }
        return String(cString: cString)
    }
    
    private func getData(from statement: OpaquePointer?, at index: Int32) throws -> Data {
        guard let blob = sqlite3_column_blob(statement, index) else {
            throw lastError()
        }
        let bytes = sqlite3_column_bytes(statement, index)
        return Data(bytes: blob, count: Int(bytes))
    }
    
    private func replaceJsonValuesWithFunction(_ filter: String) -> String {
        return filter.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: " ")
            .map { word in
                if word.hasPrefix("$") {
                    return "json_extract(value, '$.\(word.dropFirst())')"
                } else {
                    return word
                }
            }
            .joined(separator: " ")
    }
}

extension Kasa {
    public static func databasePath(for name: String) -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return "\(path)/\(name).sqlite"
    }
    
    public func lastError() -> NSError {
        if let errorPointer = sqlite3_errmsg(database) {
            return NSError(domain: String(cString: errorPointer), code: -1, userInfo: nil)
        } else {
            return NSError(domain: "No error message provided from SQLite.", code: -1, userInfo: nil)
        }
    }
}

extension Kasa {
    public func runMigration<T: Codable>(
        forType type: T.Type,
        migration: ([String: Any]) -> [String: Any]
    ) async throws {
        let typeName = "\(type)"
        let sql = "SELECT uuid, value FROM \(typeName)"
        
        let statement = try prepareStatement(sql: sql, parameters: [])
        defer {
            sqlite3_finalize(
                statement
            )
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let uuid = try getString(from: statement, at: 0)
            let data = try getData(from: statement, at: 1)
            
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
            let migratedJsonObject = migration(jsonObject)
            
            let migratedData = try JSONSerialization.data(withJSONObject: migratedJsonObject, options: .fragmentsAllowed)
            let updateSql = "UPDATE \(typeName) SET value = ? WHERE uuid = ?;"
            let updateStatement = try prepareStatement(sql: updateSql, parameters: [migratedData, uuid])
            try await execute(statement: updateStatement)
        }
    }
}
