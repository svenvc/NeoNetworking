Class {
	#name : #ExamplePrimeTestServerTest,
	#superclass : #TestCase,
	#category : #'Neo-Networking'
}

{ #category : #tests }
ExamplePrimeTestServerTest >> testIsPrime [
	| server address port client number request response |
	server := ExamplePrimeTestServer new port: 0; start.
	address := NetNameResolver loopBackAddress.
	port := server actualPort.
	client := ZdcSocketStream openConnectionToHost: address port: port.
	number := (Integer primesUpTo: 100 + 1e3 atRandom) last.
	request := { #method -> #isPrime. #number -> number } asDictionary.
	(ZnCharacterWriteStream on: client) nextPutAll: (STONJSON toString: request); lf; flush.
	response := STONJSON fromString: (ZnCharacterReadStream on: client) nextLine.
	client close.
	server stop.
	self assert: (response at: #prime) equals: number isPrime
]

{ #category : #tests }
ExamplePrimeTestServerTest >> testIsPrimeRandom [
	| server address port client number request response |
	server := ExamplePrimeTestServer new port: 0; start.
	address := NetNameResolver loopBackAddress.
	port := server actualPort.
	client := ZdcSocketStream openConnectionToHost: address port: port.
	number := 1e6 atRandom.
	request := { #method -> #isPrime. #number -> number } asDictionary.
	(ZnCharacterWriteStream on: client) nextPutAll: (STONJSON toString: request); lf; flush.
	response := STONJSON fromString: (ZnCharacterReadStream on: client) nextLine.
	client close.
	server stop.
	self assert: (response at: #prime) equals: number isPrime
]
