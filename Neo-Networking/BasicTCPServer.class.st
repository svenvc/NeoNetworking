"
I am BasicTCPServer, a framework for a TCP network service listening on a socket, accepting and servicing client connections.
I am an AbstractNetworkServer.
I fork a connection handler process to service each client.

Out of the box I implement an RFC 862 Echo service.

I am meant to be subclassed to implement other protocols. Consider overwriting almost any method, if needed.

Example:

	BasicTCPServer new start.
	
Implements and conforms to [Smoke Test] https://protohackers.com/problem/0

"
Class {
	#name : #BasicTCPServer,
	#superclass : #AbstractNetworkServer,
	#instVars : [
		'bindingAddress'
	],
	#category : #'Neo-Networking'
}

{ #category : #accessing }
BasicTCPServer >> acceptWaitTimeout [
	^ 300
]

{ #category : #accessing }
BasicTCPServer >> backlogSize [
	^ 10
]

{ #category : #accessing }
BasicTCPServer >> bindingAddress [
	^ bindingAddress
]

{ #category : #accessing }
BasicTCPServer >> bindingAddress: address [
	bindingAddress := address
]

{ #category : #protocol }
BasicTCPServer >> handleConnection: stream [
	"Echo all bytes read from the input side by writing them to the output side, according to RFC 862"

	[ stream atEnd ] whileFalse: [
		"Be extra careful, EOF is often only seen after reading"
		stream next ifNotNil: [ :byte |
			self log: [ 'Echoing byte: {1}' format: { byte } ].
			stream nextPut: byte; flush ] ]
]

{ #category : #private }
BasicTCPServer >> initializeServerSocket [
	serverSocket := Socket newTCP.
	serverSocket setOption: 'TCP_NODELAY' value: 1.
	bindingAddress
		ifNil: [
			serverSocket listenOn: self port backlogSize: self backlogSize ]
		ifNotNil: [
			serverSocket listenOn: self port backlogSize: self backlogSize interface: bindingAddress ].
	serverSocket isValid
		ifFalse: [ self error: 'Cannot create socket on port ' , self port printString ].
	self port isZero
		ifTrue: [ self log: ('OS assigned port = {1}' format: { serverSocket port }) ]
]

{ #category : #protocol }
BasicTCPServer >> listenLoop [
	"We create a listening Socket, then wait for a connection.
	After each connection we also check that the listening Socket is still valid
	- if not we just make a recursive call to this method to start over."

	self initializeServerSocket.
	[
		[
		serverSocket isValid
			ifFalse: [
				"will trigger #ifCurtailed: block and destroy socket"
				^ self listenLoop ].
		self serveConnectionOn: serverSocket ] repeat
	] ifCurtailed: [ self releaseServerSocket ]
]

{ #category : #private }
BasicTCPServer >> releaseServerSocket [
	(Delay forMilliseconds: 10) wait.
	serverSocket destroy.
	serverSocket := nil
]

{ #category : #protocol }
BasicTCPServer >> serveConnectionOn: listeningSocket [
	"We wait up to acceptWaitTimeout seconds for an incoming connection.
	If we get one we wrap it in a SocketStream and fork #handleConnection: on it"

	| stream socket |
	socket := listeningSocket waitForAcceptFor: self acceptWaitTimeout.
	socket ifNil: [ ^ self ].
	stream := self socketStreamOn: socket.
	[ [ [
			self log: 'Handling connection'.
			self handleConnection: stream ]
		ensure: [
			self log: 'Ending connection'.
			stream close ] ]
				ifCurtailed: [ socket destroy ] ]
					forkAt: self workerProcessPriority
					named: self workerProcessName
]

{ #category : #private }
BasicTCPServer >> socketStreamOn: socket [
	^ (ZdcSocketStream on: socket)
			timeout: self timeout;
			yourself
]

{ #category : #accessing }
BasicTCPServer >> workerProcessName [
	^ self serverProcessName, ' Connection Handler'
]

{ #category : #accessing }
BasicTCPServer >> workerProcessPriority [
	^ Processor lowIOPriority
]
