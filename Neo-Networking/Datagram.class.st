"
Datagram represents the contents of a UDP Datagram, 
the data as well as a host address and a port.

Note that the data buffer is only used up to the length.
See #contents, #contents:, #hasContent and #reset.
The goal is to make it possible to reuse this object multiple times.

A datagram is always binary.

When receiving a datagram, the host:port will be that of the sender.
When sending a datagram, the host:port designate the destination.
When replying on a received datagram, the sender's host:port must be used.
"
Class {
	#name : #Datagram,
	#superclass : #Object,
	#instVars : [
		'buffer',
		'length',
		'address',
		'port'
	],
	#category : #'Neo-Networking'
}

{ #category : #'instance creation' }
Datagram class >> buffer: size [
	"Create a new datagram capable of holding size bytes"

	^ self new
		buffer: (ByteArray new: size);
		reset;
		yourself
]

{ #category : #'instance creation' }
Datagram class >> with: data [
	"Create a datagram containing data (a ByteArray)"

	^ self new
		contents: data;
		yourself
]

{ #category : #accessing }
Datagram >> address [
	^ address
]

{ #category : #accessing }
Datagram >> address: anObject [
	address := anObject
]

{ #category : #accessing }
Datagram >> addressPort [
	^ String streamContents: [ :out |
			self printAddressAndPortOn: out ]
]

{ #category : #accessing }
Datagram >> buffer [
	^ buffer
]

{ #category : #accessing }
Datagram >> buffer: aStringOrByteArray [
	buffer := aStringOrByteArray
]

{ #category : #accessing }
Datagram >> capacity [
	^ buffer ifNil: [ 0 ] ifNotNil: [ buffer size ]
]

{ #category : #public }
Datagram >> contents [
	^ self buffer copyFrom: 1 to: self length
]

{ #category : #public }
Datagram >> contents: data [
	self buffer
		ifNil: [ self setContents: data ]
		ifNotNil: [ self replaceContents: data ]
]

{ #category : #testing }
Datagram >> hasAddressAndPort [
	^ self address notNil and: [ self port notNil ]
]

{ #category : #accessing }
Datagram >> host [
	^ NetNameResolver nameForAddress: self address timeout: 5
]

{ #category : #accessing }
Datagram >> host: hostname [
	self address: (NetNameResolver addressForName: hostname)
]

{ #category : #testing }
Datagram >> isEmpty [
	^ self length isNil or: [ self length isZero ]
]

{ #category : #accessing }
Datagram >> length [
	^ length
]

{ #category : #accessing }
Datagram >> length: anObject [
	length := anObject
]

{ #category : #accessing }
Datagram >> port [
	^ port
]

{ #category : #accessing }
Datagram >> port: anObject [
	port := anObject
]

{ #category : #printing }
Datagram >> printAddressAndPortOn: stream [
	stream nextPutAll: ($. join: self address); nextPut: $:; print: self port
]

{ #category : #printing }
Datagram >> printOn: stream [
	super printOn: stream.
	stream nextPut: $(.
	self isEmpty
		ifFalse: [ self contents printHexOn: stream ].
	self hasAddressAndPort
		ifTrue: [
			self isEmpty ifFalse: [ stream space ].
			self printAddressAndPortOn: stream ].
	stream nextPut: $)
]

{ #category : #public }
Datagram >> readStream [
	^ ReadStream on: self buffer from: 1 to: self length
]

{ #category : #public }
Datagram >> replaceContents: data [
	self buffer replaceFrom: 1 to: data size with: data startingAt: 1.
	self length: data size
]

{ #category : #public }
Datagram >> reset [
	length := 0.
	address := port := nil
]

{ #category : #public }
Datagram >> setContents: data [
	self buffer: data.
	self length: data size
]

{ #category : #accessing }
Datagram >> size [
	^ self length
]

{ #category : #testing }
Datagram >> wasReceived [
	"Return true when I am the result of the reception of a packet, if an empty one"

	^ self hasAddressAndPort
			and: [ self address ~= #[0 0 0 0] and: [ self port isZero not ] ]
]
