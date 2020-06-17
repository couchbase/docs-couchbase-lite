// tag::listener[]

/// A listener to provide websocket based endpoint for peer-to-peer replication.
/// Once the listener is started, peer replicators can connect to the listener by using URLEndpoint
@available(OSX 10.12, iOS 10.0, *)

public class URLEndpointListener {

    /// Current connection status of the listener.
    public struct ConnectionStatus {

        /// The current number of the connections served by the listener.
        public let connectionCount: UInt64

        /// The current number of the active connections(BUSY) served by the listener.
        public let activeConnectionCount: UInt64
    }

// tag::config[]
    /// The read-only configuration.
    public var config: CouchbaseLiteSwift.URLEndpointListenerConfiguration { get }

    /// The listening port of the listener. If the listener is not started, the port will be `nil`
    public var port: UInt16? { get }

    /// The URLs of the listener.  If the network interface is specified, return only single URL that reflects the network interface address
    /// else gather all possible URLs. If the listener is not started, will return `nil`
    public var urls: [URL]? { get }

    /// The connection status of the listener
    public var status: CouchbaseLiteSwift.URLEndpointListener.ConnectionStatus { get }

// end::config[]

// tag::init-listener[]
    /// Initializes a listener with the given configuration object.
    public init(config: CouchbaseLiteSwift.URLEndpointListenerConfiguration)
// end::init-listener[]

// tag::start-listener[]
    /// Starts the listener.
    public func start() throws
// end::start-listener[]

// tag::stop-listener[]
    /// Stop the listener.
    public func stop()
// end::stop-listener[]

}
// end::listener[]





// tag::listener-config[]

/// The configuration used for configuring and creating a URLEndpointListener.
@available(OSX 10.12, iOS 10.0, *)
public class URLEndpointListenerConfiguration {

    /// The database object associated with the listener.
    public let database: CouchbaseLiteSwift.Database

    /// The port that the listener will listen to. If default value is zero which means that the listener will automatically
    /// select an available port to listen to when the listener is started.
    public var port: UInt16?

    /// The network interface in the form of the IP Address or network interface name such as en0 that the listener will listen to.
    /// The default value is nil which means that the listener will listen to all network interfaces.
    public var networkInterface: String?

    /// Disable TLS communication. The default value is NO which means that the TLS will be enabled by default.
    public var disableTLS: Bool

    /// The TLS Identity used for configuring TLS Communication. The default value is nil which means that
    /// a generated anonymous self-signed identity will be used unless the disableTLS property is set to YES.
    public var tlsIdentity: CouchbaseLiteSwift.TLSIdentity?

    /// The authenticator used by the listener to authenticate clients.
    public var authenticator: CouchbaseLiteSwift.ListenerAuthenticator?

    /// Allow delta sync when replicating with the listener. The default value is NO.
    public var enableDeltaSync: Bool

    /// Allow only pull replication to pull changes from the listener. The default value is NO.
    public var readOnly: Bool

    /// Initializes a ListenerConfiguration's builder with the given database
    ///
    /// - Parameters:
    ///   - database: The local database.
    public init(database: CouchbaseLiteSwift.Database)

    /// Initializes a ListenerConfiguration's builder with the given
    /// configuration object.
    ///
    /// - Parameter config: The configuration object.
    public convenience init(config: CouchbaseLiteSwift.URLEndpointListenerConfiguration)
}

// end::listener-config[]


// tag::passive-p2pWebsocketsListener[]

// MARK: Peer-to-peer Passive Listener for user db
extension DatabaseManager {
// tag::initWebsocketsListener[]
    func initWebsocketsListenerForUserDb()throws {
        guard let db = _userDb else {
            throw ListDocError.DatabaseNotInitialized
        }

        if _websocketListener != nil  {
            print("Listener already initialized")
            return
        }

        // Include websockets listener initializer code
        let listenerConfig = URLEndpointListenerConfiguration(database: db)
        listenerConfig.disableTLS  = true // Use with anonymous self signed cert
        listenerConfig.enableDeltaSync = true
        listenerConfig.tlsIdentity = nil

        listenerConfig.authenticator = ListenerPasswordAuthenticator.init {
                   (username, password) -> Bool in
            if (self._whitelistedUsers.contains(["password" : password, "name":username])) {
                return true
            }
            return false
               }

        _websocketListener = URLEndpointListener(config: listenerConfig)

    }
// end::initWebsocketsListener[]

// tag::startWebsocketsListener[]

    // TODO: MAKE ASYNC ON BACKGROUND QUEUE AND USE CALLBACK ON MAIN THREAD
    func startWebsocketsListenerForUserDb(handler:@escaping(_ urls:[URL]?, _ error:Error?)->Void) throws{
        print(#function)
        guard let websocketListener = _websocketListener else {
            throw ListDocError.WebsocketsListenerNotInitialized
            }
        DispatchQueue.global().sync {
            do {
                try websocketListener.start()
                handler(websocketListener.urls,nil)
            }
            catch {
                handler(nil,error)
            }

        }

    }
// end::startWebsocketsListener[]

// tag::stopWebsocketsListener[]
    func stopWebsocketsListenerForUserDb() throws{
        print(#function)
        guard let websocketListener = _websocketListener else {
            throw ListDocError.WebsocketsListenerNotInitialized
        }
        websocketListener.stop()

    }
// end::stopWebsocketsListener[]

}
// end::passive-p2pWebsocketsListener[]

// tag::p2p-ws-api-urlendpointlistener[]
public class URLEndpointListener {
    // Properties // <1>
    public let config: URLEndpointListenerConfiguration
    public let port UInt16?
    public let tlsIdentity: TLSIdentity?
    public let urls: Array<URL>?
    public let status: ConnectionStatus?
    // Constructors <2>
    public init(config: URLEndpointListenerConfiguration)
    // Methods <3>
    public func start() throws
    public func stop()
}
// end::p2p-ws-api-urlendpointlistener[]


// tag::p2p-ws-api-urlendpointlistener-constructor[]
let config = URLEndpointListenerConfiguration.init(database: self.oDB)
config.port = tls ? wssPort : wsPort
config.disableTLS = !tls
config.authenticator = auth
self.listener = URLEndpointListener.init(config: config) // <1>
// end::p2p-ws-api-urlendpointlistener-constructor[]


