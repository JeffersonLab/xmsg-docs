---
layout: doc_lang
group_id: tutorials
group_title: Tutorials
id: cpp
title: C++
---

## Actors

In order to send and receive data, an actor for publishers and subscribers needs
to be created. After including the ipc_lib header file, all that needs to be
done to create these is to call the respective constructors:

  Creating producer object:<br>
    ```IpcProducer prod;```<br>

  Creating consumer object:<br>
    ```IpcConsumer cons;```<br>

These actor names will be used for all of the examples following.

## Starting Actors

After creating these actor objects, all that is needed to start them is to call
their respective 'run' methods. The `run()` method assigns a topic, creates a
default 'Hello World!' message, and connects the actor to the proxy. The method
then sends the message in a while loop that is controlled by the `waiting_for_messages`
variable.

  Running the producer:<br>
    `prod.run();`<br>

  Running the consumer:<br>
    `cons.run();`


## Messages

In order to send the current message while outside of the `run()` method, call
`sendMsg()` on the actor. This method is called within the while loop of `run()`:

  `prod.sendMsg();`

To read the messages received, the consumer class has overloaded right shift
operators for different data types to store data into the appropriate data type.
The producer class has overloaded left shit operators to make messages from
different data types.

  Setting the message:<br>
    `prod << "message to set to";`

**With the current implementation of the overloaded `<<` and `>>` operators, reading
and writing composite messages is not supported, meaning if used twice, the operators
will overwrite the first message and not append to it.**

After calling the `run()` method, or setting the message through `<<` operators,
the message will have a value. To set the message and topic to all empty strings,
call `clearMsg()` on the actor:

  `prod.clearMsg();`


## Connections

When the `ipc_lib.h` header creates xMsg actors, it defaults the connections to
`localhost`. The connection can be specified when creating the actor by passing
the constructor a different connection, for example:

  Specifying producer connection:<br>
    ```IpcProducer prod("localhost");```<br>

  Specifying consumer connection:<br>
    ```IpcConsumer cons("localhost");```<br>

Or the connection can be left to default as `localhost` by not passing anything
in the constructor:

  Default producer connection:<br>
    ```IpcProducer prod;```<br>

  Default consumer connection:<br>
    ```IpcConsumer cons;```<br>

## User Callback

There is a user defined callback that is used for receiving messages, as of now
it simply prints the messages out to the command line as they are received. To
assign the callback to the subscriber, it is passed in the method 'subscribe'

  Assigning User Callback:<br>
    ```sub = consumer.subscribe(TOPIC_VAR, CONNECTION_VAR, user_callback);```

The Callback is passed the message, which is parsed by `xmsg::parse_message` and
can be seen in the current UserCallback.
