# CorePersistence

A protocol-oriented, batteries-included foundation for persistence in Swift. 

# Goals
This library has ambitious goals:
- Provide a protocol-oriented foundation for all the critical aspects of a typical, modern Swift application's persistence layer.
- Provide standard, high performance primitives for the most common data formats (`JSON`, `CSV`, `XML` etc.).
- Unf*** `Codable`.

# Features
- An opinionated, protocol-oriented encapsulated of persistent identifiers (both type identifiers and instance identifiers).
- A modular plugin system for `Codable` (achieved by custom encoders & decoders that can wrap existing ones, macros, and a suite of protocols).
- Better diagnostics for `Codable` errors (`EncodingError` and `DecodingError` are subpar).
- Essential data storage primitives (see `@FileStorage` and `@FolderStorage` – similar to SwiftUI's `@AppStorage` but for the application's persistence layer.)
- A high performance `JSON` primitive.
- A high performance `CSV` primitive.
- A high performance `XML` primitive (backed by the excellent `XMLCoder` library for now).

## JSONSchema
Broad description of the JSON schema. It is agnostic and independent of any programming language.
Based on: [https://json-schema.org/draft/2019-09/json-schema-core.html](https://json-schema.org/draft/2019-09/json-schema-core) it implements only concepts used in the `rum-events-format` schemas.

```swift
let restaurantBookingSchema = JSONSchema(
    type: .object,
    description: "Information required to make a restaurant booking",
    properties: [
        "name": JSONSchema(
            type: .string,
            description: "The name of the restaurant"
        ),
        "date" : JSONSchema(
            type: .string,
            description: "The date of the restaurant booking in yyyy-MM-dd format. Should be a date with a year, month, day."
        ),
        "time" : JSONSchema(
            type: .string,
            description: "The time of the reservation in HH:mm format. Should include hours and minutes."
        ),
        "number_of_people" : JSONSchema(
            type: .integer,
            description: "The total number of people the reservation is for"
        )
    ],
    // the required parameter specifies whether all properties listed are required or not
    // note that you can also pass in an array of strings specifying the properties that are required as follows:
    // required: ["name", "date", "time"] - "number_of_people" not required
    required: false 
)
```

You can also create a `JSONSchema` based on your object as follows:

```swift
struct RestaurantBooking: Codable, Hashable, Sendable {
    let name: String?
    let date: String?
    let time: String?
    let numberOfPeople: Int?
}

func createRestaurantBookingSchema() -> JSONSchema? {
    do {
        let restaurantBookingSchema: JSONSchema = try JSONSchema(
            type: RestaurantBooking.self,
            description: "Information required to make a restaurant booking",
            propertyDescriptions: [
                "name": "The name of the restaurant",
                "date": "The date of the restaurant booking in yyyy-MM-dd format. Should be a date with a year, month, day.",
                "time": "The time of the reservation in HH:mm format. Should include hours and minutes.",
                "number_of_people": "The total number of people the reservation is for"
            ],
            required: false
        )
        return restaurantBookingSchema
    } catch {
        print(error)
        return nil
    }
}
```

## @FileStorage
The `@FileStorage` property wrapper is a tool designed to simplify data persistence by automatically handling the reading and writing of data to files. Features include:
- **Automatic Data Handling**: `@FileStorage` automates the process of storing and retrieving data. Data is automatically written to a file whenever it changes, and read from the file when needed.
- **Configurable Storage Location**: You can specify where the data should be stored, such as in the application's documents directory (`.appDocuments`) or other specific locations (e.g.  `.desktop`, `.downloads`, `.musicDirectory`) that can be configured based on permissions and user settings. This flexibility ensures that data storage can be adapted to different application needs and environments.
- **Customizable Serialization**: It supports different data coders like JSON or property list, allowing for easy serialization and deserialization of complex data types. This is useful for storing custom objects, as long as they conform to the `Codable` protocol.
- **Error Handling Strategies**: `@FileStorage` offers customizable error handling strategies, such as discarding corrupted data and resetting to default values, or even halting the application on errors. This is critical for maintaining data integrity and application stability.

Using `@FileStorage` can be used as an alternative to `SwiftData` for simpler, smaller-scale applications because it offers a more straightforward and lightweight approach to data persistence. It seamlessly integrates with SwiftUI, providing an easy-to-use, declarative syntax that minimizes boilerplate code and automatically handles serialization of Codable objects. This eliminates the need for complex database setup, schema management, and migrations, making it ideal for applications that don't require the advanced features and overhead of a full-fledged database system. Additionally, `@FileStorage` allows for customizable error handling strategies, ensuring data integrity without the complexity of managing a relational database.

```swift
// Making DataStore an ObservableObject allows to receive notifications when values change
// In View: @StateObject var dataStore: DataStore = .shared
public final class DataStore: ObservableObject {
    
    @MainActor
    // the DataStore should be a singleton
    public static let shared = DataStore()
    
    @FileStorage(
        // directory of the app docuemnts set to .appDocuments means that the file will be stored in the app sandbox. User permissions dialog will not show up
        // if you use other options (e.g. .documents, .desktop, .downloads, .musicDirectory, etc), make sure to enable app permissions to access those folders. The user will have to grant permissions.
        .appDocuments,
        path: "path.json",
        coder: .json, // .propertyList is also supported
        // In case of read error, discard existing data (if any) and reset with the initial value.
        options: .init(readErrorRecoveryStrategy: .discardAndReset)
    )
    
    // the file will be auto-updated as objects are changed
    var objects: IdentifierIndexingArrayOf<MyIdentifiableObject> = []

    @MainActor
    private init() {
        if objects.isEmpty {
            objects = [.init(someText: "Hello World")]
        }
    }
}

// must conform to Identifiable, Hashable, and Codable
public struct MyIdentifiableObject: Identifiable, Hashable, Codable {
    public var id = UUID()
    public var someText: String?
    
    init(someText: String?) {
        self.someText = someText
    }
}
```

Other custom options for initializing @FileStorage:
```swift
// For Application Groups
@FileStorage(
    location: {
        return try! URL(
            directory: .securityApplicationGroup("group.com.yourgroupname.Shared")
        )
        .appending(path: "DirectoryPath", directoryHint: .isDirectory)
        .appending(path: "data.json")
    },
    coder: JSONCoder(), // TOMLCoder() also supported
    options: .init(readErrorRecoveryStrategy: .fatalError)
)

// Storing in Home Directory using URL
// This will require to updated settings to allow Read/Write access to the directory
@FileStorage(
    url: URL.homeDirectory.appending(path: "data.json"),
    coder: JSONCoder()
)

// Specifying Path & Filename
@FileStorage(
    directory: .appDocuments,
    path: "ProjectName",
    filename: UUID.self,
    coder: HadeanTopLevelCoder(coder: JSONCoder()),
    options: .init(readErrorRecoveryStrategy: .discardAndReset)
)
```

## @HadeanIdentifier
`@HadeanIdentifier` is a general purpose persistent identifier to identify distinct objects. 
Usage:
```swift
@HadeanIdentifier("guvol-haboz-motiz-povag")
struct MyObject {
// your object code here
}
```
It is recommended to use a [Proquint](https://github.com/dsw/proquint) - Identifiers that are not real words but are as Readable, Spellable, and Pronounceable as words. 

Python scrip to generate a proquint: 
```python
from proquint import uint2quint
import random

# Generate a unique string of 4 proquint words
unique_string = '-'.join(uint2quint(random.getrandbits(32)) for _ in range(4))
print(unique_string)
```

# License

CorePersistence is licensed under the [MIT License](https://vmanot.mit-license.org).

# Acknowledgments

<details>
<summary>XMLCoder</summary>

- **Link**: https://github.com/CoreOffice/XMLCoder
- **License**: [MIT License](https://github.com/CoreOffice/XMLCoder/blob/main/LICENSE)
- **Authors**: Shawn Moore and XMLCoder contributors

</details>
