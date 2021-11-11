//
//  ActivePeerConnection.swift
//  code-snippets
//
//  Created by Jayahari Vavachan on 11/10/21.
//  Copyright © 2021 couchbase. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity

/* ----------------------------------------------------------- */
/* ---------------------  ACTIVE SIDE  ----------------------- */
/* ---------------  stubs for documentation  ----------------- */
/* ----------------------------------------------------------- */
class ActivePeer: MessageEndpointDelegate {
    
    init() throws {
        let id = ""
        
        // tag::message-endpoint[]
        let database = try Database(name: "dbname")
        
        // The delegate must implement the `MessageEndpointDelegate` protocol.
        let messageEndpointTarget = MessageEndpoint(uid: "UID:123", target: id, protocolType: .messageStream, delegate: self)
        // end::message-endpoint[]
        
        // tag::message-endpoint-replicator[]
        let config = ReplicatorConfiguration(database: database, target: messageEndpointTarget)
        
        // Create the replicator object.
        let replicator = Replicator(config: config)
        // Start the replication.
        replicator.start()
        // end::message-endpoint-replicator[]
    }
    
    // tag::create-connection[]
    /* implementation of MessageEndpointDelegate */
    func createConnection(endpoint: MessageEndpoint) -> MessageEndpointConnection {
        let connection = ActivePeerConnection() /* implements MessageEndpointConnection */
        return connection
    }
    // end::create-connection[]
    
}

class ActivePeerConnection: MessageEndpointConnection {
    
    var replicatorConnection: ReplicatorConnection?
    
    init() {}
    
    func disconnect() {
        // tag::active-replicator-close[]
        replicatorConnection?.close(error: nil)
        // end::active-replicator-close[]
    }
    
    // tag::active-peer-open[]
    /* implementation of MessageEndpointConnection */
    func open(connection: ReplicatorConnection, completion: @escaping (Bool, MessagingError?) -> Void) {
        replicatorConnection = connection
        completion(true, nil)
    }
    // end::active-peer-open[]
    
    // tag::active-peer-send[]
    /* implementation of MessageEndpointConnection */
    func send(message: Message, completion: @escaping (Bool, MessagingError?) -> Void) {
        var data = message.toData()
        /* send the data to the other peer */
        /* ... */
        /* call the completion handler once the message is sent */
        completion(true, nil)
    }
    // end::active-peer-send[]
    
    func receive(data: Data) {
        // tag::active-peer-receive[]
        let message = Message.fromData(data)
        replicatorConnection?.receive(message: message)
        // end::active-peer-receive[]
    }
    
    // tag::active-peer-close[]
    /* implementation of MessageEndpointConnection */
    func close(error: Error?, completion: @escaping () -> Void) {
        /* disconnect with communications framework */
        /* ... */
        /* call completion handler */
        completion()
    }
    // end::active-peer-close[]
    
}

/* ----------------------------------------------------------- */
/* ---------------------  PASSIVE SIDE  ---------------------- */
/* ---------------  stubs for documentation  ----------------- */
/* ----------------------------------------------------------- */
class PassivePeerConnection: NSObject, MessageEndpointConnection {
    
    var messageEndpointListener: MessageEndpointListener?
    var replicatorConnection: ReplicatorConnection?
    
    override init() {
        super.init()
    }
    
    func startListener() {
        // tag::listener[]
        let database = try! Database(name: "mydb")
        let config = MessageEndpointListenerConfiguration(database: database, protocolType: .messageStream)
        messageEndpointListener = MessageEndpointListener(config: config)
        // end::listener[]
    }
    
    func stopListener() {
        // tag::passive-stop-listener[]
        messageEndpointListener?.closeAll()
        // end::passive-stop-listener[]
    }
    
    func acceptConnection() {
        // tag::advertizer-accept[]
        let connection = PassivePeerConnection() /* implements MessageEndpointConnection */
        messageEndpointListener?.accept(connection: connection)
        // end::advertizer-accept[]
    }
    
    func disconnect() {
        // tag::passive-replicator-close[]
        replicatorConnection?.close(error: nil)
        // end::passive-replicator-close[]
    }
    
    // tag::passive-peer-open[]
    /* implementation of MessageEndpointConnection */
    func open(connection: ReplicatorConnection, completion: @escaping (Bool, MessagingError?) -> Void) {
        replicatorConnection = connection
        completion(true, nil)
    }
    // end::passive-peer-open[]
    
    // tag::passive-peer-send[]
    /* implementation of MessageEndpointConnection */
    func send(message: Message, completion: @escaping (Bool, MessagingError?) -> Void) {
        var data = Data()
        data.append(message.toData())
        /* send the data to the other peer */
        /* ... */
        /* call the completion handler once the message is sent */
        completion(true, nil)
    }
    // end::passive-peer-send[]
    
    func receive(data: Data) {
        // tag::passive-peer-receive[]
        let message = Message.fromData(data)
        replicatorConnection?.receive(message: message)
        // end::passive-peer-receive[]
    }
    
    // tag::passive-peer-close[]
    /* implementation of MessageEndpointConnection */
    func close(error: Error?, completion: @escaping () -> Void) {
        /* disconnect with communications framework */
        /* ... */
        /* call completion handler */
        completion()
    }
    // end::passive-peer-close[]
}
