//
//  String.swift
//  swift-extensions-pack
//
//  Created by Oleh Hudeichuk on 2/6/19.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol NetSessionFilePrtcl {

    var data: Data { get set }
    var fileName: String { get set }
}

// MARK: Session File
public struct NetSessionFile: NetSessionFilePrtcl {
    
    public var data: Data
    public var fileName: String

    public init(data: Data, fileName: String) {
        self.data = data
        self.fileName = fileName
    }
}

// MARK: Extension NSMutableData
extension NSMutableData {
    
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}

// MARK: Multipart
public class NetMultipartData {
    public var body                   : NSMutableData = NSMutableData()
    private var _boundary      : String        = ""
    private var boundaryPrefix : String        = ""
    private var finishBoundary : String        = ""
    public var boundary : String {
        set {
            _boundary      = newValue
            boundaryPrefix = "--\(newValue)\r\n"
            finishBoundary = "--\(self.boundary)--"
        }
        get { return _boundary }
    }
    
    public init() {
        boundary = "Boundary-\(UUID().uuidString)"
    }
    
    public init(boundary: String) {
        self.boundary = boundary
    }
    
    public func append(_ name: String, _ value: Any) {
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        body.appendString("\(value)\r\n")
    }
    
    public func appendFile(_ name: String, _ data: Data, _ fileName: String) {
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        body.append(data)
        body.appendString("\r\n")
    }
    
    public func appendFile(_ name: String, _ data: Data, _ fileName: String, mimeType: String) {
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
    }
    
    public func finalizeBodyAndGetData() -> NSMutableData {
        finalizeBody()
        return body
    }
    
    private func finalizeBody() {
        body.appendString(finishBoundary)
    }

    public func toRailsMultipartData(_ anyObject: Any) -> NSMutableData {

        func checkValue(_ parentName: String, _ anyObject: Any) {
            if let array = anyObject as? Array<Any> {
                for (index, element) in array.enumerated() {
                    let newNodeName = "\(parentName)[\(index)]"
                    checkValue(newNodeName, element)
                }
            } else if let dictionary = anyObject as? Dictionary<String, Any> {
                for key in dictionary.keys {
                    let newNodeName = parentName.count == 0 ? "\(key)" : "\(parentName)[\(key)]"
                    checkValue(newNodeName, dictionary[key]!)
                }
            } else {
                if let file = anyObject as? NetSessionFilePrtcl {
                    appendFile(parentName, file.data, file.fileName)
                } else {
                    append(parentName, anyObject)
                }
            }
        }

        checkValue("", anyObject as AnyObject)
        return finalizeBodyAndGetData()
    }
}

// MARK: Extension Dictionary to Multipart (Recursive)
extension Dictionary {
    
    func toRailsMultipartData() -> NSMutableData {
        return NetMultipartData().toRailsMultipartData(self)
    }
    
    //    MARK: Ruby On Rails
    func toRailsQueryParams() -> String {
        return Net.toRailsQueryParams(self)
    }
}



//  MARK: Net
public class Net {
    private static let sessionConfiguration : URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        //        config.timeoutIntervalForRequest  = 1000
        //        config.timeoutIntervalForResource = 0
        return config
    }()
    
    public static var sharedSession = URLSession(configuration: sessionConfiguration)
    
    public enum NetErrors : Error {
        case NotValidParams
        case SomeError
        case BadData
    }
    
    
    public class func sendRequest(url: String,
                                  method: String,
                                  headers: [String:String]? = nil,
                                  params: [String:Any]? = nil,
                                  body: Data? = nil,
                                  multipart: Bool = false,
                                  session: URLSession = sharedSession,
                                  beforeResume: (() -> ())? = {},
                                  afterResume: (() -> ())? = {},
                                  _ handler: @escaping (Data?, URLResponse?, Error?) -> () = { _,_,_ in }) throws
    {
        let request = try makeRequest(url: url, method: method, headers: headers, params: params, body: body, multipart: multipart)
        
        let dataTask = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            handler(data, response, error)
        })
        
        if let beforeResume = beforeResume { beforeResume() }
        dataTask.resume()
        if let afterResume = afterResume { afterResume() }
        // sharedSession.finishTasksAndInvalidate()
    }
    
    
    private class func makeRequest(url: String,
                            method: String,
                            headers: [String:String]?=nil,
                            params: [String:Any]?=nil,
                            body: Data?=nil,
                            multipart: Bool=false) throws -> URLRequest
    {
        let fullUrl = "\(url)\(makeQueryParamsString(params))"
        guard let requestUrl = URL(string: fullUrl) else { throw NetErrors.NotValidParams }
        var request                 = URLRequest(url: requestUrl)
        request.httpMethod          = method
        request.allHTTPHeaderFields = headers
        
        if method.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == "get" { return request }
        
        if multipart {
            request.httpBody = makeMultipartBody(&request, params)
        } else {
            request.httpBody = makeBody(params, body)
        }
        
        
        return request
    }
    
    
    private class func makeBody(_ params: [String:Any]?, _ body: Data?) -> Data? {
        var result : Data?
        
        if let body = body {
            result = body
        } else {
            result = paramsString(params).data(using: String.Encoding.utf8)
        }
        
        return result
    }
    
    private class func makeMultipartBody(_ request: inout URLRequest, _ params: [String:Any]?) -> Data? {
        let body = NetMultipartData()
        request.setValue("multipart/form-data; boundary=\(body.boundary)", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        return body.toRailsMultipartData(params ?? [:]) as Data
    }
    
    public class func makeQueryParamsString(_ params: [String:Any]?) -> String {
        guard let params = params else { return "" }
        var queryParamsString = params.count > 0 ? "?" : ""
        queryParamsString.append(paramsString(params))
        
        return queryParamsString
    }
    
    public class func paramsString(_ params: [String:Any]?) -> String {
        return toRailsQueryParams(params)
    }
    
    public class func urlEncode(_ string: String) -> String {
        var allowedCharacters = CharacterSet.alphanumerics
        allowedCharacters.insert(charactersIn: ".-_")
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
    }

    public class func toQueryParams(_ params: [String:Any]?) -> String {
        var paramsString          = ""
        var first                 = true
        let separator : Character = "&"
        guard let params = params else { return paramsString }

        for (key, value) in params {
            if first {
                first = false
                paramsString += "\(key)=\(urlEncode("\(value)"))"
            } else {
                paramsString += "\(separator)\(key)=\(urlEncode("\(value)"))"
            }
        }

        return paramsString
    }

    public class func toRailsQueryParams(_ anyObject: Any) -> String {
        func checkValue(_ parentName: String, _ anyObject: AnyObject, _ queryParams: inout String) {
            if let array = anyObject as? Array<AnyObject> {
                for (index, element) in array.enumerated() {
                    let newNodeName = "\(parentName)[\(index)]"
                    checkValue(newNodeName, element, &queryParams)
                }
            } else if let dictionary = anyObject as? Dictionary<String,AnyObject> {
                for key in dictionary.keys {
                    let newNodeName = parentName.count == 0 ? "\(key)" : "\(parentName)[\(key)]"
                    checkValue(newNodeName, dictionary[key]!, &queryParams)
                }
            } else {
                let value = urlEncode("\(anyObject)")
                let pair = queryParams.count == 0 ? "\(parentName)=\(value)" : "&\(parentName)=\(value)"
                queryParams.append(pair)
            }
        }

        var result = ""
        checkValue("", anyObject as AnyObject, &result)
        return result
    }
}

