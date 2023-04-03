Class {
	#name : #ExampleUDPKeyValueServerTest,
	#superclass : #TestCase,
	#category : #'Neo-Networking'
}

{ #category : #tests }
ExampleUDPKeyValueServerTest >> testEmpty [
	| server actualPort datagram sender listener |
	server := ExampleUDPKeyValueServer new port: 0; start.
	actualPort := server actualPort.
	listener := UDPListener onPort: 0.
	sender := listener sender.
	sender sendDatagram: 'foo=' utf8Encoded toHost: 'localhost' port: actualPort.
	sender sendDatagram: 'foo' utf8Encoded toHost: 'localhost' port: actualPort.
	datagram := listener receiveDatagramTimeout: 1.
	self assert: datagram contents utf8Decoded equals: 'foo='.
	sender sendDatagram: '=foo' utf8Encoded toHost: 'localhost' port: actualPort.
	sender sendDatagram: '' utf8Encoded toHost: 'localhost' port: actualPort.
	datagram := listener receiveDatagramTimeout: 1.
	self assert: datagram contents utf8Decoded equals: '=foo'.
	sender sendDatagram: '=' utf8Encoded toHost: 'localhost' port: actualPort.
	sender sendDatagram: '' utf8Encoded toHost: 'localhost' port: actualPort.
	datagram := listener receiveDatagramTimeout: 1.
	self assert: datagram contents utf8Decoded equals: '='.
	listener close.
	server stop
]

{ #category : #tests }
ExampleUDPKeyValueServerTest >> testProtocol [
	| server actualPort foo bar datagram sender listener |
	server := ExampleUDPKeyValueServer new port: 0; start.
	actualPort := server actualPort.
	listener := UDPListener onPort: 0.
	sender := listener sender.
	foo := 'foo=' , UUID new asString.
	bar := 'bar=' , UUID new asString.
	sender sendDatagram: foo utf8Encoded toHost: 'localhost' port: actualPort.
	sender sendDatagram: bar utf8Encoded toHost: 'localhost' port: actualPort.
	sender sendDatagram: 'foo' utf8Encoded toHost: 'localhost' port: actualPort.
	datagram := listener receiveDatagramTimeout: 1.
	self assert: datagram contents utf8Decoded equals: foo.
	sender sendDatagram: 'bar' utf8Encoded toHost: 'localhost' port: actualPort.
	datagram := listener receiveDatagramTimeout: 1.
	self assert: datagram contents utf8Decoded equals: bar.
	listener close.
	server stop
]

{ #category : #tests }
ExampleUDPKeyValueServerTest >> testVersion [
	| server actualPort datagram sender listener |
	server := ExampleUDPKeyValueServer new port: 0; start.
	actualPort := server actualPort.
	listener := UDPListener onPort: 0.
	sender := listener sender.
	sender sendDatagram: 'version' utf8Encoded toHost: 'localhost' port: actualPort.
	datagram := listener receiveDatagramTimeout: 1.
	self assert: (datagram contents utf8Decoded beginsWith: 'version=').
	sender sendDatagram: 'version=' utf8Encoded toHost: 'localhost' port: actualPort.
	sender sendDatagram: 'version' utf8Encoded toHost: 'localhost' port: actualPort.
	datagram := listener receiveDatagramTimeout: 1.
	self assert: (datagram contents utf8Decoded beginsWith: 'version=').
	listener close.
	server stop
]
