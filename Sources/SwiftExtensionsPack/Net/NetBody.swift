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
