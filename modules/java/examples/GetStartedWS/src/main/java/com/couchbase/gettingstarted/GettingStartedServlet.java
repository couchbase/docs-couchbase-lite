package com.couchbase.gettingstarted;

import java.io.IOException;
import java.net.URISyntaxException;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import jakarta.servlet.annotation.WebServlet;

import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.Document;
import com.couchbase.lite.ReplicatorActivityLevel;
import com.couchbase.lite.Result;


@WebServlet(urlPatterns = "/GettingStarted")
public class GettingStartedServlet extends HttpServlet {
    private static final String DB_NAME = "example";
    private static final String COLL_NAME = "example";
    private static final String NEWLINE_TAG = "<br />";
    private static final String SG_URI = null; // "ws://localhost:4984/getting-started-db"

    //private int numRows;
    private String log;

    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        logToResponse("Servlet started :: doPost");
        handleReq(req, resp);
    }

    // tag::getting-started[]

    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        logToResponse("Servlet started :: doGet");
        handleReq(req, resp);
    }

    private void handleReq(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        log = "";

        int numRows = runCBL();

        req.setAttribute("rowCount", numRows);
        req.setAttribute("log", log);
        getServletContext()
            .getRequestDispatcher("/showDbItems.jsp")
            .forward(req, resp);

        logToResponse("Servlet Ended :: doPost Exits");
    }

    private int runCBL() throws ServletException {
        DBManager mgr = DBManager.getInstance();
        logToResponse("CBL Initialized");

        DBManager.Replication replication = null;
        int numRows = 0;
        try {
            Database db = mgr.createDb(DB_NAME);
            logToResponse("Database created: " + db.getName());
            Collection coll = mgr.createCollection(db, COLL_NAME);
            logToResponse("Collection created: " + coll);
            String id = mgr.createDoc(coll);
            Document doc = mgr.retrieveDoc(coll, id);
            if (doc == null) {
                logToResponse("No such document :: " + id);
            }
            else {
                logToResponse("Document ID :: " + doc.getId());
                logToResponse("Learning :: " + doc.getString("language"));
            }
            mgr.updateDoc(coll, id);
            List<Map<String, Object>> results = mgr.queryDocs(coll);
            numRows = results.size();
            logToResponse("Number of rows :: " + numRows);

            //  <.>
            // OPTIONAL -- if you have Sync Gateway Installed you can try replication too
            // Create a replicator to push and pull changes to and from the cloud.
            // Be sure to hold a reference somewhere to prevent the Replicator from being GCed
            if (SG_URI != null) {replication = startReplicator(mgr, coll, SG_URI); }
        }
        catch (CouchbaseLiteException | URISyntaxException | InterruptedException e) {
            throw new ServletException("Couchbase error", e);
        }
        finally {
            if (replication != null) { mgr.stopReplicator(replication); }
            logToResponse("Replication Finished at :: " + Instant.now());
        }

        return numRows;
    }

    private DBManager.Replication startReplicator(DBManager mgr, Collection coll, String url)
        throws URISyntaxException, ServletException, InterruptedException {
        // CAUTION: Demonstration only!!!
        // One would NEVER do this in a real WebApp!!
        CountDownLatch latch = new CountDownLatch(1);
        DBManager.Replication repl = mgr.startReplicator(
            coll,
            change -> {
                ReplicatorActivityLevel status = change.getStatus().getActivityLevel();
                logToResponse("Replicator state changed :: " + status);
                // Check status of replication and wait till it is completed
                if ((status == ReplicatorActivityLevel.STOPPED) || (status == ReplicatorActivityLevel.IDLE)) {
                    latch.countDown();
                }
            });
        logToResponse("Replication Started at :: " + Instant.now());

        if (!latch.await(10L, TimeUnit.MINUTES)) {
            throw new ServletException("Replicator did not finish");
        }

        return repl;
    }
    // end::getting-started[]

    public void logToResponse(String msg) {
        System.out.println(msg);
        log = log + msg + NEWLINE_TAG;
    }
}
