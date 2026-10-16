import Foundation

public struct CodeSigningIdentity: Identifiable, Hashable {
    public var id: String { hash }
    public var hash: String
    public var name: String
    public var isDeveloperID: Bool
    
    public init(hash: String, name: String) {
        self.hash = hash
        self.name = name
        self.isDeveloperID = name.contains("Developer ID Application")
    }
}

public class KeychainIdentityService {
    public static let shared = KeychainIdentityService()
    
    public init() {}
    
    /// Queries macOS Keychain for code signing identities using `/usr/bin/security`
    public func fetchIdentities() -> [CodeSigningIdentity] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-identity", "-v", "-p", "codesigning"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            var identities: [CodeSigningIdentity] = []
            
            // Format example:
            //   1) 1234567890ABCDEF1234567890ABCDEF12345678 "Developer ID Application: My Company (TEAMID)"
            let lines = output.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.contains(")") && trimmed.contains("\"") else { continue }
                
                let parts = trimmed.components(separatedBy: "\"")
                guard parts.count >= 2 else { continue }
                
                let name = parts[1]
                let prefixParts = parts[0].components(separatedBy: " ")
                guard let hashCandidate = prefixParts.last(where: { $0.count == 40 }) else {
                    identities.append(CodeSigningIdentity(hash: name, name: name))
                    continue
                }
                
                identities.append(CodeSigningIdentity(hash: hashCandidate, name: name))
            }
            
            // Sort Developer ID Application to top
            return identities.sorted {
                if $0.isDeveloperID && !$1.isDeveloperID { return true }
                if !$0.isDeveloperID && $1.isDeveloperID { return false }
                return $0.name < $1.name
            }
        } catch {
            return []
        }
    }
}
