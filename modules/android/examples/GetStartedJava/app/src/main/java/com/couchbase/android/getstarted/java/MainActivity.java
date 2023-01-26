package com.couchbase.android.getstarted.java;

import android.os.Bundle;
import android.widget.Button;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.ViewModelProvider;


public class MainActivity extends AppCompatActivity {
     private MainViewModel model;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        model = new ViewModelProvider(this).get(MainViewModel.class);

        TextView statusView = findViewById(R.id.replState);
        Button runButton = findViewById(R.id.runIt);

        // Extremely simple: allows starting one replicator on top of another...
        runButton.setOnClickListener(v -> model.runIt().observe(this, statusView::setText));
    }

    @Override
    protected void onStop() {
        super.onStop();
        model.stopIt();
    }
}
