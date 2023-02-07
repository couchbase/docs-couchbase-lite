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

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.RejectedExecutionHandler;
import java.util.concurrent.SynchronousQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import com.couchbase.lite.Collection;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseEndpoint;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorChange;
import com.couchbase.lite.ReplicatorChangeListener;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorType;


@SuppressWarnings({"unused", "ConstantConditions"})
public class ExecutionPolicyExamples {
    private Replicator thisReplicator;
    private ListenerToken thisToken;

    // tag::execution-inorder[]
    private static final ExecutorService IN_ORDER_EXEC = Executors.newSingleThreadExecutor();

    /**
     * This version guarantees in order delivery and is parsimonious with space
     * The listener does not need to be thread safe (at least as far as this code is concerned).
     * It will run on only thread (the Executor's thread) and must return from a given call
     * before the next call commences.  Events may be delivered arbitrarily late, though,
     * depending on how long it takes the listener to run.
     */
    public void runInOrder(Collection collection, Database target) {
        Replicator repl = new Replicator(new ReplicatorConfiguration(new DatabaseEndpoint(target))
            .setType(ReplicatorType.PUSH_AND_PULL)
            .setContinuous(false));

        thisToken = repl.addChangeListener(IN_ORDER_EXEC, this::onChange);

        repl.start();
        thisReplicator = repl;
    }
    // end::execution-inorder[]


    // tag::execution-maxthroughput[]
    private static final ExecutorService MAX_THROUGHPUT_EXEC = Executors.newCachedThreadPool();

    /**
     * This version maximizes throughput.  It will deliver change notifications as quickly
     * as CPU availability allows. It may deliver change notifications out of order.
     * Listeners must be thread safe because they may be called from multiple threads.
     * In fact, they must be re-entrant because a given listener may be running on mutiple threads
     * simultaneously.  In addition, when notifications swamp the processors, notifications awaiting
     * a processor will be queued as Threads, (instead of as Runnables) with accompanying memory
     * and GC impact.
     */
    public void runMaxThroughput(Collection collection, Database target) {
        Replicator repl = new Replicator(new ReplicatorConfiguration(new DatabaseEndpoint(target))
            .setType(ReplicatorType.PUSH_AND_PULL)
            .setContinuous(false));

        thisToken = repl.addChangeListener(MAX_THROUGHPUT_EXEC, this::onChange);

        repl.start();
        thisReplicator = repl;
    }
    // end::execution-maxthroughput[]


    // tag::execution-policied[]
    private static final int CPUS = Runtime.getRuntime().availableProcessors();

    private static final AtomicReference<ThreadPoolExecutor> BACKUP_EXEC = new AtomicReference<>();

    private static final RejectedExecutionHandler BACKUP_EXECUTION = (r, e) -> {
            ExecutorService exec = BACKUP_EXEC.get();
            if (exec != null) {
                exec.execute(r);
                return;
            }

            BACKUP_EXEC.compareAndSet(null, createBackupExecutor());
            BACKUP_EXEC.get().execute(r);
        };

    private static ThreadPoolExecutor createBackupExecutor() {
        ThreadPoolExecutor exec = new ThreadPoolExecutor(
            CPUS + 1,
            2 * CPUS + 1,
            30, TimeUnit.SECONDS,
            new LinkedBlockingQueue<>());
        exec.allowCoreThreadTimeOut(true);
        return exec;
    }

    private static final ThreadPoolExecutor STANDARD_EXEC = new ThreadPoolExecutor(
        CPUS + 1,
        2 * CPUS + 1,
        30, TimeUnit.SECONDS,
        new SynchronousQueue<>());
    static { STANDARD_EXEC.setRejectedExecutionHandler(BACKUP_EXECUTION); }
    /**
     * This version demonstrates the extreme configurability of the Couchbase Lite replicator callback system.
     * It may deliver updates out of order and does require thread-safe and re-entrant listeners
     * (though it does correctly synchronize tasks passed to it using a SynchronousQueue).
     * The thread pool executor shown here is configured for the sweet spot for number of threads per CPU.
     * In a real system, this single executor might be used by the entire application and be passed to
     * this module, thus establishing a reasonable app-wide threading policy.
     * In an emergency (Rejected Execution) it lazily creates a backup executor with an unbounded queue
     * in front of it.  It, thus, may deliver notifications late, as well as out of order.
     */
    public void runExecutionPolicy(Collection collection, Database target, ReplicatorChangeListener listener) {
        Replicator repl = new Replicator(new ReplicatorConfiguration(new DatabaseEndpoint(target))
            .setType(ReplicatorType.PUSH_AND_PULL)
            .setContinuous(false));

        thisToken = repl.addChangeListener(STANDARD_EXEC, this::onChange);

        repl.start();
        thisReplicator = repl;
    }
    // end::execution-policied[]

    private void onChange(ReplicatorChange change) { }
}

