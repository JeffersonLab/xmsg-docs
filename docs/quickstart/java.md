---
layout: doc_quick
type: quickstart
type_desc: Quick Start
id: java
title: Java
---

## Installation

### With Gradle:

```
repositories {
    maven {
        url 'http://clasweb.jlab.org/clas12maven/'
    }
}

dependencies {
    compile 'org.jlab.coda:xmsg:2.4-SNAPSHOT'
}
```
### With Maven:

```
<repositories>
   <repository>
      <id>clas12maven</id>
      <url>http://clasweb.jlab.org/clas12maven</url>
   </repository>
</repositories>

<dependencies>
   <dependency>
      <groupId>org.jlab.coda</groupId>
      <artifactId>xmsg</artifactId>
      <version>2.4-SNAPSHOT</version>
  </dependency>
</dependencies>
```

## Build notes

xMsg requires the Java 8 JDK.

### Ubuntu

- Support PPAs:
```
$ sudo apt-get install software-properties-common
```

- Install Oracle Java 8 from the Web Upd8 PPA:
```
$ sudo add-apt-repository ppa:webupd8team/java
$ sudo apt-get update
$ sudo apt-get install oracle-java8-installer
```

- Check the version:
```
$ java -version
java version "1.8.0_101"
Java(TM) SE Runtime Environment (build 1.8.0_101-b13)
Java HotSpot(TM) 64-Bit Server VM (build 25.101-b13, mixed mode)
```

You may need the following package to set Java 8 as default (see the previous link for more details):
```
$ sudo apt-get install oracle-java8-set-default
```
You can also set the default Java version with update-alternatives:
```
$ sudo update-alternatives --config java
```

### macOS

- Install Oracle Java using Homebrew:
```
$ brew cask install java
```

- Check the version:
```
$ java -version
java version "1.8.0_92"
Java(TM) SE Runtime Environment (build 1.8.0_92-b14)
Java HotSpot(TM) 64-Bit Server VM (build 25.92-b14, mixed mode)
```

## Build

To build xMsg use the provided Gradle wrapper. It will download the required Gradle version and all dependencies.
```
$ ./gradlew
```

To run the integration tests:
```
$ ./gradlew integration
```
To install the xMsg artifact to the local Maven repository:
```
$ ./gradlew install
```
Importing the project into your IDE

Gradle can generate the required configuration files to import the xMsg project into Eclipse and IntelliJ IDEA:
```
$ ./gradlew cleanEclipse eclipse

$ ./gradlew cleanIdea idea
```
See also the [Eclipse Buildship plugin](http://www.vogella.com/tutorials/EclipseGradle/article.html)
and the [Intellij IDEA Gradle](https://www.jetbrains.com/help/idea/2016.2/gradle.html)  Help.