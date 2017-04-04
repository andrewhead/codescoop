import org.acme.database.Book;
import org.acme.database.Booklist;
import org.acme.database.Cursor;
import org.acme.database.Database;
import org.acme.database.ConnectionException;

import java.util.ArrayList;
import java.util.List;


public class BookListing {

    private boolean DEBUG = true;

    public Booklist getBookListing(String genre, int maxBooks) {

        Database database = new Database("https://acme-books.com/db");
        Cursor cursor = database.cursor();
        Booklist booklist = new Booklist();
        List titles = new ArrayList();

        try {

            String query = "SELECT id, title, year, num_pages FROM table WHERE title LIKE '%" + genre + "%'";
            cursor.execute(query);
            boolean finished = false;

            if (cursor.rowCount() > 0) {

                int rowNumber = 0;
                while (!finished) {

                    int rowCount = cursor.rowCount();

                    for (int i = 0; i < Math.min(rowCount, maxBooks); ++i) {

                        cursor.fetchone();
                        int id = cursor.getInt(0);
                        String title = cursor.getString(1);
                        int year = cursor.getInt(2);
                        int num_pages = cursor.getInt(3);
                        Book book = new Book(id, title, year, num_pages);

                        if (title != null) {
                            titles.add(title);
                        }
                        if (id != -1) {
                            boolean bestseller = isBestseller(book.getId());
                            if (bestseller) {
                                booklist.hasBestseller = bestseller;
                            }
                        }

                        if (DEBUG) {
                            System.out.println("Fetched book: " + title + " (" + genre + ")");
                        }

                        rowNumber++;

                        if (cursor.end() || rowNumber >= maxBooks) {
                            finished = true;
                        } else if (i == rowCount - 1){
                            cursor.next(id);
                        }

                    }
                 }
            } else {
                System.out.println("No results found in the database");
            }

        } catch (ConnectionException exception) {
            exception.printStackTrace();
        }

        booklist.titles = titles;
        return booklist;

    }

    public boolean isBestseller(int id) {
        return id == 2;
    }

    public static void main(String[] args) {
        new BookListing().getBookListing("romance", 3);
    }

}
