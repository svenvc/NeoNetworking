"
I am BasicTCPServer, a framework for a TCP network service listening on a socket, accepting and servicing client connections.

Out of the box I implement an RFC 862 Echo service.

I am meant to be subclassed to implement other protocols. Consider overwriting almost every method, if needed.

Example:

	BasicTCPServer new start.
	
Implements and conforms to [Smoke Test] https://protohackers.com/problem/0
	

"
Class {
	#name : #BasicTCPServer,
	#superclass : #Object,
	#instVars : [
		'port',
		'bindingAddress',
		'timeout',
		'process',
		'serverSocket'
	],
	#classVars : [
		'ManagedServers'
	],
	#category : #'Neo-Networking'
}

{ #category : #'class initialization' }
BasicTCPServer class >> initialize [
	SessionManager default registerNetworkClassNamed: self name
]

{ #category : #accessing }
BasicTCPServer class >> managedServers [
	^ ManagedServers ifNil: [ ManagedServers := IdentitySet new ]
]

{ #category : #registry }
BasicTCPServer class >> register: server [
	"Arrange for server to be sent start/stop on system startUp/shutDown"

	self managedServers add: server
]

{ #category : #'system startup' }
BasicTCPServer class >> shutDown: quiting [
	"Our system shutDown hook: stop all servers we manage"

	quiting
		ifTrue: [
			self managedServers do: [ :each | each stop: false ] ]
]

{ #category : #public }
BasicTCPServer class >> startOn: port [
	"self startOn: 4999"

	^ self new
		port: port;
		start
]

{ #category : #'system startup' }
BasicTCPServer class >> startUp: resuming [
	"Our system startUp hook: start all servers we manage.
	We do this using deferred startup actions to allow normal error handling."

	resuming
		ifTrue: [
			SessionManager default currentSession addDeferredStartupAction: [
				self managedServers do: [ :each | each start ] ] ]
]

{ #category : #registry }
BasicTCPServer class >> unregister: server [
	"No longer send server start/stop on system startUp/shutDown"

	self managedServers remove: server ifAbsent: [ ]
]

{ #category : #accessing }
BasicTCPServer >> acceptWaitTimeout [
	^ 300
]

{ #category : #accessing }
BasicTCPServer >> actualPort [
	^ self port isZero
		  ifTrue: [
			  self isRunning
				  ifTrue: [ serverSocket port ]
				  ifFalse: [ self error: 'not yet bound' ] ]
		  ifFalse: [ port ]
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

{ #category : #accessing }
BasicTCPServer >> defaultPort [
	^ 9999
]

{ #category : #protocol }
BasicTCPServer >> handleConnection: stream [
	"Echo all bytes read from the input side by writing them to the output side, according to RFC 862"

	[ stream atEnd ] whileFalse: [
		"Be extra careful, EOF is often only seen after reading"
		stream next ifNotNil: [ :byte |
			self log: ('Echoing byte: {1}' format: { byte }).
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

{ #category : #testing }
BasicTCPServer >> isRunning [
	"Return true when I am running"

	^ process notNil and: [ serverSocket notNil ]
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
BasicTCPServer >> log: message [
	| now |
	now := DateAndTime now.
	(String streamContents: [ :out |
		now printYMDOn: out.
		out space.
		now printHMSOn: out.
		out nextPut: $..
		out nextPutAll: ((now nanoSecond // 1e6) printPaddedWith: $0 to: 3).
		out space.
		Processor activeProcess hash printOn: out base: 36 length: 6 padded: true.
		out space.
		out nextPutAll: message ]) traceCr
]

{ #category : #accessing }
BasicTCPServer >> port [
	^ port ifNil: [ port := self defaultPort ]
]

{ #category : #accessing }
BasicTCPServer >> port: integer [
	port := integer
]

{ #category : #printing }
BasicTCPServer >> printOn: stream [
	super printOn: stream.
	stream << $(.
	self isRunning
		ifTrue: [ stream << #running; space; print: self actualPort ]
		ifFalse: [ stream print: self port ].
	stream << $)
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

{ #category : #accessing }
BasicTCPServer >> serverProcessName [
	^ self class name asString , ' port ' , self port asString
]

{ #category : #accessing }
BasicTCPServer >> serverProcessPriority [
	^ Processor highIOPriority
]

{ #category : #private }
BasicTCPServer >> socketStreamOn: socket [
	^ (ZdcSocketStream on: socket)
			timeout: self timeout;
			yourself
]

{ #category : #public }
BasicTCPServer >> start [
	self start: false
]

{ #category : #public }
BasicTCPServer >> start: register [
	self stop.
	register ifTrue: [ self class register: self ].
	process := [ self listenLoop ]
		forkAt: self serverProcessPriority
		named: self serverProcessName.
	self log: ('Started {1}' format: { self serverProcessName })
]

{ #category : #public }
BasicTCPServer >> stop [
	self stop: false
]

{ #category : #public }
BasicTCPServer >> stop: unregister [
	unregister ifTrue: [ self class unregister: self ].
	self isRunning ifFalse: [ ^ self ].
	process terminate.
	process := nil.
	self log: ('Stopped {1}' format: { self serverProcessName })
]

{ #category : #accessing }
BasicTCPServer >> timeout [
	^ timeout ifNil: [ timeout := ZnNetworkingUtils socketStreamTimeout ]
]

{ #category : #accessing }
BasicTCPServer >> timeout: seconds [
	timeout := seconds
]

{ #category : #accessing }
BasicTCPServer >> workerProcessName [
	^ self serverProcessName, ' Connection Handler'
]

{ #category : #accessing }
BasicTCPServer >> workerProcessPriority [
	^ Processor lowIOPriority
]
