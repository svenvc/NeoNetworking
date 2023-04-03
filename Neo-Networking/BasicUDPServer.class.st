"
I am BasicUDPServer.
I am a AbstractNetworkServer.
I handle incoming datagrams in my main process.

Out of the box I implement an RFC 862 Echo service.
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
	self log: ('Echoing {1}' format: { datagram }).
	sender send: datagram
]

{ #category : #protocol }
BasicUDPServer >> listenLoop [
	self setUp.
	[ [
		| datagram |
		datagram := listener receiveDatagramTimeout: self timeout.
		datagram isEmpty ifFalse: [ self handleDatagram: datagram ] ] repeat ]
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
