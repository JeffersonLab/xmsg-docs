---
layout: doc_guide
title: Subscriptions
---

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

{: .note }
Regular expressions and wildcards are not supported. Only prefix matching.
For example, trying to select just the subject of any domain, `*:B`,
is not a valid subscription topic.

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

![]({{ site.baseurl }}/assets/images/ctrl-sub-req.png){: .align-center .zmqmsg }

If the request was successfully received,
the proxy will publish back another control message, with this format:

![]({{ site.baseurl }}/assets/images/ctrl-sub-ack.png){: .align-center .zmqmsg }

This message should be received by the `subSocket` if everything is working.
But if no message is received after 100 ms, the request will be published again.
After 10 unsuccessful attempts, an exception will be thrown
because the subscription could not be started.

{: .note }
Since the subscription will be checked before starting the background thread,
the `subscribe` method can block
several hundred of milliseconds waiting for a control message
to confirm that the subscription can receive messages.

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
