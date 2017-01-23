---
layout: tutorial
title: Java
---

## Actors

An xMsg *actor* is required to publish or subscribe messages.
Messages are identified by *topics*,
and contain *metadata* and *user serialized data*.
Multi-threaded publication of messages is supported.
Each thread must use its own *connection* to send messages.
Subscription always runs in a background thread.
Every received message is then sent to a *threadpool* of worker threads
that run a user-defined *callback* for each message.
This *callback* must be thread-safe.

A *proxy* must be running in order to pass messages between actors.
There may be many proxies running in a xMsg cloud,
but messages must be published to the same proxy than the subscription,
or the subscriber will not receive them.
There is no limitation on the number of proxies than an actor can be connected to.

Long-lived actors can register with a global *registrar service*
if they are periodically publishing messages to a given topic,
or subscribed to a given topic.
Others actors can search the registrar to discover them,
and receive or send messages to those topics.

To create an xMsg actor the following alternatives are provided:

```java
xMsg(String name)
xMsg(String name, int poolSize)
xMsg(String name, xMsgRegAddress defaultRegistrar)
xMsg(String name, xMsgRegAddress defaultRegistrar, int poolSize)
xMsg(String name, xMsgProxyAddress defaultProxy,
     xMsgRegAddress defaultRegistrar, int poolSize)
```

The constructor sets the **name** of the actor (used for registration)
and also generates a unique **ID** (to receive sync-publication responses).
The **default registrar** and **default proxy** addresses are optional
(if not given *localhost* and standard xMsg port are used).
The **default proxy** address should be used
for long-running publication or subscription of messages.
The actor can then register as a *publisher* or *subscriber*
on the **default registrar** service.
The **poolsize** controls how many threads will run subscription callbacks.

The constructor will also create a **connection pool** to manage *connections*,
a **threadpool** to process subscribed messages (using `poolSize` threads),
and a **poller thread** to receive sync-publication responses.

The `xMsg` class implements the `AutoCloseable` interface.
Closing the actor will close all connections,
stop all subscriptions and shutdown the callback threadpool.

```java
try (xMsg actor = new xMsg("name")) {
    // use the actor for pub/sub communications
}
```

## Messages

Actors communicate with others actors by publishing messages
to given **topics**, or named channels.
Subscribers can receive the messages published to the topics
to which they are interested, by subscribing to them.
The messages are not sent directly to another actor.
All actors subscribed to the topic of a published message will receive it.

### Raw message format

A message is sent through the wire as a ZMQ message composed of three frames:

![]({{ site.baseurl }}/img/raw-message.png){: .align-center .zmqmsg }

The **topic** frame is a 3-part string with the format:
`<DOMAIN>:<SUBJECT>:<TYPE>`,
where `<SUBJECT>` and `<TYPE>` parts are optional.
The topic is used by subscribers to filter messages of interest.
Topics are matched by prefix;
if the topic of the subscription is a prefix of the topic of the message
(or the same), the message will be received.

The **metadata** frame contains a serialized *protobuffer* with fields
that can be used to describe the data of the message.
At minimum, the metadata must have the `dataType` field set,
to indicate the *mime-type* of the binary payload.
The `byteOrder` field can be used to set the data endianness if needed.
The `communicationId` field can be used to track messages
by giving them a unique identification.

The **data** frame contains the binary representation
of the actual data of the message.
xMsg provides help to serialize primitive data types.
Complex objects must be serialized before creating the message.

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

## Connections

In order to publish or subscribe messages,
a connection to an xMsg **proxy** must be obtained.
Connections are managed by the xMsg actor,
that keeps an internal **connection pool** to cache and reuse connections.

<div class="admonition note">
The global `ZContext` wrapper is not used to keep a list of created sockets.
Thus, in order to destroy the context, all connections must be already
closed and the actor destroyed too,
otherwise the context will hang because some sockets are not closed yet.
</div>

### Connection fields

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

### Connection pool

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

### Creating connections

When the connection pool does not have a cached connection to the given proxy,
a new connection will be created.

The three sockets will be connected to the proxy address using the TCP protocol.
To check the connection, the `pubSocket` will publish a control message to the proxy,
with the following format:

