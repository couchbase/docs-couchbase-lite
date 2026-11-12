package com.couchbase.android.quickstart

// tag::quickstart[]
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.couchbase.lite.CouchbaseLite
import com.couchbase.lite.Database
import com.couchbase.lite.MutableDocument

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        CouchbaseLite.init(this) // <.>

        val database = Database("getting-started") // <.>

        val collection = database.getCollection("hotel", "inventory") // <.>
            ?: database.createCollection("hotel", "inventory")

        collection.save( // <.>
            MutableDocument("hotel::1")
                .setString("type", "hotel")
                .setString("name", "Hotel Couchbase")
                .setString("city", "Manchester")
        )

        val query = database.createQuery( // <.>
            "SELECT name, city FROM inventory.hotel WHERE type = 'hotel'"
        )

        val hotels = query.execute().use { resultSet ->
            resultSet.allResults().map {
                "${it.getString("name")}, ${it.getString("city")}"
            }
        }

        setContent { // <.>
            Column(Modifier.fillMaxSize().padding(24.dp)) {
                hotels.forEach { hotel -> Text(hotel) }
            }
        }
    }
}
// end::quickstart[]
