import java.security.KeyStore;
import javax.net.ssl.*;
import java.security.cert.X509Certificate;

public class SmallScoop {

  public static void main(String[] args) {

    KeyStore ks = KeyStore.getInstance(KeyStore.getDefaultType());
    SSLContext context = SSLContext.getInstance("TLS");
    TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
    tmf.init(ks);
    X509TrustManager defaultTrustManager = (X509TrustManager) tmf.getTrustManagers()[0];
    SavingTrustManager tm = new SavingTrustManager(defaultTrustManager);
    context.init(null, new TrustManager[]{tm}, null);
    SSLSocketFactory factory = context.getSocketFactory();
    SSLSocket socket = (SSLSocket) factory.createSocket("woot.com", 443);

  }

  private static class SavingTrustManager implements X509TrustManager { ... }

    private final X509TrustManager tm;
    private X509Certificate[] chain;

    SavingTrustManager(X509TrustManager tm) {
      this.tm = tm;
    }

    public X509Certificate[] getAcceptedIssuers() {

      /**
      * This change has been done due to the following resolution advised for Java 1.7+
      http://infposs.blogspot.kr/2013/06/installcert-and-java-7.html
      **/

      return new X509Certificate[0];
      //throw new UnsupportedOperationException();
    }

    public void checkClientTrusted(X509Certificate[] chain, String authType)
    throws CertificateException {
      throw new UnsupportedOperationException();
    }

    public void checkServerTrusted(X509Certificate[] chain, String authType)
    throws CertificateException {
      this.chain = chain;
      tm.checkServerTrusted(chain, authType);
    }
  }

}