![]({{ site.baseurl }}/img/ctrl-pub-req.png){: .align-center .zmqmsg }

If the request was successfully published,
the proxy will send to the `ctrlSocket` a message with this format
(note that the first frame will be stripped):

![]({{ site.baseurl }}/img/ctrl-pub-ack.png){: .align-center .zmqmsg }

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

## Publication

The xMsg actor presents a single method to publish messages:

```java
void publish(xMsgConnection connection, xMsgMessage message) throws xMsgException
```

The message will be serialized into ZMQ frames, sent to the connected proxy,
and delivered to all subscribers that match the topic of the message.

<div class="admonition note">
ZMQ does not send the raw message right away.
It will be stored on a queue to be sent by a background I/O thread.
If there are no subscribers for the topic,
the message will discarded silently, and not put on the queue.
</div>

To send messages to a given proxy,
a connection to the proxy must be obtained from the connection pool.
Actors can publish messages to as many proxies as required
by the topology of the application.

<div class="admonition note">
ZMQ "propagates" the subscriptions
as an special message that is delivered to every connected PUB socket.
Thus, it may take a while for a PUB socket to receive all subscriptions,
and a publisher may silently drop the first messages
due to not having the full information about subscriptions.
</div>

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

## Subscriptions

To receive messages,
an actor must **subscribe** to a **proxy** for a given **topic**.
If the topic of a message published to the proxy
matches the topic of the subscription, the actor will receive that message.

A *user-defined callback* must by provided in order to start the subscription.
The callback will run for every received message.
The actor runs callbacks of all subscriptions in a dedicated **threadpool**,
thus the callback must be thread-safe.

### Topic matching

The topics are matched by prefix.
For example, if the subscription topic is `A:B`,
the following table shows which topics are matched:

|**Message topic**|**Received**|**Message topic**|**Received**|
|:----------------|------------|:----------------|------------|
|`A`              |no          |`A:C`            |no          |
|`A:B`            |yes         |`A:C:D`          |no          |
|`A:B:L`          |yes         |`E`              |no          |
|`A:B:M`          |yes         |`M:R`            |no          |

<p></p>

<div class="admonition note">
Regular expressions and wildcards are not supported. Only prefix matching.
For example, trying to select just the subject of any domain, `*:B`,
is not a valid subscription topic.
</div>

### Starting the subscription

The xMsg actor presents a single call to start a subscription:

```java
xMsgSubscription subscribe(xMsgConnection connection,
                           xMsgTopic topic,
                           xMsgCallBack callback) throws xMsgException
```

xMsg convention is to subscribe to the *default proxy*.
Once the connection is successfully subscribed,
a **background thread** will be started to receive messages.
The method will return a **handler**
that can be used later to stop the thread and close the connection.
The background thread will take ownership of the connection,
which should not be reused or closed after the method returns.

The subscription is started by subscribing the `subSocket` to the given topic.
In order to check that the subscription is running,
the `pubSocket` will publish a control message to the proxy,
with the following format:

![]({{ site.baseurl }}/img/ctrl-sub-req.png){: .align-center .zmqmsg }

If the request was successfully received,
the proxy will publish back another control message, with this format:

![]({{ site.baseurl }}/img/ctrl-sub-ack.png){: .align-center .zmqmsg }

This message should be received by the `subSocket` if everything is working.
But if no message is received after 100 ms, the request will be published again.
After 10 unsuccessful attempts, an exception will be thrown
because the subscription could not be started.

<div class="admonition note">
Since the subscription will be checked before starting the background thread,
the `subscribe` method can block
several hundred of milliseconds waiting for a control message
to confirm that the subscription can receive messages.
</div>

The **background thread** simply runs a continuos loop
that periodically polls the `subSocket` for new ZMQ raw messages.
Every message will be unpacked into an `xMsgMessage` object
and passed as argument to the subscription **callback**.
Running the callback with the received message will be submitted
as a new task to be executed by the internal **threadpool**
of the subscribed actor.
Thus, the poller loop can continue receiving messages
while the previous messages are processed on the worker threads.

