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


## Payloads

To create a payload for xMsg, first create the object with:

  `xmsg::proto::Payload payload;`

After creating the object, you can begin to add items to the object to store. Payload
has a method called `add_item()`, which adds a new item to the payload and returns
a pointer to the new item. Making a call similar to this would give you a pointer
to the item:

  `xmsg::proto::Payload_Item* item = payload.add_item();`

Now `item` is a pointer to a newly added item to the payload. Using this pointer,
you can set the item name and the data for the item. The data is a pointer inside
`item` accessible with `mutable_data()`.

To read a Payload from a message, first create a buffer object with the data from
the message:

  `const std::vector<std::uint8_t>& buffer = msg.data();`


Then take the buffer object created, and use xmsg::proto::Payload's `ParseFromArray`:

  `payload.ParseFromArray(buffer.data(), buffer.size());`


To send a payload, you first need to serialize the payload before you can create
a message containing it. To serialize the payload, you first want to create a buffer
object:

  `auto buffer = std::vector<std::uint8_t>(payload.ByteSize());`


Then you need to serialize the payload:

  `payload.SerializeToArray(buffer.data(), buffer.size());`


Then return the buffer. After creating the buffer containing a serialized payload,
you can begin to craft the message. Create a method receiving a topic and the
payload to return the signature of an xMsg message:

  ```
  xmsg::Message payload_message(xmsg::Topic topic, const xmsg::proto::Payload payload) {
      auto buffer = serialize_payload(payload);
      return {topic, xmsg::mimetype::xmsg_data, std::move(buffer)};
  }
  ```


After creating this method, you can call it to create the message:

  `message = payload_message(topic, payload);`
