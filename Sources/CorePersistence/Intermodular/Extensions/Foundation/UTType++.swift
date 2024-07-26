//
// Copyright (c) Vatsal Manot
//

#if canImport(CoreServices)
import CoreServices
#endif
import FoundationX
import UniformTypeIdentifiers

extension UTType {
    public static let webInternetLocation = UTType("com.apple.web-internet-location")!
}

extension UTType {
    public init?(from url: URL) {
        if FileManager.default.fileExists(at: url), let type = try? url.resourceValues(forKeys: [.typeIdentifierKey]).contentType {
            self = type
        } else if let type = UTType(filenameExtension: url.pathExtension) {
            self = type
        } else {
            return nil
        }
    }
}

#if canImport(CoreServices) && os(macOS)
public func LSRegisterURL(_ url: URL) throws {
    enum BundleRegistrationError: Error {
        case failedToRegister
    }
    
    let status = CoreServices.LSRegisterURL(url as CFURL, true)
    
    guard status == noErr else {
        throw BundleRegistrationError.failedToRegister
    }
}

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension UTType {
    private enum SetDefaultRoleHandlerError: Error {
        case failedToSetDefaultHandler
    }
    
    public func setDefaultHandler(
        _ handler: Bundle.ID,
        forRole role: LSRolesMask
    ) throws {
        let status = LSSetDefaultRoleHandlerForContentType(
            self.identifier as CFString,
            role,
            handler.rawValue as CFString
        )
        
        guard status == noErr else {
            throw SetDefaultRoleHandlerError.failedToSetDefaultHandler
        }
    }
}
#endif
