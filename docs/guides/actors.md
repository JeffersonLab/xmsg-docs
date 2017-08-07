---
layout: doc_guide
group_id: guides
group_title: Guides
id: actors
title: Actors
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
