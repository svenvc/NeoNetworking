"
I am ExampleUDPKeyValueServer.
I am a BasicUDPServer.

Datagram key=value does an insert, no reply
Datagran key does a retrieve, reply is key=value if it exists

Implements and conforms to [Unusual Database Program] https://protohackers.com/problem/4
"
Class {
	#name : #ExampleUDPKeyValueServer,
	#superclass : #BasicUDPServer,
	#instVars : [
		'data'
	],
	#category : #'Neo-Networking'
}

{ #category : #accessing }
ExampleUDPKeyValueServer >> data [
	^ data
]

{ #category : #protocol }
ExampleUDPKeyValueServer >> handleDatagram: datagram [
	| request |
	request := datagram contents utf8Decoded.
	self log: [ 'Received {1} {2}' format: { datagram. request } ].
	(request includes: $=)
		ifTrue: [
			(request copyUpTo: $=) = #version
				ifFalse: [ data at: (request copyUpTo: $=) put: (request copyAfter: $=) ] ]
		ifFalse: [
			data at: request ifPresent: [ :value | | reply |
				reply := '{1}={2}' format: { request. value }.
				self log: [ 'Answered {1} {2}' format: { reply. datagram addressPort } ].
				sender sendDatagram: reply utf8Encoded inReplyTo: datagram ] ]
]

{ #category : #initialization }
ExampleUDPKeyValueServer >> initialize [
	super initialize.
	data := Dictionary new.
	data at: #version put: (self class name asString , ' - 1.0')
]
