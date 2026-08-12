//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import JSONSchema
import Runtime
import Swallow
import Testing

@Suite
struct JSONSchemaTests {
    struct BookRestaurantIntentParameters: Codable, Hashable, Initiable, Sendable {
        @JSONSchemaDescription("The name of the restaurant")
        var restaurant_name: String?

        @JSONSchemaDescription(
            "The date of the restaurant booking in yyyy-MM-dd format. Should be a date with a year, month, day. NOTHING ELSE"
        )
        var reservation_date: String?

        @JSONSchemaDescription(
            "The time of the reservation in HH:mm format. Should include hours and minutes. NOTHING ELSE"
        )
        var reservation_time: String?

        var number_of_guests: Int?

        init() {

        }
    }

    @Test
    func reflectionProducesExpectedObjectSchema() throws {
        let schema: JSONSchema = try JSONSchema(
            reflecting: BookRestaurantIntentParameters.self,
            description: "Information required to make a restaurant booking",
            propertyDescriptions: [
                "number_of_guests": "The total number of people the reservation is for"
            ],
            required: false
        )

        #expect(schema.type == .object)
        #expect(schema.required == nil)
        #expect(schema.properties?.keys.sorted() == [
            "number_of_guests",
            "reservation_date",
            "reservation_time",
            "restaurant_name",
        ])
        #expect(schema.properties?["restaurant_name"]?.type == .string)
        #expect(
            schema.properties?["restaurant_name"]?.description
                == "The name of the restaurant"
        )
        #expect(schema.properties?["number_of_guests"]?.type == .integer)
        #expect(
            schema.properties?["number_of_guests"]?.description
                == "The total number of people the reservation is for"
        )
    }

    @Test
    func draft202012RepresentationRoundTripsWithoutLosingVocabulary() throws {
        let data = Data(
            """
            {
              "$schema": "https://json-schema.org/draft/2020-12/schema",
              "$id": "https://example.com/catalog.schema.json",
              "$ref": "#/$defs/Catalog",
              "$defs": {
                "Catalog": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": ["kind", "items"],
                  "properties": {
                    "kind": {"const": "catalog"},
                    "items": {
                      "type": "array",
                      "minItems": 1,
                      "maxItems": 4,
                      "uniqueItems": true,
                      "items": {
                        "oneOf": [
                          {"type": "string", "minLength": 1, "pattern": "^[a-z]+$"},
                          {"type": ["integer", "null"]}
                        ]
                      }
                    }
                  },
                  "allOf": [
                    {
                      "if": {"properties": {"kind": {"const": "catalog"}}},
                      "then": {"minProperties": 2},
                      "else": {"not": {"required": ["kind"]}}
                    }
                  ]
                }
              }
            }
            """.utf8
        )

        let schema = try JSONDecoder().decode(JSONSchema.self, from: data)
        let original = try JSONSerialization.jsonObject(with: data) as? NSDictionary
        let reencoded =
            try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(schema)
            ) as? NSDictionary
        #expect(original == reencoded)
    }

    @Test
    func booleanSchemasAndAdditionalPropertiesFalseRoundTrip() throws {
        for schema in [JSONSchema.any, JSONSchema.never] {
            let data = try JSONEncoder().encode(schema)
            #expect(try JSONDecoder().decode(JSONSchema.self, from: data) == schema)
        }

        let schema = try JSONDecoder().decode(
            JSONSchema.self,
            from: Data(#"{"type":"object","additionalProperties":false}"#.utf8)
        )
        #expect(schema.additionalProperties == false)
    }

    @Test
    func draft202012ValidationResolvesDefinitionsAndConditions() throws {
        let schemaData = Data(
            """
            {
              "$schema": "https://json-schema.org/draft/2020-12/schema",
              "$ref": "#/$defs/Item",
              "$defs": {
                "Item": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": ["kind", "values"],
                  "properties": {
                    "kind": {"enum": ["named", "anonymous"]},
                    "name": {"type": "string", "minLength": 1},
                    "values": {
                      "type": "array",
                      "minItems": 1,
                      "uniqueItems": true,
                      "items": {"type": "integer", "minimum": 0}
                    }
                  },
                  "if": {"properties": {"kind": {"const": "named"}}},
                  "then": {"required": ["name"], "properties": {"name": {}}}
                }
              }
            }
            """.utf8
        )
        let schema = try JSONDecoder().decode(JSONSchema.self, from: schemaData)

        try schema.validate(
            JSON(jsonObject: [
                "kind": "named",
                "name": "example",
                "values": [0, 1],
            ]))
        #expect(throws: JSONSchema.ValidationError.self) {
            try schema.validate(
                JSON(jsonObject: [
                    "kind": "named",
                    "values": [0, 1],
                ]))
        }
        #expect(throws: JSONSchema.ValidationError.self) {
            try schema.validate(
                JSON(jsonObject: [
                    "kind": "anonymous",
                    "values": [1, 1],
                ]))
        }
        #expect(throws: JSONSchema.ValidationError.self) {
            try schema.validate(
                JSON(jsonObject: [
                    "kind": "anonymous",
                    "values": [1],
                    "unknown": true,
                ]))
        }
    }
}
