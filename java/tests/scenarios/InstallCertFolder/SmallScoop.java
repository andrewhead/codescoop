import javax.net.ssl.*;

public class SmallScoop {

  private static class Tm {

    public AnonymousClass1 chain = new AnonymousClass1();

    public AnonymousClass2 checkServerTrusted(java.security.cert.X509Certificate[] arg1, java.lang.String arg2) {
      return null;
    }

    public AnonymousClass3 getAcceptedIssuers() {
      return new AnonymousClass3();
    }

  }

  private static class AnonymousClass1 {
  }

  private static class AnonymousClass3 {
  }

  public static void main(String[] args) {

    SSLContext context = SSLContext.getInstance("TLS");
    context.init(null, new TrustManager[]{(new Tm())}, null);
    SSLSocketFactory factory = context.getSocketFactory();
    SSLSocket socket = (SSLSocket) factory.createSocket("woot.com", 443);
    socket.setSoTimeout(10000);
    socket.startHandshake();
    socket.startHandshake();
    socket.close();

  }

}
