# xMsg

xMsg is a lightweight, yet full featured publish/subscribe messaging system,
providing asynchronous publish/subscribe inter-process communication.

#### Many-to-many communication model

xMsg creates an environment where various information producers and
consumers can communicate all at the same time. Each piece of information can
be delivered to various consumers concurrently, while each consumer can
receive information from different producers.

#### Decoupling

xMsg actors, i.e. information producers and consumers do not need to know each
other. Message addressing is based on the message topic. Information is
published to a topic or named logical channel. Consumers will receive all
messages published to the topic to which they subscribe, and all subscribers
to a topic will receive the same message. The producer is responsible for
defining classes of message topics to which consumers can subscribe.


## Getting Started

For a full description of xMsg, read the [**User's Guide**](guides/actors.md).
The table below also presents **quickstart guides**
and links to the *source repository* and the *API reference*
for every language in which xMsg is implemented.

For instructions how to add xMsg to your project,
visit the [**Download page**](download.md).


## Supported Languages

<div class="doc-lang-table" markdown="1">

| Java | C++ | Python |
|:-----|:----|:-------|
| [Quick Start][jq] | [Quick Start][cq] | [Quick Start][pq] |
| [Source code][jg] | [Source code][cg] | [Source code][pg] |
| [Reference][jr]   | [Reference][cr]   | [Reference][pr]   |

</div>

[jq]: quickstart/java.md
[jg]: https://github.com/JeffersonLab/xmsg-java
[jr]: /xmsg/api/java/current/

[cq]: quickstart/cpp.md
[cg]: https://github.com/JeffersonLab/xmsg-cpp
[cr]: /xmsg/api/cpp/

[pq]: quickstart/python.md
[pg]: https://github.com/JeffersonLab/xmsg-python
[pr]: /xmsg/api/python/


## Features

### Dynamic discovery

xMsg provides in memory registration database that is used to register xMsg actors
(i.e. publishers and subscribers). Hence, xMsg API includes methods for registering a
nd discovering publishers and subscribers. This makes xMsg a suitable framework to
build symmetric SOA based applications. For example a services that has a message
to publishing can check to see if there are enough subscribers of this particular message type.

To solve dynamic discovery problem in pub/sub environment the need of a proxy
server is unavoidable. xMsg is using 0MQ socket libraries and borrows 0MQ proxy,
which is a simple stateless message switch to address mentioned dynamic discovery problem.

### Simple conenction handling

xMsg stores proxy connection objects internally in a connection pool for
efficiency reasons. To avoid proxy connection concurrency, thus achieving
maximum performance, connection objects are not shared between threads.
Each xMsg actor tread will reuse an available connection object, or create
a new proxy connection if it is not available in the pool.

### Publish to any user-defined topics

xMsg publisher can send a message of any topic. xMsg subscribers subscribe
to abstract topics and provide callbacks to handle messages as they arrive,
in a so called subscribe-and-forget mode. Neither publisher nor subscriber
knows of each others existence. Thus publishers and subscribers are completely
independent of each others. Yet, for a proper communication they need to
establish some kind of relationship or binding, and that binding is the
communication or message topic. Note that multiple xMsg actors can communicate
without interfering with each other via simple topic naming conventions.
xMsg topic convention defines three parts: domain, subject, and type,
presented by the Topic class.

### Multithreaded callbacks

xMsg subscriber callbacks will run in a separate thread. For that reason
xMsg provides a thread pool, simplifying the job of a user. Note that
user provided callback routines must be thread safe and/or thread enabled.


## Use cases

* [IPC implementation with xMsg C++](software/ipc_lib.md)