A single actor can be subscribed to many different topics
on many different proxies.
Each subscription will run on its own background thread,
but all of them will share the same threadpool to run the callbacks.
The size of the threadpool must be chosen
based on the number of subscriptions and the expected rate of messages.

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

<div class="admonition note">
Stopping the subscription will not remove or interrupt
the callbacks of the subscription that are still pending or running
in the internal threadpool.
</div>

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

## Synchronous Publication

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

<div class="admonition note">
In order to receive a response,
the subscription callback must support sync-publication
and publish response messages to the expected topic.
xMsg does not publish a response automatically.
</div>

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

### Publishing responses

To reply sync-publication messages,
the *user-defined* callback must explicitly support publication of responses.
xMsg will not reply synchronous requests automatically.
If the callback does not send a response,
the actor doing the `syncPublish` call will timeout.

A received message is a synchronous request if the `replyTo` metadata is set.
To reply this message,
the response must be published to the topic defined by the value of `replyTo`.
The `xMsgMessage` class provides methods to quickly access this metatada field:

```java
boolean     hasReplyTopic()
xMsgTopic   getReplyTopic()
```

Finally, the response message shall be published
to the same proxy used to start the subscription.
The xMsg convention is to subscribe to the *default proxy*.
If the wrong topic or proxy are used, the response will not be received.

```java
xMsgConnection connection = actor.getConnection(); // to default proxy
xMsgTopic topic = xMsgTopic.build("data", "power");
xMsgSubscription sub = actor.subscribe(connection, topic, msg -> {
    try {
        byte[] data = processMessage(msg);
        // check if message is a sync request
        if (msg.hasReplyTopic()) {
            xMsgTopic resTopic = msg.getReplyTopic();
            xMsgMessage resMsg = new xMsgMessage(resTopic, "binary/data", data);
            // publish response to default proxy (the same of subscription)
            try (xMsgConnection resCon = actor.getConnection()) {
                actor.publish(resCon, resMsg);
            }
        }
    } catch (Exception e) {
        e.printStacktrace();
    }
});
```

To quickly create response messages, for example,
returning the same input data or data of primitive type,
the following static methods are also provided:

```java
xMsgMessage createResponse(xMsgMessage msg)
xMsgMessage createResponse(xMsgMessage msg, Object data)
```

The response topic and mime-type will be set to the proper values.

## Registration/Discovery

If an actor is subscribed to a topic of interest,
or it is periodically publishing messages,
it can register with the xMsg registrar service
so others actors can discover them.

The registrar service must be running as a separate process
in some selected node. The actors define the address
of the *default registrar* during construction.

### Registering the actor with the registrar

To register the actor, the type of the registration
(publisher or subscriber),
the topic of interest and a description must be defined.
These parameters are encapsulated in the `xMsgRegInfo` class,
and the following factories are provided:

```java
xMsgRegInfo publisher(xMsgTopic topic, String description);
xMsgRegInfo subscriber(xMsgTopic topic, String description);
```

The registration methods shall receive the registration info,
and optionally the address of the registrar service,
and a custom timeout value.
xMsg convention is to register with the *default registrar* service.

```java
void register(xMsgRegInfo info)
void register(xMsgRegInfo info, xMsgRegAddress address)
void register(xMsgRegInfo info, xMsgRegAddress address, int timeout)
```

The actor must be publishing or subscribed to messages
if it is registered:

```java
try (xMsg publisher = new xMsg("publisher");
     xMsgConnection con = publisher.getConnection()) { // to default proxy
    xMsgTopic topic = xMsgTopic.build("report", "sports");
    publisher.register(xMsgRegInfo.publisher(topic, "sport reports"));
    while (keepRunning) {
        xMsgMessage msg = createReport(topic);
        publisher.publish(con, msg);
    }
} catch (xMsgException e) {
    e.printStackTrace();
}
```

The registration request will be sent to the registrar
as a *protobuffer* object with fields for the
**name**, **address**, **type**, **topic** and **description** of the actor
(see `xMsgRegistration`).
The *default proxy* will be registered as the address
where the actor is publishing or subscribed to.
There may be multiple actors registered to the same address and topic.

