package com.couchbase.android.cloudsync

// tag::cloudsync[]
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.couchbase.lite.BasicAuthenticator
import com.couchbase.lite.CollectionConfiguration
import com.couchbase.lite.CouchbaseLite
import com.couchbase.lite.Database
import com.couchbase.lite.MutableDocument
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorConfiguration
import com.couchbase.lite.ReplicatorType
import com.couchbase.lite.URLEndpoint
import java.net.URI

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        CouchbaseLite.init(this)

        val database = Database("getting-started")
        val collection = database.getCollection("hotel", "inventory")
            ?: database.createCollection("hotel", "inventory")

        val hotels = mutableStateOf(emptyList<String>())
        val syncState = mutableStateOf("Starting")

        val query = database.createQuery(
            "SELECT name, city FROM inventory.hotel WHERE type = 'hotel'"
        )

        query.addChangeListener { change -> // <.>
            hotels.value = change.results?.allResults()?.map {
                "${it.getString("name")}, ${it.getString("city")}"
            } ?: emptyList()
        }

        val target = URLEndpoint(
            URI("${BuildConfig.CBL_BASE_URL}/${BuildConfig.CBL_ENDPOINT}") // <.>
        )

        val collectionConfigs = CollectionConfiguration.fromCollections( // <.>
            listOf(collection)
        )

        val config = ReplicatorConfiguration(collectionConfigs, target)
        config.authenticator = BasicAuthenticator( // <.>
            BuildConfig.CBL_USER,
            BuildConfig.CBL_PASSWORD.toCharArray()
        )
        config.type = ReplicatorType.PUSH_AND_PULL
        config.isContinuous = true // <.>

        val replicator = Replicator(config)

        replicator.addChangeListener { change -> // <.>
            syncState.value = change.status.activityLevel.toString()
            change.status.error?.let { Log.e("SYNC", "Replication error", it) }
        }

        replicator.start()

        setContent {
            Column(Modifier.fillMaxSize().padding(24.dp)) {
                Text("Sync: ${syncState.value}")
                Button(onClick = {
                    collection.save( // <.>
                        MutableDocument()
                            .setString("type", "hotel")
                            .setString("source", "cbl-tutorial")
                            .setString("name", "Hotel ${(100..999).random()}")
                            .setString("city", "Birmingham")
                    )
                }) { Text("Add a hotel") }
                hotels.value.forEach { hotel -> Text(hotel) }
            }
        }
    }
}
// end::cloudsync[]
