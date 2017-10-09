---
layout: doc_tutorial
title: Java
---


### Creating messages

To construct a message,
the topic, the metadata and the serialized data are needed:

```java
xMsgMessage(xMsgTopic topic, xMsgMeta.Builder metaData, byte[] data)
xMsgMessage(xMsgTopic topic, String mimeType, byte[] data)
```

An overload with just the *mime-type* is provided for simple messages
when there is no need to set other metadata fields.
Without the *mime-type* the message will be malformed
and it will not be published.

The data in the message is always a byte array.
xMsg does not do serialization of user defined data.

```java
// Set the topic
xMsgTopic topic = xMsgTopic.build("domain", "subject", "type");

// Set the metadata
xMsgMeta.Builder meta = xMsgMeta.newBuilder();
meta.setDataType("binary/type");
meta.setByteOrder(xMsgMeta.Endian.Little);
meta.setCommunicationId(666);

// The data of the message
SomeType value = new SomeType();
byte[] data = SomeType.serialize(value);

// Create the message
xMsgMessage msg = new xMsgMessage(topic, meta, data);
```

For primitives and arrays of primitives,
a *protobuffer* container class is provided
to store and serialize the data:

```java
xMsgData.Builder builder = xMsgData.newBuilder();
builder.setFLSINT32(100);
builder.setDOUBLE(4.5);
builder.addAllDOUBLEA(Arrays.asList(4.4, 5.6, 2.1));
byte data = builder.build().toByteArray();
```

To help creating simple messages, a static method can serialize
primitives, arrays of primitives or Java objects:

```java
xMsgMessage createFrom(xMsgTopic topic, Object data)
```

In this case, the data will be stored and serialized
in *protobuffer* format (see `xMsgData`),
and the *mime-type* will be set to the proper predefined value
(see `xMsgMimeType`).

```java
xMsgMessage msg1 = xMsgMessage.createFrom(topic, 200});
xMsgMessage msg2 = xMsgMessage.createFrom(topic, new Double[] { 3, 4, 5});
xMsgMessage msg3 = xMsgMessage.createFrom(topic, "string data");

assert msg1.getMimeType().equals(xMsgMimeType.SFIXED32);
assert msg2.getMimeType().equals(xMsgMimeType.ARRAY_DOUBLE);
assert msg3.getMimeType().equals(xMsgMimeType.STRING);
```

### Reading messages

To read the data of a message, the *mime-type* must be checked first.
If the type is known, the data can be deserialized:

```java
Type data = null;
if (msg.getMimeType().equals("binary/type")) {
    byte[] bb = msg.getData();
    data = Type.deserialize(bb);
}
```

Or if the byte order matters:

```java
Type data = null;
if (msg.getMimeType().equals("binary/type")) {
    byte[] bb = msg.getData();
    ByteOrder order = msg.getDataOrder();
    data = Type.deserialize(bb, order);
}
```

When the data type is a primitive, arrays of primitives or Java object,
a static helper method can parse the data from the message:

```java
<T> T parseData(xMsgMessage msg, Class<T> dataType)
```

The *mime-type* will be used to check
if the message contains data of the expected type.
Primitives and arrays of primitives
should have been serialized as *protobuffer* format.
The `createFrom` method can help with that.

```java
Integer intData = xMsgMessage.parseData(msg, Integer.class);
Double[] arrayData = xMsgMessage.parseData(msg, Double[].class);
String stringData = xMsgMessage.parseData(msg, String.class);
JavaType objectData = (JavaType) xMsgMessage.parseData(msg);
```

### Creating connections

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

### Publication

The xMsg actor presents a single method to publish messages:

```java
void publish(xMsgConnection connection, xMsgMessage message) throws xMsgException
```

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

### Subscriptions


The xMsg actor presents a single call to start a subscription:

```java
xMsgSubscription subscribe(xMsgConnection connection,
                           xMsgTopic topic,
                           xMsgCallBack callback) throws xMsgException
```


### User-defined callbacks

The callback interface presents a single method,
that receives a message that matches the topic of the subscription:

```java
public interface xMsgCallBack {
    void callback(xMsgMessage msg);
}
```

Lambda functions can be used to write simple callbacks:

```java
xMsgConnection connection = actor.getConnection();
xMsgTopic topic = xMsgTopic.build("data", "cars");
xMsgSubscription sub = actor.subscribe(connection, topic, msg -> {
    System.out.println("Received: " + xMsgMessage.parseData(msg, String.class));
});
```

For each received message on the subscription,
the callback will run with the message as the argument.
Callbacks do not run as soon as the messages are received;
they are submitted to be executed by the worker threads
of the internal threadpool, when a thread is available.

