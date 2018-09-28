---
title: Connections
---

In order to publish or subscribe messages,
a connection to an xMsg **proxy** must be obtained.
Connections are managed by the xMsg actor,
that keeps an internal **connection pool** to cache and reuse connections.

{: .note }
The global `ZContext` wrapper is not used to keep a list of created sockets.
Thus, in order to destroy the context, all connections must be already
closed and the actor destroyed too,
otherwise the context will hang because some sockets are not closed yet.

## Connection fields

Each connection contains the address of the proxy and three ZMQ sockets:

-   `pubSocket` (PUB): socket used for publication of messages
-   `subSocket` (SUB): socket used to received subscribed messages
-   `ctrlSocket` (DEALER): socket used internally to send and receive control messages

The `ctrlSocket` is used to verify that the connection to the proxy is
established.

A 9-digit unique ID is generated for each new connection,
with the following format: `LPPPRRRRR`.
The first digit is the language (1 for Java, 2 for C++, 3 for Python),
`PPP` is a 3-digit prefix unique to the node,
and `RRRRR` is a 5-digit random number between 0 and 99999.

This ID is required to register the `ctrlSocket` with the proxy
(ZMQ uses an identity per socket for REQ/REP communications).

## Connection pool

To get a connection from the connection pool, a **proxy address** is required.
The connection pool keeps a set of cached connections.
If a connection to the proxy already exists, it will be returned.
Otherwise, a new one will be created.
Multiple threads can access the pool at the same time.
Each thread will receive its own connection.

Connections should be closed in order to return them to the connection pool,
so it can be reused by other publishing threads.
The `try-with-resources` block is the preferred way to obtain and use a
connection:

```java
try (xMsgConnection connection = actor.getConnection(proxyAddress)) {
    // use the connection
} catch (xMsgException e) {
    e.printStacktrace();
}
```

The actor must be destroyed in order to close all connections cached in the
connection pool.

## Creating connections

When the connection pool does not have a cached connection to the given proxy,
a new connection will be created.

The three sockets will be connected to the proxy address using the TCP protocol.
To check the connection, the `pubSocket` will publish a control message to the proxy,
with the following format:

![]({{ site.baseurl }}/assets/images/ctrl-pub-req.png){: .align-center .zmqmsg }

If the request was successfully published,
the proxy will send to the `ctrlSocket` a message with this format
(note that the first frame will be stripped):

![]({{ site.baseurl }}/assets/images/ctrl-pub-ack.png){: .align-center .zmqmsg }

If no response is received after 100 ms, the request will be published again.
After 10 unsuccessful requests, an exception will be thrown
because the proxy could not be connected.

New connections can be customized by providing a **connection setup**:

```java
public class CustomSetup implements xMsgConnectionSetup {
    @override
    public void preConnection(Socket socket) {
        // set options before the ZMQ socket is connected
    }
    @override
    public void postConnection() {
        System.out.println("Successfully connected");
    }
}

actor.setConnectionSetup(new CustomSetup());
```

The setup will be used each time a new connection is created.
