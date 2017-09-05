import com.sun.mail.smtp.SMTPTransport;

import org.apache.commons.lang.Validate;
import org.apache.commons.lang.StringUtils;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.Jsoup;
import org.jsoup.select.Elements;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.net.URL;
import java.net.URLEncoder;
import java.security.Security;
import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.Properties;

import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Session;
import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

/**
 * Example program to list links from a URL.
 */
public class CraigslistMonitor {

    public static void main(String[] args) throws IOException, MessagingException, AddressException {

        if (args.length < 2) {
          args = new String[]{"electric bike", "openairandrew@gmail.com"};
        }

        List titles = new ArrayList();
        List prices = new ArrayList();
        List links = new ArrayList();

        String query = URLEncoder.encode(args[0], "utf-8");
        String destination = args[1];
        URL url = new URL("https://sfbay.craigslist.org/search/bia?query=" + query);
        System.out.println("Fetching " + url.toExternalForm() + "...");

        Document doc = Jsoup.parse(url, 3*1000);
        Elements rows = doc.select("li.result-row");
        System.out.println(url);

        for (Iterator rowsIterator = rows.iterator(); rowsIterator.hasNext();) {

            Element row = (Element) rowsIterator.next();

            String price = row.select("span.result-meta span.result-price").text();
            int priceInt = -1;
            if (!price.equals("")) {
                priceInt = Integer.parseInt(price.replaceFirst("\\$", ""));
            }
            prices.add(new Integer(priceInt));

            Element image = row.select("a.result-image.gallery").get(0);
            String link = image.attr("abs:href");
            links.add(link);

            String title = row.select("a.result-title.hdrlnk").text();
            titles.add(title);

            if (titles.size() >= 5) break;
        }

        int maxTitleLength = 0;
        int maxPriceLength = 0;
        int maxLinkLength = 0;
        for (int i = 0; i < titles.size(); i++) {
            String titleLine = (String) titles.get(i);
            if (titleLine.length() > maxTitleLength) {
                maxTitleLength = titleLine.length();
            }
            int priceLine = ((Integer) prices.get(i)).intValue();
            if (Integer.toString(priceLine).length() > maxPriceLength) {
                maxPriceLength = Integer.toString(priceLine).length();
            }
            String linkLine = (String) links.get(i);
            if (linkLine.length() > maxLinkLength) {
                maxLinkLength = linkLine.length();
            }
        }

        String messageHtml = "<code>";
        for (int j = 0; j < titles.size(); j++) {
            String titleText = (String) titles.get(j);
            String priceText = ((Integer) prices.get(j)).toString();
            String linkText = (String) links.get(j);
            String titlePadded = titleText + StringUtils.repeat(" ", maxTitleLength - titleText.length());
            String pricePadded = priceText + StringUtils.repeat(" ", maxPriceLength - priceText.length());
            String linkPadded = linkText + StringUtils.repeat(" ", maxLinkLength - linkText.length());
            messageHtml += ("( $" + pricePadded + " ) " + titlePadded + "<br/>" + linkPadded + "<br/><br/>");
        }
        messageHtml += "</code>";

        BufferedReader confReader = new BufferedReader(new FileReader("/etc/smtp.conf"));
        String username = confReader.readLine();
        String password = confReader.readLine();
        System.out.println("Logging in with " + username + ", " + password);

        Security.addProvider(new com.sun.net.ssl.internal.ssl.Provider());
        String sslFactoryClass = "javax.net.ssl.SSLSocketFactory";

        Properties properties = System.getProperties();
        properties.setProperty("mail.smtps.host", "smtp.gmail.com");
        properties.setProperty("mail.smtp.socketFactory.class", sslFactoryClass);
        properties.setProperty("mail.smtp.port", "587");
        properties.setProperty("mail.smtp.socketFactory.port", "587");
        properties.setProperty("auth", "true");
        properties.put("mail.smtps.quitwait", "false");

        Session session = Session.getInstance(properties, null);

        MimeMessage message = new MimeMessage(session);
        message.setFrom(new InternetAddress(username));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(destination, false));
        message.setSubject("Update of Craigslist posts");
        message.setText(messageHtml, "utf-8", "html");
        message.setSentDate(new Date());

        SMTPTransport transport = (SMTPTransport) session.getTransport("smtps");
        transport.connect("smtp.gmail.com", username, password);
        transport.sendMessage(message, message.getAllRecipients());
        transport.close();
    }
}
