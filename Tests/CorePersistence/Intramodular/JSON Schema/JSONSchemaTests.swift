//
// Copyright (c) Vatsal Manot
//

import _JSONSchema
import CorePersistence
import Diagnostics
import Runtime
import Swallow
import XCTest


extension Decodable {
    public typealias JSONSchemaDescription<T: Codable & Hashable & Sendable> = _JSONSchemaDescriptionAnnotation<T>
}

final class JSONSchemaTests: XCTestCase {
    static let bookRestaurantParametersJSONSchema = JSONSchema(
        type: .object,
        description: "Information required to make a restaurant booking",
        properties: [
            "restaurant_name": JSONSchema(
                type: .string,
                description: "The name of the restaurant",
                required: false
            ),
            "reservation_date" : JSONSchema(
                type: .string,
                description: "The date of the restaurant booking in yyyy-MM-dd format. Should be a date with a year, month, day. NOTHING ELSE",
                required: false
            ),
            "reservation_time" : JSONSchema(
                type: .string,
                description: "The time of the reservation in HH:mm format. Should include hours and minutes. NOTHING ELSE",
                required: false
            ),
            "number_of_guests" : JSONSchema(
                type: .integer,
                description: "The total number of people the reservation is for",
                required: false
            ),
        ],
        required: false
    )
    
    struct BookRestaurantIntentParameters: Codable, Hashable, Initiable, Sendable {
        var restaurant_name: String?
        var reservation_date: String?
        var reservation_time: String?
        var number_of_guests: Int?
        
        init() {
            
        }
    }
    
    func test() throws {
        let schema: JSONSchema = try JSONSchema(
            reflecting: BookRestaurantIntentParameters.self,
            description: "Information required to make a restaurant booking",
            propertyDescriptions: [
                "restaurant_name": "The name of the restaurant",
                "reservation_date": "The date of the restaurant booking in yyyy-MM-dd format. Should be a date with a year, month, day. NOTHING ELSE",
                "reservation_time": "The time of the reservation in HH:mm format. Should include hours and minutes. NOTHING ELSE",
                "number_of_guests": "The total number of people the reservation is for",
            ],
            required: false
        )
        
        XCTAssertEqual(schema, Self.bookRestaurantParametersJSONSchema)
        
        print(schema)
    }
}

