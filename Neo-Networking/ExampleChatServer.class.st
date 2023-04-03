"
I am ExampleChatServer, implementing a simple chat room.
I am a BasicTCPServer.

Implements and conforms to [Budget Chat] https://protohackers.com/problem/3
"
Class {
	#name : #ExampleChatServer,
	#superclass : #BasicTCPServer,
	#instVars : [
		'chatRoom',
		'access'
	],
	#category : #'Neo-Networking'
}

{ #category : #protocol }
ExampleChatServer >> enter: handle with: outputStream [
	access critical: [
		self writeLine: ('* Present in the chat room are: {1}' format: { $, join: chatRoom keys }) to: outputStream.
		chatRoom valuesDo: [ :out |
			self writeLine: ('* {1} has entered the chat room' format: { handle }) to: out ].
		chatRoom at: handle put: outputStream ]
]

{ #category : #protocol }
ExampleChatServer >> handleConnection: stream [
	| input output handle message |
	input := ZnCharacterReadStream on: stream.
	output := ZnCharacterWriteStream on: stream.
	self writeLine: 'Welcome to the chat room. Please enter your handle (name/id):' to: output.
	((handle := self readLineFrom: input) isEmptyOrNil not and: [ handle allSatisfy: #isAlphaNumeric ])
		ifTrue: [ self enter: handle with: output ]
		ifFalse: [ ^ self ].
	[ (message := self readLineFrom: input) isNil ] whileFalse: [
		access critical: [
			chatRoom keysAndValuesDo: [ :key :value |
				key = handle ifFalse: [
					self writeLine: ('[{1}] {2}' format: { handle. message }) to: value ] ] ] ].
	self leave: handle
]

{ #category : #initialization }
ExampleChatServer >> initialize [
	super initialize.
	chatRoom := Dictionary new.
	access := Monitor new
]

{ #category : #protocol }
ExampleChatServer >> leave: handle [
	access critical: [
		chatRoom removeKey: handle.
		chatRoom valuesDo: [ :out |
			self writeLine: ('* {1} has left the chat room' format: { handle }) to: out ] ]
]

{ #category : #protocol }
ExampleChatServer >> readLineFrom: input [
	| line |
	line := nil.
	[ line := [ [ input nextLine ]
		on: ConnectionTimedOut do: [ #continue ] ]
			on: Error do: [ nil ].
		line = #continue ] whileTrue.
	self log: [ 'Read {1}' format: { line } ].
	^ line
]

{ #category : #public }
ExampleChatServer >> stop: boolean [
	super stop: boolean.
	chatRoom removeAll
]

{ #category : #protocol }
ExampleChatServer >> writeLine: line to: output [
	self log: [ 'Wrote {1}' format: { line } ].
	^ [ output nextPutAll: line; lf; flush ] on: Error do: [ nil ]
]
