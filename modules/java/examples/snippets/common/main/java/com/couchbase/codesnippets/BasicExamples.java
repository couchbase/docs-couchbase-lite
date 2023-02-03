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
package com.couchbase.codesnippets;

import com.couchbase.lite.Database;
import com.couchbase.lite.LogDomain;
import com.couchbase.lite.LogLevel;


@SuppressWarnings({"unused", "ConstantConditions"})
public class BasicExamples  {
    public void troubleshootingExample() {
        // tag::replication-logging[]
        Database.log.getConsole().setDomains(LogDomain.REPLICATOR);
        Database.log.getConsole().setLevel(LogLevel.VERBOSE);
        // end::replication-logging[]
    }
}
