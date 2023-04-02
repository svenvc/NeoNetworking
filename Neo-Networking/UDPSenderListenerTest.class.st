Class {
	#name : #UDPSenderListenerTest,
	#superclass : #TestCase,
	#category : #'Neo-Networking'
}

{ #category : #tests }
UDPSenderListenerTest >> testSimple [
	| data listener result datagram |
	listener := UDPListener onPort: 12345.
	data := #[ 1 2 3 4 5 6 7 8 9 0 ].
	result := UDPSender send: data toHost: 'localhost' port: 12345.
	self assert: result equals: data size.
	datagram := listener receiveDatagramTimeout: 1.
	self assert: datagram contents equals: data.
	listener close
]

{ #category : #tests }
UDPSenderListenerTest >> testSizes [
	512 to: 9216 by: 512 do: [ :each |
		| data listener result datagram |
		listener := UDPListener onPort: 12345.
		listener sizeBuffer: each.
		data := ByteArray new: each streamContents: [ :stream |
			each timesRepeat: [ stream nextPut: 256 atRandom - 1 ] ].
		result := UDPSender send: data toHost: 'localhost' port: 12345.
		self assert: result equals: data size.
		datagram := listener receiveDatagramTimeout: 1.
		self assert: datagram contents equals: data.
		listener close ]
]
