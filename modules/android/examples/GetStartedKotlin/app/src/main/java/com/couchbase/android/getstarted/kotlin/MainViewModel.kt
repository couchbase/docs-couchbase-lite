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
package com.couchbase.android.getstarted.kotlin

import android.content.Context
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import java.lang.ref.WeakReference

class MainViewModel(private val context: WeakReference<Context>) : ViewModel() {
    private val replicationState: MutableLiveData<String> by lazy { MutableLiveData<String>("Not Started") }

    fun runIt(): MutableLiveData<String> {
        context.get()?.let {
            viewModelScope.launch(Dispatchers.IO) {
                val mgr = DBManager.getInstance(it)
                mgr.createDb("example")
                mgr.createCollection("example")
                val id = mgr.createDoc()
                mgr.retrieveDoc(id)
                mgr.updateDoc(id)
                mgr.queryDocs()
                mgr.replicate()
                    ?.onEach { change -> replicationState.postValue(change.status.activityLevel.toString()) }
                    ?.collect()
            }
        }
        return replicationState
    }
}