### Removing the actor from the registrar

To remove a previously registered actor,
the same registration parameters must be used
(publisher or subscriber, and topic):

```java
xMsgRegInfo publisher(xMsgTopic topic);
xMsgRegInfo subscriber(xMsgTopic topic);
```

Like registration methods,
deregistration shall receive the registration info,
and optionally the address of the registrar service,
and a custom timeout value.

```java
void deregister(xMsgRegInfo info)
void deregister(xMsgRegInfo info, xMsgRegAddress address)
void deregister(xMsgRegInfo info, xMsgRegAddress address, int timeout)
```

Obviously,
the address of the registrar must be the same one used for registration.

### Discovering registered actors

Actors can discover others registered actors that match a given query.
The registration information of those actors (**address** and **topic**),
can be used to publish or subscribe to messages of interest.

To discover registered actors, an `xMsgRegQuery` must be created,
encapsulating the search parameters.
The following factories are provided:

```java
xMsgRegQuery publishers(xMsgTopic topic);
xMsgRegQuery subscribers(xMsgTopic topic);
```

Currently, only topic-matching is supported.
More complex queries can be added on next releases.

As with registration methods,
discovery shall receive the registration query,
and optionally the address of the registrar service,
and a custom timeout value.

```java
Set<xMsgRegRecord> discover(xMsgRegQuery query)
Set<xMsgRegRecord> discover(xMsgRegQuery query, xMsgRegAddress address)
Set<xMsgRegRecord> discover(xMsgRegQuery query, xMsgRegAddress address, int timeout)
```

The registrar service will return the registration information
of all actors that match the query.
The actor will wrap the received `xMsgRegistration` data
with the `xMsgRegRecord` class,
that presents high-level methods to access the raw registration information.

Discovery requests can be used to check if there are actors
that can receive messages, or that are publishing expected messages.
The registered addresses can be used to publish or subscribe
the messages of interest:

```java
try (xMsg actor = new xMsg("actor")) {
    xMsgTopic topic = xMsgTopic.build("report", "sports");
    xMsgRegQuery query = xMsgRegQuery.subscribers(topic);
    Set<xMsgRegRecord> subscribers = actor.discover(query);
    for (xMsgRegRecord sub : subscribers) {
        try (xMsgConnection con = actor.getConnection(sub.address())) {
            xMsgMessage msg = createMessage(topic);
            actor.publish(con, msg);
        }
    }
} catch (xMsgException e) {
    e.printStackTrace();
}
```

### Topic matching

The discovery queries will match registered actors by topic
using different rules for publishers and subscribers.

If the query is all **subscribers** of the topic `A:B`,
all actors that would receive a message of topic `A:B`
will be matched:

|**Subscriber topic**|**Matched**|**Subscriber topic**|**Matched**|
|:-------------------|-----------|:-------------------|-----------|
|`A`                 |yes        |`A:C`               |no         |
|`A:B`               |yes        |`A:C:D`             |no         |
|`A:B:L`             |no         |`E`                 |no         |
|`A:B:M`             |no         |`M:R`               |no         |

If the query is all **publishers** of the topic `A:B`,
all publishers of messages that would be received
by a subscription to `A:B`
will be matched:

|**Publisher topic**|**Matched**|**Publisher topic**|**Matched**|
|:------------------|-----------|:------------------|-----------|
|`A`                |no         |`A:C`              |no         |
|`A:B`              |yes        |`A:C:D`            |no         |
|`A:B:L`            |yes        |`E`                |no         |
|`A:B:M`            |yes        |`M:R`              |no         |

## Scripts

xMsg provides two wrappers scripts to launch the **proxy**
and the **registrar** processes.

To launch the proxy:

```
$ jx_proxy
```

To launch the registrar:

```
$ jx_registrar
```

Both scripts can accept custom settings for the IP address and port
that shall be used.

The proxy and the registrar can also be instantiated from a Java program.
See the `xMsgProxy` and `xMsgRegistrar` classes.
Note that a new `ZContext` must be created,
and destroyed before stopping the services.
