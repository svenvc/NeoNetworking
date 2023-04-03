Class {
	#name : #DatagramTest,
	#superclass : #TestCase,
	#category : #'Neo-Networking'
}

{ #category : #tests }
DatagramTest >> testSimple [
	| datagram |
	datagram := Datagram buffer: 32.
	self assert: datagram isEmpty.
	self assert: datagram capacity equals: 32.
	datagram contents: #[ 2 3 5 7 ].
	self deny: datagram isEmpty.
	self assert: datagram contents equals: #[ 2 3 5 7 ].
	self assert: datagram size equals: 4.
	self assert: (datagram readStream next; next: 2) equals: #[ 3 5 ]
]
