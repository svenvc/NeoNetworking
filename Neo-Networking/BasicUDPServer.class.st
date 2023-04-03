"
I am BasicUDPServer, a framework for a UDP network service listening on a socket, accepting and servicing incoming datagrams.
I am a AbstractNetworkServer.
I handle incoming datagrams in my main process.

Out of the box I implement an RFC 862 Echo service.

I am meant to be subclassed to implement other protocols. Consider overwriting almost any method, if needed.
"
Class {
	#name : #BasicUDPServer,
	#superclass : #AbstractNetworkServer,
	#instVars : [
		'sender',
		'listener'
	],
	#category : #'Neo-Networking'
}

{ #category : #protocol }
BasicUDPServer >> handleDatagram: datagram [
	self log: [ 'Echoing {1}' format: { datagram } ].
	sender send: datagram
]

{ #category : #protocol }
BasicUDPServer >> listenLoop [
	self setUp.
	[ [
		| datagram |
		datagram := listener receiveDatagramTimeout: self timeout.
		datagram wasReceived ifTrue: [ self handleDatagram: datagram ] ] repeat ]
			ifCurtailed: [ self tearDown ]
]

{ #category : #protocol }
BasicUDPServer >> setUp [
	listener := UDPListener onPort: self port.
	sender := listener sender.
	serverSocket := listener socket.
	self port isZero ifTrue: [
		self log: ('OS assigned port = {1}' format: { serverSocket port }) ]
]

{ #category : #protocol }
BasicUDPServer >> tearDown [
	listener close.
	listener := sender := serverSocket := nil
]
