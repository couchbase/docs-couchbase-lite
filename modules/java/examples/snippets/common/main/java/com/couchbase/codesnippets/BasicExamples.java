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

import java.io.File;

import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

import com.couchbase.lite.Array;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLite;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseConfiguration;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Document;
import com.couchbase.lite.MutableArray;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;


public class BasicExamples {
    public class SupportingDatatypes {
        private final File rootDir;

        public SupportingDatatypes(@NotNull File rootDir) { this.rootDir = rootDir; }

        public void datatypeUsage() throws CouchbaseLiteException {
            // tag::datatype_usage[]
            // tag::datatype_usage_createdb[]
            // Initialize the Couchbase Lite system
            CouchbaseLite.init();

            // Get the database (and create it if it doesn’t exist).
            DatabaseConfiguration config = new DatabaseConfiguration();
            config.setDirectory(this.rootDir.getAbsolutePath());
            Database database = new Database("getting-started", config)
            try (Collection collection = database.getCollection("myCollection")) {
                if (collection == null) { throw new IllegalStateException("collection not found"); }

                // end::datatype_usage_createdb[]
                // tag::datatype_usage_createdoc[]
                // Create your new document
                MutableDocument mutableDoc = new MutableDocument();

                // end::datatype_usage_createdoc[]
                // tag::datatype_usage_mutdict[]
                // Create and populate mutable dictionary
                // Create a new mutable dictionary and populate some keys/values
                MutableDictionary address = new MutableDictionary();
                address.setString("street", "1 Main st.");
                address.setString("city", "San Francisco");
                address.setString("state", "CA");
                address.setString("country", "USA");
                address.setString("code", "90210");

                // end::datatype_usage_mutdict[]
                // tag::datatype_usage_mutarray[]
                // Create and populate mutable array
                MutableArray phones = new MutableArray();
                phones.addString("650-000-0000");
                phones.addString("650-000-0001");

                // end::datatype_usage_mutarray[]
                // tag::datatype_usage_populate[]
                // Initialize and populate the document

                // Add document type to document properties <.>
                mutableDoc.setString("type", "hotel");

                // Add hotel name string to document properties <.>
                mutableDoc.setString("name", "Hotel Java Mo");

                // Add float to document properties <.>
                mutableDoc.setFloat("room_rate", 121.75F);

                // Add dictionary to document's properties <.>
                mutableDoc.setDictionary("address", (Dictionary) address);

                // Add array to document's properties <.>
                mutableDoc.setArray("phones", (Array) phones);

                // end::datatype_usage_populate[]
                // tag::datatype_usage_persist[]
                // Save the document changes <.>
                collection.save(mutableDoc);
                // end::datatype_usage_persist[]
            }

            // tag::datatype_usage_closedb[]
            // Close the database <.>
            database.close();

            // end::datatype_usage_closedb[]

            // end::datatype_usage[]
        }

        public void datatypeDictionary(@NotNull Collection collection) throws CouchbaseLiteException {

            // tag::datatype_dictionary[]
            // NOTE: No error handling, for brevity (see getting started)
            Document document = collection.getDocument("doc1");
            if (document == null) { return; }

            // Getting a dictionary from the document's properties
            Dictionary dict = document.getDictionary("address");
            if (dict == null) { return; }

            // Access a value with a key from the dictionary
            String street = dict.getString("street");

            // Iterate dictionary
            for (String key: dict.getKeys()) {
                System.out.println("Key " + key + " = " + dict.getValue(key));
            }

            // Create a mutable copy
            MutableDictionary mutableDict = dict.toMutable();

            // end::datatype_dictionary[]
        }

        public void datatypeMutableDictionary(@NotNull Collection collection) throws CouchbaseLiteException {

            // tag::datatype_mutable_dictionary[]
            // NOTE: No error handling, for brevity (see getting started)

            // Create a new mutable dictionary and populate some keys/values
            MutableDictionary mutableDict = new MutableDictionary();
            mutableDict.setString("street", "1 Main st.");
            mutableDict.setString("city", "San Francisco");

            // Add the dictionary to a document's properties and save the document
            MutableDocument mutableDoc = new MutableDocument("doc1");
            mutableDoc.setDictionary("address", (Dictionary) mutableDict);
            collection.save(mutableDoc);

            // end::datatype_mutable_dictionary[]
        }

        public void datatypeArray(@NotNull Collection collection) throws CouchbaseLiteException {

            // tag::datatype_array[]
            // NOTE: No error handling, for brevity (see getting started)

            Document document = collection.getDocument("doc1");
            if (document == null) { return; }

            // Getting a phones array from the document's properties
            Array array = document.getArray("phones");
            if (array == null) { return; }

            // Get element count
            int count = array.count();

            // Access an array element by index
            String phone = array.getString(1);

            // Iterate array
            for (int i = 0; i < count; i++) {
                System.out.println("Row  " + i + " = " + array.getString(i));
            }

            // Create a mutable copy
            MutableArray mutableArray = array.toMutable();
            // end::datatype_array[]
        }

        public void datatypeMutableArray(@NotNull Collection collection) throws CouchbaseLiteException {

            // tag::datatype_mutable_array[]
            // NOTE: No error handling, for brevity (see getting started)

            // Create a new mutable array and populate data into the array
            MutableArray mutableArray = new MutableArray();
            mutableArray.addString("650-000-0000");
            mutableArray.addString("650-000-0001");

            // Set the array to document's properties and save the document
            MutableDocument mutableDoc = new MutableDocument("doc1");
            mutableDoc.setArray("phones", (Array) mutableArray);
            collection.save(mutableDoc);
            // end::datatype_mutable_array[]
        }
    }
}

