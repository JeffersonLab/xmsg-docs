---
layout: doc_lang
group_id: examples
group_title: Examples
id: ipc-cpp
title: IPC C++
---

# Publisher Subscriber Example using ipc_lib header with xMsg

In the /src/ directory, two files called `pub.cpp` and `sub.cpp` contain
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

## Expanding on the example
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
