Class {
	#name : #ExampleAssetPricingServerTest,
	#superclass : #TestCase,
	#category : #'Neo-Networking'
}

{ #category : #tests }
ExampleAssetPricingServerTest >> testSimple [
	| server address port client command |
	server := ExampleAssetPricingServer new port: 0; start.
	address := NetNameResolver loopBackAddress.
	port := server actualPort.
	client := ZdcSocketStream openConnectionToHost: address port: port.
	#(($I 12345 101)($I 12346 102)($I 12347 100)($I 40960 5)($Q 12288 16384)) do: [ :each |
		command := ByteArray streamContents: [ :out |
			out nextPut: each first asInteger; int32: each second; int32: each third ].
		client nextPutAll: command; flush ].
	command := client next: 4.
	self assert: command readStream int32 equals: 101.
	client close.
	server stop
]
