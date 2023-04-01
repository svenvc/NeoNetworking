Class {
	#name : #ExampleChatServerTest,
	#superclass : #TestCase,
	#category : #'Neo-Networking'
}

{ #category : #tests }
ExampleChatServerTest >> testConversation [
	| server address port client1 client2 out1 in1 out2 in2 handle1 handle2 line message |
	server := ExampleChatServer new port: 0; start.
	address := NetNameResolver loopBackAddress.
	port := server actualPort.
	client1 := ZdcSocketStream openConnectionToHost: address port: port.
	handle1 := UUID new hex.
	out1 := ZnCharacterWriteStream on: client1.
	in1 := ZnCharacterReadStream on: client1.
	line := in1 nextLine. "welcome prompt"
	self deny: line isEmptyOrNil.
	out1 nextPutAll: handle1; lf; flush. "register"
	line := in1 nextLine. "present prompt"
	self deny: (line includesSubstring: handle1).
	client2 := ZdcSocketStream openConnectionToHost: address port: port.
	handle2 := UUID new hex.
	out2 := ZnCharacterWriteStream on: client2.
	in2 := ZnCharacterReadStream on: client2.
	line := in2 nextLine. "welcome prompt"
	self deny: line isEmptyOrNil.
	out2 nextPutAll: handle2; lf; flush. "register"
	line := in2 nextLine. "present prompt"
	self assert: (line includesSubstring: handle1).
	self deny: (line includesSubstring: handle2).
	line := in1 nextLine. "enter"
	self assert: (line includesSubstring: handle2).
	message := UUID new hex.
	out1 nextPutAll: message; lf; flush. "send message from client1->client2"
	line := in2 nextLine. "receive message from client1->client2"
	self assert: (line includesSubstring: handle1).
	self assert: (line includesSubstring: message).
	message := UUID new hex.
	out2 nextPutAll: message; lf; flush. "send message from client2->client1"
	line := in1 nextLine. "receive message from client2->client1"
	self assert: (line includesSubstring: handle2).
	self assert: (line includesSubstring: message).
	client2 close.
	line := in1 nextLine. "leave"
	self assert: (line includesSubstring: handle2).
	client1 close.
	server stop
]
