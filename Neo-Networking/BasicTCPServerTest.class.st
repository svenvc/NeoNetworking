Class {
	#name : #BasicTCPServerTest,
	#superclass : #TestCase,
	#category : #'Neo-Networking'
}

{ #category : #tests }
BasicTCPServerTest >> testEchoNextPut [
	| server address port client input output |
	server := BasicTCPServer new port: 0; start.
	address := NetNameResolver loopBackAddress.
	port := server actualPort.
	client := ZdcSocketStream openConnectionToHost: address port: port.
	input := #[ 2 3 5 7 11 ].
	output := ByteArray streamContents: [ :out |
		input do: [ :each |
			client nextPut: each; flush.
			client next ifNotNil: [ :byte |
				out nextPut: byte ] ].
		client close ].
	server stop.
	self assert: input equals: output
]

{ #category : #tests }
BasicTCPServerTest >> testEchoNextPutAll [
	| server address port client input output |
	server := BasicTCPServer new port: 0; start.
	address := NetNameResolver loopBackAddress.
	port := server actualPort.
	client := ZdcSocketStream openConnectionToHost: address port: port.
	input := UUID new as: ByteArray.
	client nextPutAll: input; flush.
	output := client next: input size.
	client close.
	server stop.
	self assert: input equals: output
]
