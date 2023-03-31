"
I am ExamplePrimeTestServer, implementing a JSON protocol for test if a number is a prime.
I am a BasicTCPServer.

Request

    {""method"":""isPrime"",""number"":123}

Response

    {""method"":""isPrime"",""prime"":false}
"
Class {
	#name : #ExamplePrimeTestServer,
	#superclass : #BasicTCPServer,
	#category : #'Neo-Networking'
}

{ #category : #protocol }
ExamplePrimeTestServer >> baseResponse [
	^ { #method -> #isPrime } asOrderedDictionary
]

{ #category : #protocol }
ExamplePrimeTestServer >> errorResponse: errorMessage [
	^ self baseResponse
			at: #error put: errorMessage;
			yourself
]

{ #category : #protocol }
ExamplePrimeTestServer >> handleConnection: stream [
	| input output line json response |
	input := ZnCharacterReadStream on: stream.
	output := ZnCharacterWriteStream on: stream.
	[ (line := self readLineFrom: input) isNil ] whileFalse: [
		json := [ STONJSON fromString: line ] on: STONReaderError do: [ nil ].
		response := self handleIsPrimeRequest: json.
		self writeLine: (STONJSON toString: response) to: output.
		(response includesKey: #error) ifTrue: [ ^ self ] ]
]

{ #category : #protocol }
ExamplePrimeTestServer >> handleIsPrimeRequest: json [
	| number |
	json isDictionary
		ifFalse: [ ^ self errorResponse: 'Invalid JSON' ].
	(json at: #method ifAbsent: [ nil ]) = #isPrime
		ifFalse: [ ^ self errorResponse: 'Unsupported method' ].
	(number := json at: #number ifAbsent: [ nil ]) isInteger
		ifFalse: [ ^ self errorResponse: 'Number must be an integer' ].
	^ self resultResponse: (number positive and: [ number isPrime ])
]

{ #category : #protocol }
ExamplePrimeTestServer >> readLineFrom: input [
	| line |
	line := [ input nextLine ] on: Error do: [ nil ].
	self log: ('Read line: {1}' format: { line }).
	^ line
]

{ #category : #protocol }
ExamplePrimeTestServer >> resultResponse: boolean [
	^ self baseResponse
			at: #prime put: boolean;
			yourself
]

{ #category : #protocol }
ExamplePrimeTestServer >> writeLine: line to: output [
	self log: ('Wrote line: {1}' format: { line }).
	^ [ output nextPutAll: line; lf; flush ] on: Error do: [ nil ]
]
