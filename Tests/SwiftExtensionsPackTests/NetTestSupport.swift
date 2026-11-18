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
    private let replyOnCancel: NetTestReply?
    private let onCreate: (@Sendable () -> Void)?
    private let onResume: (@Sendable () -> Void)?

    init(
        reply: NetTestReply? = nil,
        replyOnCancel: NetTestReply? = nil,
        onCreate: (@Sendable () -> Void)? = nil,
        onResume: (@Sendable () -> Void)? = nil
    ) {
        self.reply = reply
        self.replyOnCancel = replyOnCancel
        self.onCreate = onCreate
        self.onResume = onResume
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
        let replyOnCancel = replyOnCancel
        let onResume = onResume
        let task = NetTestDataTask(
            onResume: {
                onResume?()
                if let reply {
                    completionHandler(reply.data, reply.response, reply.error)
                }
            },
            onCancel: {
                if let replyOnCancel {
                    completionHandler(replyOnCancel.data, replyOnCancel.response, replyOnCancel.error)
                }
            },
            completionHandler: { reply in
                completionHandler(reply.data, reply.response, reply.error)
            }
        )
        calls.change { $0.append(Call(request: request, task: task)) }
        onCreate?()
        return task
    }

    override func invalidateAndCancel() {}
}

final class NetTestDataTask: URLSessionDataTask, @unchecked Sendable {
    let resumeCount = SafeValue(0)
    let cancelCount = SafeValue(0)
    private let onResume: @Sendable () -> Void
    private let onCancel: @Sendable () -> Void
    private let completionHandler: @Sendable (NetTestReply) -> Void

    init(
        onResume: @escaping @Sendable () -> Void,
        onCancel: @escaping @Sendable () -> Void,
        completionHandler: @escaping @Sendable (NetTestReply) -> Void
    ) {
        self.onResume = onResume
        self.onCancel = onCancel
        self.completionHandler = completionHandler
        // This detached task only invokes callbacks controlled by the test.
        super.init()
    }

    override func resume() {
        let firstResume = resumeCount.change {
            $0 += 1
            return $0 == 1
        }
        if firstResume && cancelCount.value == 0 {
            onResume()
        }
    }

    override func cancel() {
        let firstCancel = cancelCount.change {
            $0 += 1
            return $0 == 1
        }
        if firstCancel {
            onCancel()
        }
    }

    func complete(with reply: NetTestReply) {
        completionHandler(reply)
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
