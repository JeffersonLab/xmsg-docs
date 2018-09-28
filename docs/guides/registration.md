---
title: Registration/Discovery
---

If an actor is subscribed to a topic of interest,
or it is periodically publishing messages,
it can register with the xMsg registrar service
so others actors can discover them.

The registrar service must be running as a separate process
in some selected node. The actors define the address
of the *default registrar* during construction.

## Registering the actor with the registrar

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

## Removing the actor from the registrar

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

## Discovering registered actors

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

## Topic matching

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
