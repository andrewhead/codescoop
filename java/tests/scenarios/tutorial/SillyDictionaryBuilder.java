import java.util.Random;
import java.util.ArrayList;
import java.util.List;
import java.util.Iterator;
import java.io.IOException;
import java.io.PrintWriter;


public class SillyDictionaryBuilder {

  public static void main(String[] args) throws IOException {

      int MIN_ASCII_CHARACTER = 65;
      int ALPHABET_LENGTH = 26;
      int WORD_LENGTH = 8;
      int NUM_WORDS = 30;

      List words = new ArrayList();

      Random randomGenerator = new Random();
      for (int w = 0; w < NUM_WORDS; w++) {
        StringBuffer buffer = new StringBuffer();
        for (int c = 0; c < WORD_LENGTH; c++) {
          int asciiCode = MIN_ASCII_CHARACTER + randomGenerator.nextInt(ALPHABET_LENGTH);
          char character = (char) asciiCode;
          buffer.append(Character.toString(character));
        }
        String word = new String(buffer);
        words.add(word);
      }

      System.out.println("Saving the dictionary to file...");
      PrintWriter writer = new PrintWriter("output.txt", "UTF-8");
      for (Iterator iterator = words.iterator(); iterator.hasNext();) {
        String currentWord = (String) iterator.next();
        System.out.println("Saving word:" + currentWord);
        writer.println(currentWord);
      }
      writer.close();
  }

}
