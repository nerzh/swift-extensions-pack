import Foundation

public enum NetBody {
    case raw(data: Data, contentType: String)
    case json(any Encodable)
    case form([String: String])
    case multipart([NetMultipartPart])

    public static func raw(_ string: String, contentType: String) -> NetBody {
        .raw(data: Data(string.utf8), contentType: contentType)
    }
}

public enum NetMultipartPart {
    case field(name: String, value: String)
    case file(name: String, file: any NetSessionFilePrtcl)
}

extension NetBody {
    func encoded() throws -> (data: Data, contentType: String) {
        switch self {
        case let .raw(data, contentType):
            return (data, contentType)
        case let .json(value):
            return (try JSONEncoder().encode(value), "application/json")
        case let .form(fields):
            let allowedCharacters = CharacterSet(
                charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789*-._"
            )
            let components = try fields.sorted { $0.key < $1.key }.map { name, value in
                guard
                    let encodedName = name.addingPercentEncoding(withAllowedCharacters: allowedCharacters),
                    let encodedValue = value.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
                else {
                    throw Net.NetErrors.NotValidParams
                }
                return "\(encodedName)=\(encodedValue)".replacingOccurrences(of: "%20", with: "+")
            }
            return (Data(components.joined(separator: "&").utf8), "application/x-www-form-urlencoded")
        case let .multipart(parts):
            let multipart = NetMultipartData()
            for part in parts {
                switch part {
                case let .field(name, value):
                    multipart.append(name, value)
                case let .file(name, file):
                    multipart.appendFile(name, file.data, file.fileName, mimeType: file.mimeType)
                }
            }
            return (
                multipart.finalizeBodyAndGetData() as Data,
                "multipart/form-data; boundary=\(multipart.boundary)"
            )
        }
    }
}
