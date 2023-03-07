//
// Copyright (c) 2023 Couchbase, Inc All rights reserved.
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
package com.couchbase.codesnippets;

import java.io.IOException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.CertificateException;
import java.util.Arrays;
import java.util.Set;

import com.couchbase.codesnippets.utils.Logger;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.ListenerPasswordAuthenticator;
import com.couchbase.lite.URLEndpointListener;
import com.couchbase.lite.URLEndpointListenerConfiguration;


@SuppressWarnings("unused")
class ListenerExamples {
    private URLEndpointListener thisListener;

    public void passiveListenerExample(Set<Collection> collections, String validUser, char[] validPass)
        throws CouchbaseLiteException {
        // EXAMPLE 1
        // tag::listener-initialize[]
        // tag::listener-config-db[]
        // Initialize the listener config
        final URLEndpointListenerConfiguration thisConfig
            = new URLEndpointListenerConfiguration(collections); // <.>

        // end::listener-config-db[]
        // tag::listener-config-port[]
        thisConfig.setPort(55990); //<.>

        // end::listener-config-port[]
        // tag::listener-config-netw-iface[]
        thisConfig.setNetworkInterface("wlan0"); // <.>

        // end::listener-config-netw-iface[]
        // tag::listener-config-delta-sync[]
        thisConfig.setEnableDeltaSync(false); // <.>

        // end::listener-config-delta-sync[]
        // tag::listener-config-tls-full[]
        // Configure server security
        // tag::listener-config-tls-enable[]
        thisConfig.setDisableTls(false); // <.>

        // end::listener-config-tls-enable[]
        // tag::listener-config-tls-id-anon[]
        // Use an Anonymous Self-Signed Cert
        thisConfig.setTlsIdentity(null); // <.>

        // end::listener-config-tls-id-anon[]

        // tag::listener-config-client-auth-pwd[]
        // Configure Client Security using an Authenticator
        // For example, Basic Authentication <.>
        thisConfig.setAuthenticator(new ListenerPasswordAuthenticator(
            (username, password) ->
                username.equals(validUser) && Arrays.equals(password, validPass)));

        // end::listener-config-client-auth-pwd[]
        // tag::listener-start[]
        // Initialize the listener
        final URLEndpointListener thisListener
            = new URLEndpointListener(thisConfig); // <.>

        // Start the listener
        thisListener.start(); // <.>

        // end::listener-start[]
        // end::listener-initialize[]
    }

    public void listenerStatusCheckExample(URLEndpointListener thisListener) {
        // tag::listener-status-check[]
        int connectionCount =
            thisListener.getStatus().getConnectionCount(); // <.>

        int activeConnectionCount =
            thisListener.getStatus().getActiveConnectionCount();  // <.>

        // end::listener-status-check[]
    }

    public void listenerStopExample() {

        // tag::listener-stop[]
        thisListener.stop();

        // end::listener-stop[]
    }

    public void deleteIdentityExample(String alias)
        throws KeyStoreException, CertificateException, IOException, NoSuchAlgorithmException {
        // tag::deleteTlsIdentity[]
        // tag::p2p-tlsid-delete-id-from-keychain[]
        KeyStore thisKeyStore = KeyStore.getInstance("AndroidKeyStore");
        thisKeyStore.load(null);
        thisKeyStore.deleteEntry(alias);

        // end::p2p-tlsid-delete-id-from-keychain[]
        // end::deleteTlsIdentity[]
    }

    public void listenerGetNetworkInterfacesExample(Set<Collection> collections) throws CouchbaseLiteException {
        // tag::listener-get-network-interfaces[]
        final URLEndpointListener listener
            = new URLEndpointListener(
            new URLEndpointListenerConfiguration(collections));
        listener.start();
        thisListener = listener;
        Logger.log("URLS are " + thisListener.getUrls());

        // end::listener-get-network-interfaces[]
    }

    public void listenerSimpleExample(Set<Collection> collections, String validUser, char[] validPass)
        throws CouchbaseLiteException {
        // tag::listener-simple[]
        final URLEndpointListenerConfiguration thisConfig =
            new URLEndpointListenerConfiguration(collections); // <.>

        thisConfig.setAuthenticator(
            new ListenerPasswordAuthenticator(
                (username, password) ->
                    validUser.equals(username) && Arrays.equals(validPass, password)
            )
        ); // <.>

        final URLEndpointListener thisListener =
            new URLEndpointListener(thisConfig); // <.>

        thisListener.start(); // <.>

        // end::listener-simple[]
    }
}
