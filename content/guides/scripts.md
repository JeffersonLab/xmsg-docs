# Scripts

xMsg provides two wrappers scripts to launch the **proxy**
and the **registrar** processes.

To launch the proxy:

```
$ jx_proxy
```

To launch the registrar:

```
$ jx_registrar
```

Both scripts can accept custom settings for the IP address and port
that shall be used.

The proxy and the registrar can also be instantiated from a Java program.
See the `xMsgProxy` and `xMsgRegistrar` classes.
Note that a new `ZContext` must be created,
and destroyed before stopping the services.
