import org.acme.database.Cursor;
import org.acme.database.Database;
import org.acme.database.ConnectionException;


public class FetchColumnSlice {

  public static void main(String[] args) {

    String genre = "romance";
    String QUERY = "SELECT id, title, year, num_pages FROM table WHERE title LIKE '%" + genre + "%'";
    int COLUMN_INDEX_TITLE = 1;
    Database database = new Database("lou", "PA$$W0RD", "https://acme-books.com/db");
    Cursor cursor = database.cursor();
    try {
      cursor.execute(QUERY);
      cursor.fetchone();
      String title = cursor.getString(COLUMN_INDEX_TITLE);
    } catch (ConnectionException exception) {}

  }

}
