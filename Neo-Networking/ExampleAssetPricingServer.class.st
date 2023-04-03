"
I am ExampleAssetPricingServer.
I am a BasicTCPServer.

Protocol

I <int32> <int32> - insert <timestamp> <price>
Q <int32> <int32> - query <mintime> <maxtime>

Implements and conforms to [Means to an End] https://protohackers.com/problem/2
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
	| bytes byteStream key first second |
	^ [
		bytes := stream next: 9.
		self log: [ 'Read command {1}' format: { bytes hex asUppercase } ].
		byteStream := bytes readStream.
		key := byteStream next.
		first := byteStream int32.
		second := byteStream int32.
		{ #key -> key asCharacter. #first -> first. #second -> second } asDictionary ]
			on: Error do: [ self log: 'Read empty command'. nil ]
]

{ #category : #protocol }
ExampleAssetPricingServer >> writeResponse: average to: stream [
	| response |
	response := ByteArray streamContents: [ :out |
		            out int32: average asFloat truncated ].
	stream nextPutAll: response; flush.
	self log: [ 'Wrote response {1}' format: { response hex } ]
]
