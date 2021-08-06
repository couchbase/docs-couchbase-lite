//
// Copyright (c) 2020 Couchbase, Inc All rights reserved.
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
package com.couchbase.android.fruitsnveg.examples;

import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.IOException;
import java.net.URI;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.CountDownLatch;

import com.couchbase.lite.AbstractReplicator;
import com.couchbase.lite.BasicAuthenticator;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.ListenerPasswordAuthenticator;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.lite.URLEndpointListener;
import com.couchbase.lite.URLEndpointListenerConfiguration;


public class PasswordAuthListener {
    private static final String TAG = "PWD";

    // start a server and connect to it with a replicator
    public void run() throws CouchbaseLiteException, IOException {
        final Database localDb = new Database("localDb");
        MutableDocument doc = new MutableDocument();
        doc.setString("dog", "woof");
        localDb.save(doc);

        Database remoteDb = new Database("remoteDb");
        doc = new MutableDocument();
        doc.setString("cat", "meow");
        localDb.save(doc);

        final URI uri = startServer(remoteDb, "fox", "wa-pa-pa-pa-pa-pow".toCharArray());
        if (uri == null) { throw new IOException("Failed to start the server"); }

        new Thread(() -> {
            try {
                runClient(uri, "fox", "wa-pa-pa-pa-pa-pow".toCharArray(), localDb);
                Log.e(TAG, "Success!!");
            }
            catch (Exception e) { Log.e(TAG, "Failed!!", e); }
        }).start();
    }

    // start a client replicator
    public void runClient(
        @NonNull URI uri,
        @NonNull String username,
        @NonNull char[] password,
        @NonNull Database db) throws InterruptedException {
        final ReplicatorConfiguration config = new ReplicatorConfiguration(db, new URLEndpoint(uri));
        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL);
        config.setContinuous(false);
        config.setAuthenticator(new BasicAuthenticator(username, password));

        final CountDownLatch completionLatch = new CountDownLatch(1);
        final Replicator repl = new Replicator(config);
        repl.addChangeListener(change -> {
            if (change.getStatus().getActivityLevel() == AbstractReplicator.ActivityLevel.STOPPED) {
                completionLatch.countDown();
            }
        });

        repl.start(false);
        completionLatch.await();
    }

    /**
     * Snippet 1: create a ListenerPasswordAuthenticator and configure the listener with it
     *
     * Start a listener for db that accepts connections using exactly the passed username and password
     * NOTE: This requires the following, in the manifest
     *     <application
     *         ...
     *         android:usesCleartextTraffic="true"
     *         ...
     *     >
     *
     * @param db       the database to which the listener is attached
     * @param username the name of the single valid user
     * @param password the password for the user
     * @return the url at which the listener can be reached.
     * @throws CouchbaseLiteException on failure
     */
    @Nullable
    public URI startServer(@NonNull Database db, @NonNull String username, @NonNull char[] password)
        throws CouchbaseLiteException {
        final URLEndpointListenerConfiguration config = new URLEndpointListenerConfiguration(db);

        config.setPort(0); // this is the default
        config.setDisableTls(true);
        config.setAuthenticator(new ListenerPasswordAuthenticator(
            (user, pwd) -> username.equals(user) && Arrays.equals(password, pwd)));

        final URLEndpointListener listener = new URLEndpointListener(config);
        listener.start();

        final List<URI> urls = listener.getUrls();
        if (urls.isEmpty()) { return null; }
        return urls.get(0);
    }
}
