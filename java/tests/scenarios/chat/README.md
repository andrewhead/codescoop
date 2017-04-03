# What is Basic Java Instant Messenger ?

A basic java application based on GUI and Sockets+Streams, made as a College mini-project.

# How to run IM:

1. Clone or download repo.
2. First, run ServerTest.java from IMServer project.
3. Then, run ClientTest.java from IMClient project.
4. Send and receive messages from Server to Client or vice versa.
5. Use "END" string in any of the windows to close Connection.

# Updates from Andrew Head

We changed these aspects of the code:

* Initialize both the client and server inside `Server.java`
* The client gets initialized within a new thread
* Change the client to automatically exit the JFrame when
    the socket is closed
* Change the client to send a message to the server whenever
    it has established contact
* Some whitespace and other minor changes in `Server.java`

## Generating the `chat-client.jar`

```bash
jar cvf chat-client.jar Client*.class
```
