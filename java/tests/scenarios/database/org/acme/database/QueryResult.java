package org.acme.database;

import java.util.List;


public class QueryResult {

    private final int BATCH_SIZE = 2;
    private int mBatchPointer = 0;
    private List mRows;
    private boolean mIsDone;

    public QueryResult(List rows, boolean pIsDone) {
      this.mRows = rows;
      this.mIsDone = pIsDone;
    }

    public int getSize() {
      return this.mRows.size();
    }

    public List getRecords() {
      return this.mRows;
    }

    public boolean isDone() {
      return this.mIsDone;
    }

    public int getQueryLocator() {
      return this.mBatchPointer;
    }

}
