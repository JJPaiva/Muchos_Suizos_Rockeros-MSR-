Class {
	#name : #ChatGPTConversation,
	#superclass : #Object,
	#instVars : [
		'model',
		'repoLanguage',
		'promptTokens',
		'answerTokens',
		'promptText',
		'answerText',
		'codeBlocks'
	],
	#category : #'MSR-Model'
}

{ #category : #'as yet unclassified' }
ChatGPTConversation >> answerText [
	^ answerText
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> answerText: aString [
	answerText := aString
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> answerTokens [
	^ answerTokens
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> answerTokens: anInteger [
	answerTokens := anInteger
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> codeBlocks [
	^ codeBlocks
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> codeBlocks: aCollection [
	codeBlocks := aCollection
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> gtViewConversationDetailsFor: aView [
	<gtView>
	^ aView text
		title: 'Conversation Text';
		priority: 1;
		text: [ 
			'MODEL: ', self model asString, String cr,
			'REPO: ', self repoLanguage asString, String cr,
			'-------------------------------------------', String cr,
			
			"Aquí agregamos el conteo de caracteres y tokens al título del Prompt"
			'PROMPT (', self promptText size asString, ' chars / ', self promptTokens asString, ' tokens):', String cr, 
			self promptText asString, String cr, String cr, 
			
			'-------------------------------------------', String cr,
			
			"Aquí agregamos lo mismo para el Answer"
			'ANSWER (', self answerText size asString, ' chars / ', self answerTokens asString, ' tokens):', String cr, 
			self answerText asString 
		]
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> model [
	^ model
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> model: aString [
	model := aString
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> printOn: aStream [
	super printOn: aStream.
	aStream nextPut: $(.
	aStream nextPutAll: (self model ifNil: ['Unknown']).
	aStream nextPut: $).
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> promptText [
	^ promptText
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> promptText: aString [
	promptText := aString
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> promptTokens [
	^ promptTokens
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> promptTokens: anInteger [
	promptTokens := anInteger
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> repoLanguage [
	^ repoLanguage
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> repoLanguage: aString [
	repoLanguage := aString
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> totalCodeLength [
	^ self codeBlocks inject: 0 into: [ :sum :each | sum + each length ]
]

{ #category : #'as yet unclassified' }
ChatGPTConversation >> totalTokens [
	^ self promptTokens + self answerTokens
]
