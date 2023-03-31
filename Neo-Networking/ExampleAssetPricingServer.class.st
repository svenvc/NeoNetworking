"
I am ExampleAssetPricingServer.
I am a BasicTCPServer.

Protocol

I <int32> <int32> - insert <timestamp> <price>
Q <int32> <int32> - query <mintime> <maxtime>
"
Class {
	#name : #ExampleAssetPricingServer,
	#superclass : #BasicTCPServer,
	#category : #'Neo-Networking'
}

{ #category : #protocol }
ExampleAssetPricingServer >> handleConnection: stream [
	| data command subset average |
	data := OrderedCollection new.
	[ stream atEnd ] whileFalse: [
		(command := self readCommand: stream) ifNil: [ ^ self ].
		(command at: #key) = $I
			ifTrue: [
				data add: ((command at: #first) -> (command at: #second)) ].
		(command at: #key) = $Q
			ifTrue: [
				subset := data
					select: [ :each | each key between: (command at: #first) and: (command at: #second) ]
					thenCollect: [ :each | each value ].
				average := subset isEmpty ifTrue: [ 0 ] ifFalse: [ subset average ].
				self writeResponse: average to: stream ] ]
]

{ #category : #protocol }
ExampleAssetPricingServer >> readCommand: stream [
	| bytes key first second |
	^ [
		bytes := (stream next: 9) readStream.
		"self log: ('Read command: {1}' format: { bytes hex })."
		key := bytes next.
		first := bytes int32.
		second := bytes int32.
		{ #key -> key asCharacter. #first -> first. #second -> second } asDictionary ]
			on: Error do: [ "self log: 'Read command: nil'." nil ]
]

{ #category : #writing }
ExampleAssetPricingServer >> writeResponse: average to: stream [
	| response |
	response := ByteArray streamContents: [ :out |
		            out int32: average asFloat truncated ].
	stream nextPutAll: response; flush.
	self log: ('Wrote response: {1}' format: { response hex })
]
