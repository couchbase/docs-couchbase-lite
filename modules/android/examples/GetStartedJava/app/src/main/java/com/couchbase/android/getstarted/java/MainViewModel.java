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
package com.couchbase.android.getstarted.java;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import java.net.URISyntaxException;
import java.util.concurrent.atomic.AtomicReference;

import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.ListenerToken;


public class MainViewModel extends ViewModel {
    private MutableLiveData<String> replicationState = new MutableLiveData<>("Not Started");
    private AtomicReference<ListenerToken> token = new AtomicReference<>();

    public MutableLiveData<String> runIt() {
        GettingStartedApplication.runAsync(() -> {
            DBManager mgr = DBManager.getInstance();

            try {
                mgr.createDb("example");
                mgr.createCollection("example");
                String id = mgr.createDoc();
                mgr.retrieveDoc(id);
                mgr.updateDoc(id);
                mgr.queryDocs();
                token.set(mgr.replicate(change ->
                    replicationState.postValue(change.getStatus().getActivityLevel().toString())));
            }
            catch (CouchbaseLiteException | URISyntaxException e) {
                replicationState.postValue("Failed");
            }
        });

        return replicationState;
    }

    public void stopIt() {
        ListenerToken token = this.token.getAndSet(null);
        if (token != null) { token.remove(); }
    }
}
