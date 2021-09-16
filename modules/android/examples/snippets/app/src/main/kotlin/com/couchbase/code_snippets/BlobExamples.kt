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

import android.content.Context
import android.util.Log
import com.couchbase.lite.Blob
import com.couchbase.lite.Database
import com.couchbase.lite.MutableDictionary

class BlobExamples {

    // Example 2: Using Blobs
    fun example2(context: Context, db: Database) {
        val doc = db.getDocument("1000") ?: return

        // Create a blob from an asset
        val blob = Blob("image/png", context.assets.open("couchbaseimage.png"))

        // This will fail:
        // IllegalStateException("A Blob may be encoded as JSON only after it has been saved in a database")
        blob.toJSON()

        // Save the blob as part of a document
        db.save(doc.toMutable().setBlob("avatar", blob))

        // Experts only!!!
        db.saveBlob(blob)

        // Retrieve saved blob and get as JSON again
        val blobAsJSONString = db.getDocument("1000")?.getBlob("avatar")?.toJSON() ?: return

        // reconstitute
        val blobAsMap = MutableDictionary().setJSON(blobAsJSONString).toMap()

        // show the contents of the reconstituted blob
        for ((key, value) in blobAsMap) {
            Log.d("BLOB", "Data: $key -> $value")
        }

        // verify that the reconstitued thing is still blob
        if (Blob.isBlob(blobAsMap)) {
            Log.d("BLOB", blobAsJSONString)
        }
    }
}