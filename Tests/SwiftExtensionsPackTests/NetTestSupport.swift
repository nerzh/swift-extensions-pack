import Foundation
import SwiftExtensionsPack

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct NetTestReply: Sendable {
    let data: Data?
    let response: URLResponse?
    let error: (any Error)?

    init(data: Data? = nil, response: URLResponse? = nil, error: (any Error)? = nil) {
        self.data = data
        self.response = response
        self.error = error
    }
}

final class NetTestSession: URLSession, @unchecked Sendable {
    struct Call: Sendable {
        let request: URLRequest
        let task: NetTestDataTask
    }

    let calls = SafeValue<[Call]>([])
    private let reply: NetTestReply?

    init(reply: NetTestReply? = nil) {
        self.reply = reply
        #if canImport(FoundationNetworking)
        super.init(configuration: .ephemeral, delegate: nil, delegateQueue: nil)
        #else
        // Darwin's configuration initializers are factories, not subclass initializers.
        super.init()
        #endif
    }

    override func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDataTask {
        let reply = reply
        let task = NetTestDataTask {
            if let reply {
                completionHandler(reply.data, reply.response, reply.error)
            }
        }
        calls.change { $0.append(Call(request: request, task: task)) }
        return task
    }

    override func invalidateAndCancel() {}
}

final class NetTestDataTask: URLSessionDataTask, @unchecked Sendable {
    let resumeCount = SafeValue(0)
    private let onResume: @Sendable () -> Void

    init(onResume: @escaping @Sendable () -> Void) {
        self.onResume = onResume
        // This detached task only invokes the stub callback when resumed.
        super.init()
    }

    override func resume() {
        let firstResume = resumeCount.change {
            $0 += 1
            return $0 == 1
        }
        if firstResume {
            onResume()
        }
    }
}

enum NetTestError: Error, Equatable {
    case encodingFailed
    case handlerFailed
}

struct FailingNetPayload: Encodable {
    func encode(to encoder: any Encoder) throws {
        throw NetTestError.encodingFailed
    }
}

struct NetTestPayload: Codable, Equatable {
    let title: String
    let count: Int
    let enabled: Bool
}

struct CustomNetTestFile: NetSessionFilePrtcl {
    var data: Data
    var fileName: String
    var mimeType: NetMIMEType
}
