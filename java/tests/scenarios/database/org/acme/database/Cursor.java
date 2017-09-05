package org.acme.database;

import java.util.List;


public class Cursor {

    private final int BATCH_SIZE = 2;
    private int mBatchPointer = 0;
    private int mWithinBatchPointer = -1;
    private List mRows;

    public Cursor() {}

    public void addRows(List rows) {
        this.mRows = rows;
    }

    public void execute(String pQuery) {}

    public void fetchone() throws ConnectionException {
        this.mWithinBatchPointer += 1;
    }

    public int rowCount() {
        return Math.min(BATCH_SIZE, (this.mRows.size() - this.mBatchPointer)); 
    }

    private int getCurrentRowId() {
        return this.mBatchPointer + this.mWithinBatchPointer;
    }

    private Object[] getCurrentRow() {
        return (Object[]) this.mRows.get(this.getCurrentRowId());
    }

    public int getInt(int index) {
        return (int) this.getCurrentRow()[index];
    }

    public String getString(int index) {
        return (String) this.getCurrentRow()[index];
    }

    public int getSize() {
      return this.mRows.size();
    }

    public void next(int lastId) throws ConnectionException {
        this.mBatchPointer = this.mBatchPointer + BATCH_SIZE;
        this.mWithinBatchPointer = -1;
    }

    public boolean end() {
      return this.getCurrentRowId() >= (this.mRows.size() - 1);
    }

}
