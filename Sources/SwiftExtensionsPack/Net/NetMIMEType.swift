public enum NetMIMEType: Hashable, Sendable {
    case octetStream
    case json
    case problemJSON
    case jsonLD
    case xml
    case yaml
    case cbor
    case formURLEncoded
    case multipartFormData

    case plainText
    case html
    case css
    case javaScript
    case csv
    case markdown

    case pdf
    case zip
    case gzip
    case zstd
    case wasm

    case jpeg
    case png
    case apng
    case gif
    case webp
    case avif
    case heic
    case heif
    case svg
    case tiff
    case bmp
    case ico

    case mp3
    case m4a
    case oggAudio
    case flac
    case mp4
    case mpeg
    case quickTime
    case oggVideo

    case woff
    case woff2
    case ttf
    case otf

    case doc
    case docx
    case xls
    case xlsx
    case ppt
    case pptx

    case custom(String)

    public var rawValue: String {
        switch self {
        case .octetStream: return "application/octet-stream"
        case .json: return "application/json"
        case .problemJSON: return "application/problem+json"
        case .jsonLD: return "application/ld+json"
        case .xml: return "application/xml"
        case .yaml: return "application/yaml"
        case .cbor: return "application/cbor"
        case .formURLEncoded: return "application/x-www-form-urlencoded"
        case .multipartFormData: return "multipart/form-data"
        case .plainText: return "text/plain"
        case .html: return "text/html"
        case .css: return "text/css"
        case .javaScript: return "text/javascript"
        case .csv: return "text/csv"
        case .markdown: return "text/markdown"
        case .pdf: return "application/pdf"
        case .zip: return "application/zip"
        case .gzip: return "application/gzip"
        case .zstd: return "application/zstd"
        case .wasm: return "application/wasm"
        case .jpeg: return "image/jpeg"
        case .png: return "image/png"
        case .apng: return "image/apng"
        case .gif: return "image/gif"
        case .webp: return "image/webp"
        case .avif: return "image/avif"
        case .heic: return "image/heic"
        case .heif: return "image/heif"
        case .svg: return "image/svg+xml"
        case .tiff: return "image/tiff"
        case .bmp: return "image/bmp"
        case .ico: return "image/vnd.microsoft.icon"
        case .mp3: return "audio/mpeg"
        case .m4a: return "audio/mp4"
        case .oggAudio: return "audio/ogg"
        case .flac: return "audio/flac"
        case .mp4: return "video/mp4"
        case .mpeg: return "video/mpeg"
        case .quickTime: return "video/quicktime"
        case .oggVideo: return "video/ogg"
        case .woff: return "font/woff"
        case .woff2: return "font/woff2"
        case .ttf: return "font/ttf"
        case .otf: return "font/otf"
        case .doc: return "application/msword"
        case .docx: return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case .xls: return "application/vnd.ms-excel"
        case .xlsx: return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case .ppt: return "application/vnd.ms-powerpoint"
        case .pptx: return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case let .custom(value): return value
        }
    }
}
