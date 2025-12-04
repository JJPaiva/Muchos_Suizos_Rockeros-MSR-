Class {
	#name : #ChatGPTCodeBlock,
	#superclass : #Object,
	#instVars : [
		'type',
		'content'
	],
	#category : #'MSR-Model'
}

{ #category : #'as yet unclassified' }
ChatGPTCodeBlock >> content [
	^ content
]

{ #category : #'as yet unclassified' }
ChatGPTCodeBlock >> content: aString [
	content := aString
]

{ #category : #'as yet unclassified' }
ChatGPTCodeBlock >> length [
	^ content ifNil: [ 0 ] ifNotNil: [ content size ]
]

{ #category : #'as yet unclassified' }
ChatGPTCodeBlock >> type [
	^ type
]

{ #category : #'as yet unclassified' }
ChatGPTCodeBlock >> type: aString [
	type := aString
]
