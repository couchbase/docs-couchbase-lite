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
package com.couchbase.code_snippets;

import java.util.Map;
import java.util.Objects;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.json.JSONException;
import org.json.JSONObject;

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
import com.couchbase.lite.SelectResult;


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
        final MutableArray mArray = new MutableArray(JSON);

        for (int i = 0; i < mArray.count(); i++) {
            final Dictionary dict = mArray.getDictionary(i);
            System.out.println(dict.getString("name"));
            db.save(new MutableDocument(dict.getString("id"), dict.toMap()));
        }

        final Array features = db.getDocument("1002").getArray("features");
        for (Object feature: features.toList()) { System.out.println(feature.toString()); }
        System.out.println(features.toJSON());
    }

    public void jsonBlobExample(Database db) {
        final Map<String, ?> thisBlob = db.getDocument("thisdoc-id").toMap();
        if (!Blob.isBlob(thisBlob)) { return; }

        final String blobType = thisBlob.get("content_type").toString();
        final Number blobLength = (Number) thisBlob.get("length");
    }

    public void jsonDictionaryExample(Database db) {
        final MutableDictionary mDict = new MutableDictionary(JSON);
        System.out.println(mDict.toString());

        System.out.println("Details for: " + mDict.getString("name"));
        for (String key: mDict.getKeys()) {
            System.out.println(key + " => " + mDict.getValue(key));
        }
    }

    public void jsonDocumentExample(Database srcDb, Database dstDb) throws CouchbaseLiteException {
        final Query listQuery = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"))
            .from(DataSource.database(srcDb));

        for (Result row: listQuery.execute()) {
            final String thisId = row.getString("metaId");

            final String json = srcDb.getDocument(thisId).toJSON();
            System.out.println("JSON String = " + json);

            final MutableDocument hotelFromJSON = new MutableDocument(thisId, json);

            dstDb.save(hotelFromJSON);

            for (Map.Entry entry: dstDb.getDocument(thisId).toMap().entrySet()) {
                System.out.println(entry.getKey() + " => " + entry.getValue());
            }
        }
    }

    public void jsonQueryExample(Query query) throws CouchbaseLiteException, JSONException {
        for (Result row: query.execute()) {

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

class Hotel {
    @Nullable
    private String description;
    @Nullable
    private String country;
    @Nullable
    private String city;
    @Nullable
    private String name;
    @Nullable
    private String type;
    @Nullable
    private String id;

    public Hotel(
        @Nullable String description,
        @Nullable String country,
        @Nullable String city,
        @Nullable String name,
        @Nullable String type,
        @Nullable String id) {
        this.description = description;
        this.country = country;
        this.city = city;
        this.name = name;
        this.type = type;
        this.id = id;
    }

    @Nullable
    public final String getDescription() { return this.description; }

    public final void setDescription(@Nullable String var1) { this.description = var1; }

    @Nullable
    public final String getCountry() { return this.country; }

    public final void setCountry(@Nullable String var1) { this.country = var1; }

    @Nullable
    public final String getCity() { return this.city; }

    public final void setCity(@Nullable String var1) { this.city = var1; }

    @Nullable
    public final String getName() { return this.name; }

    public final void setName(@Nullable String var1) { this.name = var1; }

    @Nullable
    public final String getType() { return this.type; }

    public final void setType(@Nullable String var1) { this.type = var1; }

    @Nullable
    public final String getId() { return this.id; }

    public final void setId(@Nullable String var1) { this.id = var1; }

    @NotNull
    @Override
    public String toString() {
        return "Hotel(description=" + this.description + ", country=" + this.country
            + ", city=" + this.city + ", " + "name=" + this.name + ", type=" + this.type + ", id=" + this.id + ")";
    }

    @Override
    public int hashCode() { return Objects.hash(description, country, city, name, type, id); }

    @Override
    public boolean equals(Object o) {
        if (this == o) { return true; }
        if (!(o instanceof Hotel)) { return false; }
        Hotel hotel = (Hotel) o;
        return Objects.equals(description, hotel.description)
            && Objects.equals(country, hotel.country)
            && Objects.equals(city, hotel.city)
            && Objects.equals(name, hotel.name)
            && Objects.equals(type, hotel.type)
            && Objects.equals(id, hotel.id);
    }
}
