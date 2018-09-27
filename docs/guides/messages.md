---
layout: doc_guide
title: Messages
---

## Messages

Actors communicate with others actors by publishing messages
to given **topics**, or named channels.
Subscribers can receive the messages published to the topics
to which they are interested, by subscribing to them.
The messages are not sent directly to another actor.
All actors subscribed to the topic of a published message will receive it.

### Raw message format

A message is sent through the wire as a ZMQ message composed of three frames:

![]({{ site.baseurl }}/assets/images/raw-message.png){: .align-center .zmqmsg }

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
