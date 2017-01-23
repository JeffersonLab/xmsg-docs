---
layout: page
title: Download
---

With Gradle:

```groovy
repositories {
    maven {
        url 'https://clasweb.jlab.org/clas12maven/'
    }
}

dependencies {
    compile 'org.jlab.coda:xmsg:2.3-SNAPSHOT'
}
```

With Maven:

```xml
<repositories>
   <repository>
      <id>clas12maven</id>
      <url>https://clasweb.jlab.org/clas12maven</url>
   </repository>
</repositories>

<dependencies>
   <dependency>
      <groupId>org.jlab.coda</groupId>
      <artifactId>xmsg</artifactId>
      <version>2.3-SNAPSHOT</version>
  </dependency>
</dependencies>
```
