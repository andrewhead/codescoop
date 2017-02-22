import java.util.ArrayList;
import java.util.List;
import java.lang.Math;


public class Main {

    private Database database;
    private static final boolean DEBUG = false;

    public Main() {
        this.database = new Database();
    }

    private class Database {

        public QueryResult query(String query) throws ConnectionException {
            return new QueryResult();
        }

        public QueryResult queryMore(int queryLocator) {
            return new QueryResult();
        }

    }

    private class QueryResult {
        
        public int getSize() {
            return 0;
        }

        public Row[] getRecords() {
            return new Row[1];
        }

        public boolean isDone() {
            return false;
        }

        public int getQueryLocator() {
            return -1;
        }

    }

    private class ConnectionException extends Exception {
        public static final long serialVersionUID = -1;
    }

    private class Row {

    }

    private class Book extends Row {

        private int id;
        private String title;
        private int year;
        private int numPages;
        
        public int getId() { return id; }
        public String getTitle() { return title; }
        public int getYear() { return year; }
        public int getNumPages() { return numPages; }

    }

    private class Booklist extends ArrayList {

        public boolean hasBestseller;
        public static final long serialVersionUID = -1;
        public List titles = new ArrayList();

    }

    public boolean isBestseller(int id) {
        return id == 42;
    }

    public Booklist getBooklist(String genre, int max_books) {

        Booklist booklist = new Booklist();
        List titles = new ArrayList();
        
        try {
        
            String query = "SELECT id, title, year, num_pages FROM table WHERE title LIKE '%" + genre + "%'";
            QueryResult queryResult = database.query(query);
            boolean finished = false;
            
            if (queryResult.getSize() > 0) {
                
                int rowNumber = 0;
                while (!finished) {
                
                    Row[] records = queryResult.getRecords();
                    
                    for (int i = 0; i < Math.min(records.length, max_books); ++i) {
                    
                        Book book = (Book)records[i];
                        int id = book.getId();
                        String title = book.getTitle();
                        int year = book.getYear();
                        int num_pages = book.getNumPages();
                        
                        if (title != null) {
                            titles.add(title);
                        }
                        if (id != -1) {
                            boolean bestseller = isBestseller(id);
                            if (bestseller) {
                                booklist.hasBestseller = bestseller;
                            }
                        }
                        
                        if (DEBUG) {
                            System.out.println("Fetched book: " + title + "(" + genre + ")");
                        }
                        
                        rowNumber++;
                        
                        if (queryResult.isDone() || rowNumber >= max_books) {
                            finished = true;
                        } else {
                            queryResult = database.queryMore(queryResult.getQueryLocator());
                        }

                    }
                 }       
            } else {
                System.out.println("Hello world!");
            }
        
        } catch (ConnectionException exception) {
            exception.printStackTrace();
        }
        
        booklist.titles = titles;
        return booklist;
        
    }

    public static void main(String[] args) {
        new Main().getBooklist("romance", 3);
    }

}
