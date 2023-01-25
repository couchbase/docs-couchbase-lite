package com.couchbase.android.getstarted.java;

import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;

import com.example.getstarted_java.R;


public class MainActivity extends AppCompatActivity {
    private static final String TAG = "CBL-GS";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
    }
}
