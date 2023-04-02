"
UDPListener helps in receiving UDP Datagrams on a certain port.

	| listener response |
	listener := UDPListener onPort: 12345.
	response := listener receiveDatagramTimeout: 5 * 60.
	listener close. 
	response.

Send an UDP datagram using Netcat: nc -u 127.0.0.1 12345

I can share my socket with a UDPSender.
"
Class {
	#name : #UDPListener,
	#superclass : #Object,
	#instVars : [
		'socket',
		'datagram',
		'delay',
		'packetCount',
		'byteCount'
	],
	#category : #'Neo-Networking'
}

{ #category : #'instance creation' }
UDPListener class >> onPort: port [
	^ self new
		port: port;
		yourself
]

{ #category : #'instance creation' }
UDPListener class >> onSocket: anUDPSocket [
	^ self new
		socket: anUDPSocket;
		yourself
]

{ #category : #utilities }
UDPListener class >> startProcessOn: port handler: block [
	"UDPListener startProcessOn: 12345 handler: [ :datagram | datagram traceCr ]"
	"UDPListener startProcessOn: 12345 handler: [ :datagram | datagram contents utf8Decoded trimRight traceCr ]"

	| listener datagram |
	listener := self onPort: port.
	datagram := Datagram buffer: 256.
	^ [ [ [ block value: (listener receive: datagram) ] repeat ] ifCurtailed: [ listener close ] ] fork
]

{ #category : #accessing }
UDPListener >> byteCount [
	^ byteCount
]

{ #category : #'initialize-release' }
UDPListener >> close [
	socket ifNotNil: [
		socket closeAndDestroy.
		socket := nil ]
]

{ #category : #accessing }
UDPListener >> datagram [
	^ datagram ifNil: [ datagram := Datagram buffer: self defaultDatagramSize ]
]

{ #category : #accessing }
UDPListener >> datagram: anObject [
	datagram := anObject
]

{ #category : #accessing }
UDPListener >> defaultDatagramSize [
	^ 1024
]

{ #category : #accessing }
UDPListener >> defaultDelay [
	^ 50 "ms"
]

{ #category : #accessing }
UDPListener >> delay [
	^ delay ifNil: [ delay := Delay forMilliseconds: self defaultDelay ]
]

{ #category : #testing }
UDPListener >> hasSocket [
	^ socket notNil
]

{ #category : #initialization }
UDPListener >> initialize [
	packetCount := byteCount := 0
]

{ #category : #accessing }
UDPListener >> packetCount [
	^ packetCount
]

{ #category : #accessing }
UDPListener >> port [
	^ self hasSocket ifTrue: [ socket port ] ifFalse: [ nil ]
]

{ #category : #'initialize-release' }
UDPListener >> port: port [
	self close.
	self socket: (Socket newUDP setPort: port; yourself)
]

{ #category : #private }
UDPListener >> primitiveReceive: bytes [
	| totalReceived result |
	totalReceived := 0.
	[
		result := socket
			primSocket: socket socketHandle
			receiveUDPDataInto: bytes
			startingAt: totalReceived + 1
			count: bytes size - totalReceived.
		totalReceived := totalReceived + result first.
		result fourth
			ifTrue: [
				bytes size - totalReceived <= 0
					ifTrue: [ self error: 'Buffer overflow receiving datagram' ].
				socket waitForDataFor: 1 ]
			ifFalse: [
				result at: 1 put: totalReceived.
				^ result ]
	 ] repeat
]

{ #category : #printing }
UDPListener >> printOn: stream [
	super printOn: stream.
	stream
		nextPut: $(;
		print: self byteCount; nextPut: $B;
		space;
		nextPut: $#; print: self packetCount;
		nextPut: $)
]

{ #category : #accessing }
UDPListener >> receive: receivingDatagram [
	| result |
	[
		result := self primitiveReceive: receivingDatagram buffer.
		result first isZero ] whileTrue: [ self delay wait ].
	packetCount := packetCount + 1.
	byteCount := byteCount + result first.
	^ receivingDatagram
		length: result first;
		address: result second;
		port: result third;
		yourself
]

{ #category : #accessing }
UDPListener >> receiveDatagram [
	^ self receive: self datagram
]

{ #category : #accessing }
UDPListener >> receiveDatagram: receivingDatagram timeout: seconds [
	| delayWaitCount result |
	delayWaitCount := seconds * 1000 / self delay millisecondDelayDuration.
	[
		result := self socket
			ifNil: [
				#( 0 nil nil ).
				delayWaitCount := 1 ]
			ifNotNil: [
				self primitiveReceive: receivingDatagram buffer ].
		delayWaitCount := delayWaitCount - 1.
		result first isZero and: [ delayWaitCount > 0 ] ] whileTrue: [ self delay wait ].
	result first isZero
		ifFalse: [
			packetCount := packetCount + 1.
			byteCount := byteCount + result first ].
	^ receivingDatagram
		length: result first;
		address: result second;
		port: result third;
		yourself
]

{ #category : #accessing }
UDPListener >> receiveDatagramTimeout: seconds [
	^ self
		receiveDatagram: self datagram
		timeout: seconds
]

{ #category : #accessing }
UDPListener >> sender [
	"Answer a DPSender object on my socket"

	^ UDPSender onSocket: self socket
]

{ #category : #accessing }
UDPListener >> sizeBuffer: size [
	datagram := Datagram buffer: size
]

{ #category : #accessing }
UDPListener >> socket [
	^ socket
]

{ #category : #'initialize-release' }
UDPListener >> socket: anUDPSocket [
	socket := anUDPSocket
]
