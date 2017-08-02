---
layout: doc_quick
type: quickstart
type_desc: Quick Start
id: cpp
title: C++
---

## Build notes

xMsg requires a C++14 compiler (GCC 4.9+) and CMake 3.1+

### Ubuntu 14.04

  Support PPAs:
```
sudo apt-get install software-properties-common
```
 Add a PPA for GCC (do not use GCC 5.x due to ABI changes):
```
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt-get install build-essential gcc-4.9 g++-4.9
```

 Set GCC 4.9 as default:
```
sudo update-alternatives \
        --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 60 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-4.9
```
 Add a PPA for CMake:
```
sudo add-apt-repository ppa:george-edison55/cmake-3.x
sudo apt-get update
sudo apt-get install cmake
```

### Ubuntu 16.04

 Install GCC and CMake from the repositories:
```
sudo apt-get install build-essential cmake
```

### Mac OS X 10.9 and newer

 Install Xcode command line tools:
```
xcode-select --install
```

Install CMake using Homebrew:
```
brew install cmake
```
## Dependencies

xMsg uses Protocol Buffers and ZeroMQ.

### Ubuntu 14.04 and 16.04

Install from the repositories:
```
sudo apt-get install libzmq3-dev libprotobuf-dev protobuf-compiler
```
### Mac OS X 10.9 and newer

Use Homebrew:
```
brew update
brew install zeromq protobuf
```
## Installation

To build with CMake a configure wrapper script is provided:
```
./configure --prefix=<INSTALL_DIR>
make
make install
```