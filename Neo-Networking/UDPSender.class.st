"
UDPSender helps in sending UDP Datagram packets to a host:port.

Usage

	| sender |
	sender := T3UDPSender new.
	sender sendDatagram: 'Hello there!' toHost: 'localhost' port: 12345.
	sender close.  

	| sender |
	sender := T3UDPSender new.
	sender send: ((T3Datagram with: 'Hello there!') host: 'localhost'; port: 12345; yourself).
	sender close.  

Setup a server using Netcat: nc -lu 12345

I can share my socket with a UDPListener.
"
Class {
	#name : #UDPSender,
	#superclass : #Object,
	#instVars : [
		'socket',
		'sendBufferSize',
		'packetCount',
		'byteCount'
	],
	#category : #'Neo-Networking'
}

{ #category : #'instance creation' }
UDPSender class >> onSocket: anUDPSocket [
	^ self new
		socket: anUDPSocket;
		yourself
]

{ #category : #convenience }
UDPSender class >> send: data toHost: host port: port [
	"UDPSender send: 'Hello from Smalltalk' utf8Encoded toHost: 'localhost' port: 12345."

	| sender datagram result |
	(datagram := Datagram with: data) host: host; port: port.
	sender := self new.
	result := sender send: datagram.
	sender close.
	^ result
]

{ #category : #accessing }
UDPSender >> byteCount [
	^ byteCount
]

{ #category : #'initialize-release' }
UDPSender >> close [
	socket ifNil: [ ^ self ].
	socket closeAndDestroy.
	socket := nil
]

{ #category : #testing }
UDPSender >> hasSocket [
	^ socket notNil
]

{ #category : #initialization }
UDPSender >> initialize [
	packetCount := byteCount := 0
]

{ #category : #private }
UDPSender >> initializeSocket [
	^ self socket: Socket newUDP
]

{ #category : #accessing }
UDPSender >> listener [
	"Answer a UDPListener object on my socket"

	^ UDPListener onSocket: self socket
]

{ #category : #accessing }
UDPSender >> packetCount [
	^ packetCount
]

{ #category : #private }
UDPSender >> primitiveSend: bytes length: length host: host port: port [
	| totalSent sent toSent |
	length = 0
		ifTrue: [ ^ self sendEmptyUDPPacketToHost: host port: port ].
	totalSent := 0.
	[ totalSent < length ] whileTrue: [
		(self socket waitForSendDoneFor: self timeout)
			ifFalse: [ ConnectionTimedOut signal: 'UDP send timed out' ].
		toSent := (length - totalSent) min: sendBufferSize.
		sent := self socket
			primSocket: socket socketHandle
			sendUDPData: bytes
			toHost: host
			port: port
			startIndex: totalSent + 1
			count: toSent.
		totalSent := totalSent + sent ].
	packetCount := packetCount + 1.
	byteCount := byteCount + totalSent.
	^ totalSent
]

{ #category : #printing }
UDPSender >> printOn: stream [
	super printOn: stream.
	stream
		nextPut: $(;
		print: self byteCount; nextPut: $B;
		space;
		nextPut: $#; print: self packetCount;
		nextPut: $)
]

{ #category : #public }
UDPSender >> send: datagram [
	^ self
		primitiveSend: datagram buffer
		length: datagram length
		host: datagram address
		port: datagram port
]

{ #category : #public }
UDPSender >> sendDatagram: bytes inReplyTo: datagram [
	^ self
		sendDatagram: bytes
		toHost: datagram host
		port: datagram port
]

{ #category : #public }
UDPSender >> sendDatagram: bytes toHost: host port: port [
	| address |
	address := host isString
		ifTrue: [ NetNameResolver addressForName: host ]
		ifFalse: [ host ].
	^ self
		primitiveSend: bytes
		length: bytes size
		host: address
		port: port
]

{ #category : #private }
UDPSender >> sendEmptyUDPPacketToHost: host port: port [
	(self socket waitForSendDoneFor: self timeout)
		ifFalse: [ ConnectionTimedOut signal: 'UDP send timed out' ].
	self socket
		primSocket: socket socketHandle
		sendUDPData: #[]
		toHost: host
		port: port
		startIndex: 1
		count: 0.
	^ 0
]

{ #category : #accessing }
UDPSender >> socket [
	^ socket ifNil: [ self initializeSocket ]
]

{ #category : #'initialize-release' }
UDPSender >> socket: anUDPSocket [
	socket := anUDPSocket.
	sendBufferSize := socket ifNotNil: [ (socket getOption: 'SO_SNDBUF') second ] ifNil: [ 0 ].
	^ socket
]

{ #category : #accessing }
UDPSender >> timeout [
	^ 20
]
