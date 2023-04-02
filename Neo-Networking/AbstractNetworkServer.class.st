"
I am AbstractNetworkServer, a framework for a network service listening on a socket, accepting and servicing client connections.

I am meant to be subclassed to implement specific protocols. Consider overwriting almost every method, if needed.

I offer process management (start, stop), configuration (host, port), constansts and logging.

"
Class {
	#name : #AbstractNetworkServer,
	#superclass : #Object,
	#instVars : [
		'port',
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
AbstractNetworkServer class >> initialize [
	SessionManager default registerNetworkClassNamed: self name
]

{ #category : #accessing }
AbstractNetworkServer class >> managedServers [
	^ ManagedServers ifNil: [ ManagedServers := IdentitySet new ]
]

{ #category : #registry }
AbstractNetworkServer class >> register: server [
	"Arrange for server to be sent start/stop on system startUp/shutDown"

	self managedServers add: server
]

{ #category : #'system startup' }
AbstractNetworkServer class >> shutDown: quiting [
	"Our system shutDown hook: stop all servers we manage"

	quiting
		ifTrue: [
			self managedServers do: [ :each | each stop: false ] ]
]

{ #category : #public }
AbstractNetworkServer class >> startOn: port [
	"self startOn: 4999"

	^ self new
		port: port;
		start
]

{ #category : #'system startup' }
AbstractNetworkServer class >> startUp: resuming [
	"Our system startUp hook: start all servers we manage.
	We do this using deferred startup actions to allow normal error handling."

	resuming
		ifTrue: [
			SessionManager default currentSession addDeferredStartupAction: [
				self managedServers do: [ :each | each start ] ] ]
]

{ #category : #registry }
AbstractNetworkServer class >> unregister: server [
	"No longer send server start/stop on system startUp/shutDown"

	self managedServers remove: server ifAbsent: [ ]
]

{ #category : #accessing }
AbstractNetworkServer >> actualPort [
	^ self port isZero
		  ifTrue: [
			  self isRunning
				  ifTrue: [ serverSocket port ]
				  ifFalse: [ self error: 'not yet bound' ] ]
		  ifFalse: [ port ]
]

{ #category : #accessing }
AbstractNetworkServer >> defaultPort [
	^ 9999
]

{ #category : #testing }
AbstractNetworkServer >> isRunning [
	"Return true when I am running"

	^ process notNil and: [ serverSocket notNil ]
]

{ #category : #protocol }
AbstractNetworkServer >> listenLoop [
	self subclassResponsibility
]

{ #category : #private }
AbstractNetworkServer >> log: message [
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
AbstractNetworkServer >> port [
	^ port ifNil: [ port := self defaultPort ]
]

{ #category : #accessing }
AbstractNetworkServer >> port: integer [
	port := integer
]

{ #category : #printing }
AbstractNetworkServer >> printOn: stream [
	super printOn: stream.
	stream << $(.
	self isRunning
		ifTrue: [ stream << #running; space; print: self actualPort ]
		ifFalse: [ stream print: self port ].
	stream << $)
]

{ #category : #accessing }
AbstractNetworkServer >> serverProcessName [
	^ self class name asString , ' port ' , self port asString
]

{ #category : #accessing }
AbstractNetworkServer >> serverProcessPriority [
	^ Processor highIOPriority
]

{ #category : #public }
AbstractNetworkServer >> start [
	self start: false
]

{ #category : #public }
AbstractNetworkServer >> start: register [
	self stop.
	register ifTrue: [ self class register: self ].
	process := [ self listenLoop ]
		forkAt: self serverProcessPriority
		named: self serverProcessName.
	self log: ('Started {1}' format: { self serverProcessName })
]

{ #category : #public }
AbstractNetworkServer >> stop [
	self stop: false
]

{ #category : #public }
AbstractNetworkServer >> stop: unregister [
	unregister ifTrue: [ self class unregister: self ].
	self isRunning ifFalse: [ ^ self ].
	process terminate.
	process := nil.
	self log: ('Stopped {1}' format: { self serverProcessName })
]

{ #category : #accessing }
AbstractNetworkServer >> timeout [
	^ timeout ifNil: [ timeout := ZnNetworkingUtils socketStreamTimeout ]
]

{ #category : #accessing }
AbstractNetworkServer >> timeout: seconds [
	timeout := seconds
]
