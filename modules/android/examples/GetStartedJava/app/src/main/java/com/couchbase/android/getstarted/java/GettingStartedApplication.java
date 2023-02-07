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
package com.couchbase.android.getstarted.java;

import android.app.Application;
import android.content.Context;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;


public class GettingStartedApplication extends Application {
    private static final ExecutorService EXECUTOR_SERVICE = Executors.newFixedThreadPool(4);

    private static Context app;

    public static Context getAppContext() { return app; }

    public static void runAsync(Runnable task) { EXECUTOR_SERVICE.execute(task); }


    @Override
    public void onCreate() {
        super.onCreate();
        app = this;
    }
}
