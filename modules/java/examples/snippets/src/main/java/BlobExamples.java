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

import java.util.Map;

import com.couchbase.lite.Blob;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;


public class BlobExamples {

    // Example 2: Using Blobs
    public void example2(final Database db) throws CouchbaseLiteException {
        final Document doc = db.getDocument("1000");
        if (doc == null) { return; }

        // Create a blob from an asset
        final Blob blob = new Blob(
            "image/png",
            Thread.currentThread().getContextClassLoader().getResourceAsStream("couchbaseimage.png"));

        // This will fail:
        // IllegalStateException("A Blob may be encoded as JSON only after it has been saved in a database")
        blob.toJSON();

        // Save the blob as part of a document
        final MutableDocument mDoc = doc.toMutable();
        mDoc.setBlob("avatar", blob);
        db.save(mDoc);

        // Experts only!!!
        db.saveBlob(blob);

        // Retrieve saved blob
        final Document sameDoc = db.getDocument("1000");
        if (sameDoc == null) { return; }

        final Blob sameBlob = sameDoc.getBlob("avatar");
        if (sameBlob == null) { return; }

        // Get as JSON again
        final String blobAsJSONString = sameBlob.toJSON();

        // reconstitute
        final Map<String, Object> blobAsMap = new MutableDictionary().setJSON(blobAsJSONString).toMap();

        // show the contents of the reconstituted blob
        for (Map.Entry<String, Object> entry: blobAsMap.entrySet()) {
            System.out.println("Data: " + entry.getKey() + " -> " + entry.getValue());
        }

        // verify that the reconstituted thing is still blob
        if (Blob.isBlob(blobAsMap)) { System.out.println(blobAsJSONString); }
    }
}
