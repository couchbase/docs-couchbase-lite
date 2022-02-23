//
// Copyright (c) 2021 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
package com.couchbase.code_snippets

import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.Database
import com.couchbase.lite.Message
import com.couchbase.lite.MessageEndpoint
import com.couchbase.lite.MessageEndpointConnection
import com.couchbase.lite.MessageEndpointDelegate
import com.couchbase.lite.MessageEndpointListener
import com.couchbase.lite.MessageEndpointListenerConfigurationFactory
import com.couchbase.lite.MessagingCloseCompletion
import com.couchbase.lite.MessagingCompletion
import com.couchbase.lite.ProtocolType
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorConfigurationFactory
import com.couchbase.lite.ReplicatorConnection
import com.couchbase.lite.create


@Suppress("unused")
class BrowserSessionManager : MessageEndpointDelegate {
    private var replicator: Replicator? = null

    @Throws(CouchbaseLiteException::class)
    fun initCouchbase() {
        // tag::message-endpoint[]
        val database = Database("mydb")

        // The delegate must implement the `MessageEndpointDelegate` protocol.
        val messageEndpoint = MessageEndpoint("UID:123", "active", ProtocolType.MESSAGE_STREAM, this)
        // end::message-endpoint[]

        // tag::message-endpoint-replicator[]
        // Create the replicator object.
        val repl = Replicator(ReplicatorConfigurationFactory.create(database = database, target = messageEndpoint))
        // Start the replication.
        repl.start()
        replicator = repl
        // end::message-endpoint-replicator[]
    }

    // tag::create-connection[]
    /* implementation of MessageEndpointDelegate */
    override fun createConnection(endpoint: MessageEndpoint) = ActivePeerConnection()
    // end::create-connection[]
}

/* ----------------------------------------------------------- */
/* ---------------------  ACTIVE SIDE  ----------------------- */
/* ----------------------------------------------------------- */

@Suppress("unused")
class ActivePeerConnection : MessageEndpointConnection {
    private var replicatorConnection: ReplicatorConnection? = null

    // tag::active-replicator-close[]
    fun disconnect() {
        replicatorConnection?.close(null)
        replicatorConnection = null
    }
    // end::active-replicator-close[]

    // tag::active-peer-open[]
    /* implementation of MessageEndpointConnection */
    override fun open(connection: ReplicatorConnection, completion: MessagingCompletion) {
        replicatorConnection = connection
        completion.complete(true, null)
    }

    // end::active-peer-open[]
    // tag::active-peer-close[]
    override fun close(error: Exception?, completion: MessagingCloseCompletion) {
        /* disconnect with communications framework */
        /* ... */
        /* call completion handler */
        completion.complete()
    }

    // end::active-peer-close[]
    // tag::active-peer-send[]
    /* implementation of MessageEndpointConnection */
    override fun send(message: Message, completion: MessagingCompletion) {
        /* send the data to the other peer */
        /* ... */
        /* call the completion handler once the message is sent */
        completion.complete(true, null)
    }

    // end::active-peer-send[]
    fun receive(message: Message) {
        // tag::active-peer-receive[]
        replicatorConnection?.receive(message)
        // end::active-peer-receive[]
    }
}

/* ----------------------------------------------------------- */
/* ---------------------  PASSIVE SIDE  ---------------------- */
/* ----------------------------------------------------------- */

@Suppress("unused")
class PassivePeerConnection private constructor() : MessageEndpointConnection {
    private var messageEndpointListener: MessageEndpointListener? = null
    private var replicatorConnection: ReplicatorConnection? = null

    @Throws(CouchbaseLiteException::class)
    fun startListener() {
        // tag::listener[]
        val database = Database("mydb")
        messageEndpointListener = MessageEndpointListener(
            MessageEndpointListenerConfigurationFactory.create(database, ProtocolType.MESSAGE_STREAM)
        )
        // end::listener[]
    }

    fun stopListener() {
        // tag::passive-stop-listener[]
        messageEndpointListener?.closeAll()
        // end::passive-stop-listener[]
    }

    fun accept() {
        // tag::advertizer-accept[]
        val connection = PassivePeerConnection() /* implements MessageEndpointConnection */
        messageEndpointListener?.accept(connection)
        // end::advertizer-accept[]
    }

    fun disconnect() {
        // tag::passive-replicator-close[]
        replicatorConnection?.close(null)
        // end::passive-replicator-close[]
    }

    // tag::passive-peer-open[]
    /* implementation of MessageEndpointConnection */
    override fun open(connection: ReplicatorConnection, completion: MessagingCompletion) {
        replicatorConnection = connection
        completion.complete(true, null)
    }
    // end::passive-peer-open[]

    // tag::passive-peer-close[]
    /* implementation of MessageEndpointConnection */
    override fun close(error: Exception?, completion: MessagingCloseCompletion) {
        /* disconnect with communications framework */
        /* ... */
        /* call completion handler */
        completion.complete()
    }

    // end::passive-peer-close[]
    // tag::passive-peer-send[]
    /* implementation of MessageEndpointConnection */
    override fun send(message: Message, completion: MessagingCompletion) {
        /* send the data to the other peer */
        /* ... */
        /* call the completion handler once the message is sent */
        completion.complete(true, null)
    }

    // end::passive-peer-send[]
    fun receive(message: Message) {
        // tag::passive-peer-receive[]
        replicatorConnection?.receive(message)
        // end::passive-peer-receive[]
    }

}
