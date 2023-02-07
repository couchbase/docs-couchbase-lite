package com.couchbase.android.getstarted.kotlin

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import org.koin.androidx.viewmodel.ext.android.viewModel


class MainActivity : AppCompatActivity() {
    private val model by viewModel<MainViewModel>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val statusView = findViewById<TextView>(R.id.replState)
        val runButton = findViewById<Button>(R.id.runIt)

        // Extremely simple: allows starting one replicator on top of another...
        runButton.setOnClickListener {
            model.runIt().observe(this) { statusView.text = it }
        }
    }
}
