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
package com.couchbase.codesnippets;

import java.util.Map;

import org.json.JSONException;
import org.json.JSONObject;

import com.couchbase.codesnippets.utils.Logger;
import com.couchbase.lite.Array;
import com.couchbase.lite.Blob;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableArray;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;


@SuppressWarnings({"unused", "ConstantConditions"})
public class JSONExamples {
    public static final String JSON
        = "[{\"id\":\"1000\",\"type\":\"hotel\",\"name\":\"Hotel Ted\",\"city\":\"Paris\","
        + "\"country\":\"France\",\"description\":\"Undefined description for Hotel Ted\"},"
        + "{\"id\":\"1001\",\"type\":\"hotel\",\"name\":\"Hotel Fred\",\"city\":\"London\","
        + "\"country\":\"England\",\"description\":\"Undefined description for Hotel Fred\"},"
        + "{\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\","
        + "\"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\","
        + "\"features\":[\"Cable TV\",\"Toaster\",\"Microwave\"]}]";

    public void jsonArrayExample(Database db) throws CouchbaseLiteException {
        // tag::tojson-array[]
        // github tag=tojson-array
        final MutableArray mArray = new MutableArray(JSON); // <.>

        for (int i = 0; i < mArray.count(); i++) { // <.>
            final Dictionary dict = mArray.getDictionary(i);
            Logger.log(dict.getString("name"));
            db.save(new MutableDocument(dict.getString("id"), dict.toMap()));
        }

        final Array features = db.getDocument("1002").getArray("features");
        for (Object feature: features.toList()) { Logger.log(feature.toString()); }
        Logger.log(features.toJSON()); // <.>
        // end::tojson-array[]
    }

    public void jsonBlobExample(Database db) {
        // tag::tojson-blob[]
        // github tag=tojson-blob
        final Map<String, ?> thisBlob = db.getDocument("thisdoc-id").toMap();
        if (!Blob.isBlob(thisBlob)) { return; }

        final String blobType = thisBlob.get("content_type").toString();
        final Number blobLength = (Number) thisBlob.get("length");
        // end::tojson-blob[]
    }

    public void jsonDictionaryExample(Database db) {
        // tag::tojson-dictionary[]
        // github tag=tojson-dictionary
        final MutableDictionary mDict = new MutableDictionary(JSON); // <.>
        Logger.log(mDict.toString());

        Logger.log("Details for: " + mDict.getString("name"));
        for (String key: mDict.getKeys()) {
            Logger.log(key + " => " + mDict.getValue(key));
        }
        // end::tojson-dictionary[]
    }

    public void jsonDocumentExample(Database srcDb, Database dstDb) throws CouchbaseLiteException {
        // tag::tojson-document[]
        // github tag=tojson-document
        final Query listQuery = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"))
            .from(DataSource.database(srcDb));

        try (ResultSet results = listQuery.execute()) {
            for (Result row: results) {
                final String thisId = row.getString("metaId");

                final String json = srcDb.getDocument(thisId).toJSON(); // <.>
                Logger.log("JSON String = " + json);

                final MutableDocument hotelFromJSON = new MutableDocument(thisId, json); // <.>

                dstDb.save(hotelFromJSON);

                for (Map.Entry<String, Object> entry: dstDb.getDocument(thisId).toMap().entrySet()) {
                    Logger.log(entry.getKey() + " => " + entry.getValue()); // <.>
                }
            }
        }
        // end::tojson-document[]
    }

    public void jsonQueryExample(Query query) throws CouchbaseLiteException, JSONException {
        try (ResultSet results = query.execute()) {
            for (Result row: results) {

                // get the result into a JSON String
                final String jsonString = row.toJSON();

                final JSONObject thisJsonObj = new JSONObject(jsonString);

                // Use Json Object to populate Native object
                // Use Codable class to unpack JSON data to native object
                final Hotel thisHotel = new Hotel(
                    "this hotel",
                    "Ghana, West Africa",
                    thisJsonObj.getString("city"),
                    thisJsonObj.getString("name"),
                    thisJsonObj.getString("type"),
                    thisJsonObj.getString("id"));
            }
        }
    }
}