Since the actual callback object is created once per subscription,
the same callback may be executed simultaneously by many worker threads
to process multiple received messages.
Therefore, any *user-defined callback* shall be
[thread-safe](http://www.ibm.com/developerworks/library/j-jtp09263):

```java
class ThreadSafeAccumulator implements xMsgCallBack {

    private AtomicInteger sum = new AtomicInteger();

    @Override
    public void callback(xMsgMessage msg) {
        sum.addAndGet(xMsgMessage.parseData(msg, Integer.class));
    }

    public int getSum() {
        return sum.get();
    }
}

xMsgConnection connection = actor.getConnection();
xMsgTopic topic = xMsgTopic.build("data", "numbers", "integers");
ThreadSafeAccumulator callback = new ThreadSafeAccumulator();
xMsgSubscription sub = actor.subscribe(connection, topic, callback);
```

The actor can also be used inside the callback to publish new messages.
This allows writing complex interactions between actors
--- like service-oriented architectures,
where services send data to other services to process a request.
The connections must be obtained *inside* the callback,
and closed after publishing:

```java
xMsgConnection connection = actor.getConnection();
xMsgTopic topic = xMsgTopic.build("data", "power");

xMsgSubscription sub = actor.subscribe(connection, topic, msg -> {
    try {
        Object result = processMessage(msg);

        xMsgTopic pubTopic = xMsgTopic.build("result", "data");
        xMsgTopic logTopic = xMsgTopic.build("result", "log");
        xMsgProxyAddress pubAddr = selectAddress(result);
        xMsgProxyAddress logAddr = getLogAddress();

        try (xMsgConnection pubCon = actor.getConnection(pubAddr);
            xMsgConnection logCon = actor.getConnection(logAddr)) {
            xMsgMessage pubMsg = createMessage(pubTopic, result);
            xMsgMessage logMsg = createLogMessage(logTopic, result);
            actor.publish(pubCon, pubMsg); // publish to proxy 1
            actor.publish(logCon, logMsg); // publish to proxy 2
        }
    } catch (Exception e) {
        e.printStacktrace();
    }
});
```

### Stopping subscriptions

To stop a subscription, the subscription **handler** is required:

```java
void unsubscribe(xMsgSubscription handler)
```

The background thread will stop receiving messages,
the `subSocket` will be unsubscribed to the topic,
and the connection will be closed.

{: .note }
Stopping the subscription will not remove or interrupt
the callbacks of the subscription that are still pending or running
in the internal threadpool.

All active subscriptions will also be closed when the actor is destroyed.

Since the subscriptions run in background threads,
there must be a main thread that is kept alive while subscriptions are active.
Otherwise the actor will be closed, all subscriptions will be stopped and the
program will finish.

```java
private static volatile boolean keepRunning = true;

public static void main(String[] argv) {
    try (xMsg subscriber = new xMsg("subscriber")) {
        xMsgTopic topic = xMsgTopic.build("report", "sports");
        xMsgConnection connection = subscriber.getConnection();
        subscriber.subscribe(connection, topic, msg -> processMessage(msg));
        // keep subscription running until another threads cancels it
        while (keepRunning) {
            xMsgUtil.sleep(100);
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

### Synchronous Publication

xMsg supports publishing a message and receiving a response,
with the following method:

```java
xMsgMessage syncPublish(xMsgConnection connection, xMsgMessage msg, int timeout)
        throws xMsgException, TimeoutException
```

This publishes the message just like the `publish` method,
but this time the *metadata* is modified with a unique `replyTo` field.
Then the method will block until a response message is received
or the timeout occurs, whichever happens first.

{: .note }
In order to receive a response,
the subscription callback must support sync-publication
and publish response messages to the expected topic.
xMsg does not publish a response automatically.

As with normal publication,
the xMsg actor can sync-publish messages on multiples threads,
but each thread must obtain its own connection.

```java
executor.submit(() -> {
    try (xMsgConnection con = actor.getConnection()) {
        xMsgMessage msg = createMessage();
        xMsgMessage res = actor.syncPublish(con, msg, 10000);
        process(res);
    } catch (xMsgException | TimeoutException e) {
        e.printStacktrace();
    }
});
```

### Receiving responses

When a message is sync-published,
its metadata will be modified to contain a unique `replyTo` field.
This value is generated by the actor for each sync-published message,
and correspond to the topic that can be used by the subscription
to publish a response message.

The format of the `replyTo` topic is: `ret:<ID>:LDDDDDD`.
The `<ID>` is the unique identifier of the actor,
generated on the constructor.
`L` is the language (1 for Java, 2 for C++, 3 for Python),
and `DDDDDD` is a 6-digit serial number between 0 and 999999,
different for each message.
When 999999 is reached, it starts from 0 again.
This unique `replyTo` value per message ensures that the response can be
matched with the sync-publication call that published the request.

In order to receive the response message,
the actor must have a subscription
to the proxy where the response will be published.
To avoid creating a new subscription every time a sync message is sent,
only a single subscription per proxy will be created,
with topic: `ret:<ID>`.
This subscription will be running on background because
it will be reused to receive the responses
of all sync-publication requests to that proxy:

```java
if no response socket to address:
    create socket to address
    subscribe socket to "ret:<ID>"
set reply topic to "ret:<ID>:<SEQ>"
publish msg
wait response
```

Since response messages are received in a different thread,
a concurrent map is used to pass messages
to the waiting threads that sync-published those requests,
with the unique `replyTo` topic as the key:

```java
ConcurrentMap<Topic, Message> responses
```

Waiting a response is just checking the map periodically
for a message with topic equals to `replyTo`,
until the map contains the expected message or timeout occurs.

The actor may have multiple response subscriptions, to many proxies.
Unlike *user-defined* subscriptions (each one on its own thread),
only a single background **poller thread** checks response messages
in all subscribed sockets:

```java
while true:
    poll all sockets
    for each socket:
        if socket contains message
            put message on responses map
```

This poller thread is started on the xMsg constructor,
but every socket is created and subscribed the first time
a message is sync-published to a proxy.

