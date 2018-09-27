---
title: Publications
---

## Publications

The xMsg actor presents a single method to publish messages:

```java
void publish(xMsgConnection connection, xMsgMessage message) throws xMsgException
```

The message will be serialized into ZMQ frames, sent to the connected proxy,
and delivered to all subscribers that match the topic of the message.

{: .note }
ZMQ does not send the raw message right away.
It will be stored on a queue to be sent by a background I/O thread.
If there are no subscribers for the topic,
the message will discarded silently, and not put on the queue.

To send messages to a given proxy,
a connection to the proxy must be obtained from the connection pool.
Actors can publish messages to as many proxies as required
by the topology of the application.

{: .note }
ZMQ "propagates" the subscriptions
as an special message that is delivered to every connected PUB socket.
Thus, it may take a while for a PUB socket to receive all subscriptions,
and a publisher may silently drop the first messages
due to not having the full information about subscriptions.

For short publication tasks, the connection should be returned to the pool,
to be reused by others threads:

```java
try (xMsgConnection connection = actor.getConnection(proxyAddress)) {
    xMsgMessage message = createMessage();
    actor.publish(connection, message);
} catch (xMsgException e) {
    e.printStacktrace();
}
```

If the connections are never returned to the pool,
new connections will be created each time `getConnection` is called,
which can affect performance.

The xMsg actor can publish messages on multiples threads,
but each thread must obtain its own connection.

```java
try (xMsg actor = new xMsg("multithread-publisher")) {
    xMsgTopic topic = xMsgTopic.build("report");
    ExecutorService es = Executors.newCachedThreadPool();
    for (int i = 0; i < 8; i++) {
        es.submit(() -> {
            try (xMsgConnection connection = actor.getConnection()) {
                String data = longRunningTask();
                xMsgMessage msg = xMsgMessage.createFrom(topic, data);
                actor.publish(connection, msg);
            } catch (xMsgException e) {
                e.printStacktrace();
            }
        });
    }
    es.shutdown();
    es.awaitTermination(2, TimeUnit.MINUTES);
}
```

If the actor is just doing a few long-running publication tasks,
each one to the same proxy,
there is no need to return the connections to the pool:

```java
try (xMsgConnection connection = actor.getConnection(proxyAddress)) {
    while (keepRunning) {
        actor.publish(connection, generateMessage());
    }
}
```

Closing the actor and exiting the JVM will not send all messages still on queue.
If those messages should be delivered, the global ZMQ context should be
destroyed.

```java
public static void main(String[] argv) {
    try (xMsg publisher = new xMsg("publisher");
         xMsgConnection con = publisher.getConnection()) {
        xMsgTopic topic = xMsgTopic.build("report", "sports");
        for (int i = 0; i < 100000; i++) {
            xMsgMessage msg = createReport(topic);
            publisher.publish(con, msg);
        }
    } catch (xMsgException e) {
        e.printStackTrace();
    }
    // wait until all messages are published by ZMQ
    xMsgContext.destroyContext();
}
```
