//
// Copyright (c) 2024 Couchbase, Inc All rights reserved.
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

import com.couchbase.lite.ArrayIndexConfiguration;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.IndexConfiguration;


public class ArrayIndexExamples {
    public void ArrayIndexConfig() {
        // tag::array-index-config[]
        IndexConfiguration config = new ArrayIndexConfiguration("contacts", "type");
        // end::array-index-config[]
    }

    public void ArrayIndexSingle(Collection collection) throws CouchbaseLiteException {
        // tag::array-index-single[]
        collection.createIndex("myindex", new ArrayIndexConfiguration("likes"));
        // end::array-index-single[]
    }

    public void ArrayIndexNested(Collection collection) throws CouchbaseLiteException {

        // tag::array-index-nested[]
        collection.createIndex(
            "myindex",
            new ArrayIndexConfiguration("contacts[].phones", "type"));
        // end::array-index-nested[]
    }
}
