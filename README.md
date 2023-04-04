# NeoNetworking
Networking tools for Pharo

This package contains a small framework to set up TCP or UDP network servers/services. 
By subclassing and overwriting just a couple of methods you get a working server for a specific protocol.

The class **AbstractNetworkServer** offers process management (start, stop), configuration (port), constants and (transcript) logging.
The subclass **BasicTCPServer** is a framework for a TCP network service listening on a socket, accepting and servicing client connections, 
forking a connection handler process to service each client.
The subclass **BasicUDPServer** is a framework for a UDP network service listening on a socket, accepting and servicing incoming datagrams, handle incoming datagrams in its main process.
Both are also concrete classes acting as an RFC 862 Echo service.

Check out the class comments and the examples with their unit tests.

Together they implement and satisfy the first 5 problems of https://protohackers.com/
- problem 0 [Smoke Test](https://protohackers.com/problem/0) solution [BasicTCPServer](https://github.com/svenvc/NeoNetworking/blob/main/Neo-Networking/BasicTCPServer.class.st)
- problem 1 [Pime Test](https://protohackers.com/problem/1) solution [ExamplePrimeTestPServer](https://github.com/svenvc/NeoNetworking/blob/main/Neo-Networking/ExamplePrimeTestServer.class.st)
- problem 2 [Means to an End](https://protohackers.com/problem/2) solution [ExampleAssetPricingServer](https://github.com/svenvc/NeoNetworking/blob/main/Neo-Networking/ExampleAssetPricingServer.class.st)
- problem 3 [Budget Chat](https://protohackers.com/problem/3) solution [ExampleChatServer](https://github.com/svenvc/NeoNetworking/blob/main/Neo-Networking/ExampleChatServer.class.st)
- problem 4 [Unusual Database Program](https://protohackers.com/problem/4) solution [ExampleUDPKeyValueServer](https://github.com/svenvc/NeoNetworking/blob/main/Neo-Networking/ExampleUDPKeyValueServer.class.st)

For each solution there are unit tests containing client code exercising each protocol.

The classes Datagram, UDPSender and UDPListener improve upon the basic UDP functionality is the system class Socket.

Here is an example session installing, deploying, starting and running one of the examples:

````
$ mkdir pharo11
$ cd pharo11
$ curl get.pharo.org/alpha+vm | bash

$ ./pharo Pharo.image metacello install github://svenvc/NeoConsole/src BaselineOfNeoConsole
$ sudo apt install rlwrap
$ sudo ufw allow 9999/tcp
$ sudo ufw allow 9999/udp

$ rlwrap ./pharo Pharo.image NeoConsole repl
NeoConsole Pharo-11.0.0+build.656.sha.c2c9c49ff09ab6da7740a4421a244b63ea883d39 (64 Bit)

pharo> Gofer it url: 'github://svenvc/NeoNetworking'; package: 'Neo-Networking'; load.

a GoferLoad

pharo> ExamplePrimeTestServer new start.

an ExamplePrimeTestServer(running 9999)

2023-04-03 14:47:29.597 90CBNK Started ExamplePrimeTestServer port 9999
2023-04-03 14:49:04.594 1BAOE8 Handling connection
2023-04-03 14:49:06.675 1BAOE8 Read {"method":"isPrime","number":123}
2023-04-03 14:49:06.675 1BAOE8 Wrote {"method":"isPrime","prime":false}
2023-04-03 14:49:12.315 1BAOE8 Read {"method":"isPrime","number":997}
2023-04-03 14:49:12.316 1BAOE8 Wrote {"method":"isPrime","prime":true}
2023-04-03 14:49:16.583 1BAOE8 Read nil
2023-04-03 14:49:16.583 1BAOE8 Ending connection

pharo> ExamplePrimeTestServer allInstances anyOne stop.

an ExamplePrimeTestServer(9999)

2023-04-03 14:50:04.115 90CBNK Stopped ExamplePrimeTestServer port 9999

pharo> quit
Bye!

$ telnet 127.0.0.1 9999
Trying 127.0.0.1...
Connected to 127.0.0.1.
Escape character is '^]'.
{"method":"isPrime","number":123}
{"method":"isPrime","prime":false}
{"method":"isPrime","number":997}
{"method":"isPrime","prime":true}
````

Happy hacking !
