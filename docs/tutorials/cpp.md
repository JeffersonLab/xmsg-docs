---
layout: doc_lang
group_id: tutorials
group_title: Tutorials
id: cpp
title: C++
---

## Actors

In order to send and receive data, an actor for publishers and subscribers needs
to be created:

  Creating producer actor:<br>
    ```xmsg::xMsg producer = xmsg::xMsg("publisher");```<br>

  Creating consumer actor:<br>
    ```xmsg::xMsg consumer = xmsg::xMsg("subscriber");```<br>

These actor names will be used for all of the examples following.


## Proxy

A proxy needs to exist in order for the messages to be sent between publisher and
subscribers. After installation of xMsg, cx_proxy should be installed inside the
local bin directory:

  On Mac OSX:
  `/usr/local/bin/cx_proxy`

A proxy actor can also be crafted if it needs to perform specific actions.


## Creating connections

After creating these actor objects, the connections need to be created for each
actor. This is done with:

  Connection for the producer:<br>
    `xmsg::ProxyConnection connection = producer.connect(xmsg::util::to_host_addr("localhost"));`<br>

  Connection for the consumer:<br>
    `xmsg::ProxyConnection connection = consumer.connect(xmsg::util::to_host_addr("localhost"));`


## Messages

In order to send a message, the topic needs to be created first to send a message
with. To make a topic you can use:

  `auto topic = xmsg::Topic::build(domain, subject, type);`


Where the three parameters are strings specifying the domain, subject, and type
respectively. To then build the message you call:

  `xmsg::Message message = xmsg::make_message(topic, data);`


Topic is the object created above and data is the data being send in the message.

To receive messages, the subscriber needs to subscribe to a topic, specify a connection,
and specify a user callback. To specify these three requirements, the subscriber can
call:

  `auto sub = consumer.subscribe(topic, std::move(connection), user_callback);`


Where `user_callback` is an object containing the instructions of what to do with
the received message.

## User Callback

A user defined callback method needs to be created in order for the xMsg subscriber
to receive and process the data from the message. To read the data from the message,
the subscriber needs to parse the data from the serialized message. To do this,
the subscriber can call:

  `auto value = xmsg::parse_message<std::string>(msg);`


Where `msg` is the received message.
