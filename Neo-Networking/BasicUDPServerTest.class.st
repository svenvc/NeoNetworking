Class {
	#name : #BasicUDPServerTest,
	#superclass : #TestCase,
	#category : #'Neo-Networking'
}

{ #category : #tests }
BasicUDPServerTest >> testEcho [
	| server actualPort data result datagram sender listener |
	server := BasicUDPServer new port: 0; start.
	actualPort := server actualPort.
	listener := UDPListener onPort: 0.
	sender := listener sender.
	4 timesRepeat: [
		data := UUID new as: ByteArray.
		result := sender sendDatagram: data toHost: 'localhost' port: actualPort.
		self assert: result equals: data size.
		datagram := listener receiveDatagramTimeout: 1.
		self assert: datagram contents equals: data ].
	listener close.
	server stop
]
