---
layout: sw_ipc
title: IPC implementation details
---

## Code structure

In the `src` directory, two files called `pub.cpp` and `sub.cpp` contain
implementations of the `ipc_lib.h` header file. In order for these to transmit data
between the two actors, a proxy needs to be running. The `cx_proxy` found in
`/usr/local/bin/` after correct installation of xMsg is all you need for this
example.

The two files, `pub.cpp` and `sub.cpp`, contain calls to the header file in their
main functions that create the respective xMsg actors. To build these files
follow the build instructions in the README. GCC 4.9+ and CMake 3.1+ is required
to build. After running the CMake file, start `cx_proxy` and the pub / sub
executables that were made after building the project.

When running, these two actors should be sending / receiving a simple "Hello
World" message. To demonstrate the advantages of xMsg, try killing one of the
actors and then restarting it. The actor should immediately reconnect and
continue working.

### Expanding on the example

The example contains a publisher that executes the `run()` method from the IpcProducer
class in the header. The while loop is then terminated and in the `pub.cpp` class
an example of the overloaded operator `<<` is used to demonstrate how to write to
the publisher's message field. This can be used to send different types of data to
the subscriber. After using the `<<` operator, the method `sendMsg()` is called to send
the message.

Using what has been given in this simple 'Hello World!' example, the two example classes
can be expanded out to meet the needs of the user. The basic method calls to send data
and write data to send can be found in the `pub.cpp` class, and the basic methods to
start a receiver can be found in the `sub.cpp` class. To alter how the data is handled
when received, the UserCallback in the header file can be changed.


## Actors

In order to send and receive data, an actor for publishers and subscribers needs
to be created:

Creating producer actor:

```cpp
xmsg::xMsg producer = xmsg::xMsg("publisher");
```

Creating consumer actor:
```cpp
xmsg::xMsg consumer = xmsg::xMsg("subscriber");
```

These actor names will be used for all of the examples following.

### Proxy

A proxy needs to exist in order for the messages to be sent between publisher and
subscribers. After installation of xMsg, cx_proxy should be installed inside the
local bin directory:

On Mac OSX:
```
/usr/local/bin/cx_proxy
```

A proxy actor can also be crafted if it needs to perform specific actions.


## Creating connections

After creating these actor objects, the connections need to be created for each
actor. This is done with:

Connection for the actor:
```cpp
xmsg::ProxyConnection connection = ACTOR.connect(xmsg::util::to_host_addr("localhost"));
```


## Messages

In order to send a message, the topic needs to be created first to send a message
with. To make a topic you can use:

```cpp
auto topic = xmsg::Topic::build(domain, subject, type);
```

Where the three parameters are strings specifying the domain, subject, and type
respectively. To then build the message you call:

```cpp
xmsg::Message message = xmsg::make_message(topic, data);
```

Topic is the object created above and data is the data being send in the message.

To receive messages, the subscriber needs to subscribe to a topic, specify a connection,
and specify a user callback. To specify these three requirements, the subscriber can
call:

```cpp
auto sub = consumer.subscribe(topic, std::move(connection), user_callback);
```

Where `user_callback` is an object containing the instructions of what to do with
the received message.


## User Callback

A user defined callback method needs to be created in order for the xMsg subscriber
to receive and process the data from the message. To read the data from the message,
the subscriber needs to parse the data from the serialized message. To do this,
the subscriber can call:
```cpp
auto value = xmsg::parse_message<std::string>(msg);
```

Where `msg` is the received message.


## Payloads

To create a payload for xMsg, first create the object with:
```cpp
xmsg::proto::Payload payload;
```

After creating the object, you can begin to add items to the object to store. Payload
has a method called `add_item()`, which adds a new item to the payload and returns
a pointer to the new item. Making a call similar to this would give you a pointer
to the item:
```cpp
xmsg::proto::Payload_Item* item = payload.add_item();
```

Now `item` is a pointer to a newly added item to the payload. Using this pointer,
you can set the item name and the data for the item. The data is a pointer inside
`item` accessible with `mutable_data()`.

Items from payloads can be named and given data. To set the name of a payload item:
```cpp
item->set_name("test");
```

In order to set the data for a payload item, use:
```cpp
item->mutable_data()->CopyFrom(data);
```

To read a Payload from a message, first create a buffer object with the data from
the message:
```cpp
const std::vector<std::uint8_t>& buffer = msg.data();
```

Then take the buffer object created, and use xmsg::proto::Payload's `ParseFromArray`:
```cpp
payload.ParseFromArray(buffer.data(), buffer.size());
```

To send a payload, you first need to serialize the payload before you can create
a message containing it. To serialize the payload, you first want to create a buffer
object:
```cpp
auto buffer = std::vector<std::uint8_t>(payload.ByteSize());
```

Then you need to serialize the payload:
```cpp
payload.SerializeToArray(buffer.data(), buffer.size());
```

Then return the buffer. After creating the buffer containing a serialized payload,
you can begin to craft the message. Create a method receiving a topic and the
payload to return the signature of an xMsg message:
```cpp
xmsg::Message payload_message(const xmsg::Topic& topic,
                              const xmsg::proto::Payload& payload)
{
    // serialize_payload just creates a buffer object, serializes the payload
    // to an array, and returns the buffer, which can be seen above
    auto buffer = serialize_payload(payload);
    return {topic, xmsg::mimetype::xmsg_data, std::move(buffer)};
}
```

After creating this method, you can call it to create the message conatining the
payload:
```cpp
message = payload_message(topic, payload);
```

Under the directory xMsgMultPayloads, there is an example of a producer subscriber
model with the producer sending a payload containing multiple payload items and
the subscriber receiving the payload and printing out the names of each item.

## Arrays

When arrays are sent, you cannot call parse_message on the message because it is
not a primitive. Here is a quick snippet of code to read an array of ints from a
message:
```cpp
auto data2 = xmsg::parse_message<xmsg::proto::Data>(msg);
auto rep2 = data2.flsint64a();
std::int64_t values[3];
std::copy(rep2.begin(), rep2.end(), values);
for (int val : values) {
    std::cout << val << std::endl;
}
```
