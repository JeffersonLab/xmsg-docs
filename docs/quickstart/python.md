---
layout: doc_quick
type: quickstart
type_desc: Quick Start
id: python
title: Python
---

## System Requirements

So far tested in:

Ubuntu 15.10
OSX El Capitan

### Ubuntu
```
$ sudo aptitude install libzmq3-dev
```
### OSX
```
$ brew install zmq
```

## Installing xMsg

To install xMsg in your system run:
```
$ ./setup.py install
```
This will install the xMsg package in the system libraries, and will copy the xmsg scripts in the /usr/bin/ directory.

For development use:
```
$ python setup.py develop
```
this command installs the package (in the xmsg source folder) in a way that allows you to conveniently edit your code after its installed to the (virtual) environment and have the changes take effect immediately.

## Examples

To run the examples:
```
$ # start a xMsgNode process using the scripts
$ # in the scripts folder
$ px_node
$ # or an xMsgProxy process
$ # in the scripts folder
$ px_proxy
```
then run the publisher and subscriber scripts:
```
$ ./bin/unix/px_publisher <size_of_array_to_publish>
$ ./bin/unix/px_subscriber
```
You can find the publisher and subscriber source code at the examples package