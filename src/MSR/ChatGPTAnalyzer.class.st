Class {
	#name : #ChatGPTAnalyzer,
	#superclass : #Object,
	#instVars : [
		'jsonData',
		'repoTokensData',
		'repoData',
		'conversations'
	],
	#category : #'MSR-Model'
}

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> conversations [
	^ conversations
]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> gtBoxesFor: aView [
	<gtView>
	| mainContainer zoomable |
	(conversations isNil or: [ conversations isEmpty ]) ifTrue: [ ^ aView empty ].

	mainContainer := BlElement new
		layout: BlFlowLayout new;
		size: 8000 @ 22000; 
		yourself.

	conversations do: [ :conv |
		| box color width height modelStr |
		
		"Tus cálculos originales..."
		width := (conv answerText size max: 10) min: 500.
		height := (conv promptText size max: 10) min: 400.
		
		modelStr := conv model trim asLowercase.
		color := (modelStr includesSubstring: 'gpt-4') 
			ifTrue: [ Color green ]
			ifFalse: [ (modelStr includesSubstring: '3.5') 
				ifTrue: [ Color blue ] 
				ifFalse: [ Color lightGray ] ].

		box := BlElement new
			size: width @ height;
			background: color;
			border: (BlBorder paint: Color black width: 2);
			margin: (BlInsets all: 5);
			yourself.
		
		"--- AQUÍ ESTÁ LA MAGIA ---"
		"Al hacer click, inspeccionamos el objeto conversación individual"
		box when: BlClickEvent do: [ :e | 
			e target phlow spawnObject: conv 
		].
		"--------------------------"
			
		mainContainer addChild: box.
	].

	zoomable := BlZoomableElement new
		contentElement: mainContainer;
		yourself.

	^ aView explicit
		title: 'Conversations Map';
		priority: 1;
		stencil: [ zoomable asPannableElement ]
]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> gtCodeLanguagesFor: aView [
	<gtView>
	| stats |
	stats := Dictionary new.
	
	conversations do: [ :conv |
		conv codeBlocks do: [ :block |
			| currentCount |
			"Obtenemos el valor actual, si no existe devuelve 0"
			currentCount := stats at: block type ifAbsent: [ 0 ].
			"Guardamos el valor sumado + 1"
			stats at: block type put: currentCount + 1
		]
	].
	
	^ aView columnedList
		title: 'Code Languages';
		priority: 20;
		items: [ stats associations asSortedCollection: [:a :b | a value > b value] ];
		column: 'Language' text: [ :assoc | assoc key ];
		column: 'Count' text: [ :assoc | assoc value asString ]
]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> gtModelsTableFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Models & Code Gen';
		priority: 10;
		items: [ conversations asSortedCollection: [ :a :b | a totalCodeLength > b totalCodeLength ] ];
		column: 'Model' text: [ :each | each model ];
		column: 'Code Length (chars)' text: [ :each | each totalCodeLength asString ];
		column: 'Code Blocks' text: [ :each | each codeBlocks size asString ];
		column: 'Prompt Length' text: [ :each | each promptText size asString ]
]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> gtRepoTokensFor: aView [
	<gtView>
	| repoStats |
	repoStats := Dictionary new.
	
	conversations do: [ :conv |
		| lang currentDict |
		lang := conv repoLanguage.
		currentDict := repoStats at: lang ifAbsentPut: [ 
			Dictionary newFrom: { #prompts -> 0 . #answers -> 0 } 
		].
		
		currentDict at: #prompts put: ((currentDict at: #prompts) + conv promptTokens).
		currentDict at: #answers put: ((currentDict at: #answers) + conv answerTokens).
	].

	^ aView columnedList
		title: 'Repo Tokens';
		priority: 30;
		items: [ repoStats associations asSortedCollection: [ :a :b | 
			((a value at: #prompts) + (a value at: #answers)) > 
			((b value at: #prompts) + (b value at: #answers)) ] ];
		column: 'Repo Language' text: [ :assoc | assoc key ];
		column: 'Total Prompts' text: [ :assoc | (assoc value at: #prompts) asString ];
		column: 'Total Answers' text: [ :assoc | (assoc value at: #answers) asString ];
		column: 'Grand Total' text: [ :assoc | ((assoc value at: #prompts) + (assoc value at: #answers)) asString ]
]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> initialize [
	conversations := OrderedCollection new.
]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> loadFromJsonFile: fileName [
	| jsonFile parsedJson |
	
	jsonFile := fileName asFileReference.
	parsedJson := STONJSON fromString: jsonFile contents.
	conversations := OrderedCollection new.

	parsedJson at: 'Sources' ifPresent: [ :sourcesArray |
		sourcesArray do: [ :sourceDict |
			| currentRepoLang |
			currentRepoLang := sourceDict at: 'RepoLanguage' ifAbsent: [ 'Unknown' ].

			sourceDict at: 'ChatgptSharing' ifPresent: [ :sharingArray |
				sharingArray do: [ :sharingDict |
					| currentModel pTokens aTokens sharingConversations |
					
					currentModel := sharingDict at: 'Model' ifAbsent: [ 'Unknown' ].
					pTokens := sharingDict at: 'TokensOfPrompts' ifAbsent: [ 0 ].
					aTokens := sharingDict at: 'TokensOfAnswers' ifAbsent: [ 0 ].
					sharingConversations := sharingDict at: 'Conversations' ifAbsent: [ #() ].

					sharingConversations do: [ :convDict |
						| newConv rawCodeList newCodeBlocks |
						
						newConv := ChatGPTConversation new.
						newConv repoLanguage: currentRepoLang.
						newConv model: currentModel.
						newConv promptTokens: pTokens.
						newConv answerTokens: aTokens.
						newConv promptText: (convDict at: 'Prompt' ifAbsent: ['']).
						newConv answerText: (convDict at: 'Answer' ifAbsent: ['']).
						
						"Procesar bloques de código"
						rawCodeList := convDict at: 'ListOfCode' ifAbsent: [ #() ].
						newCodeBlocks := rawCodeList collect: [ :codeDict |
							ChatGPTCodeBlock new
								type: (codeDict at: 'Type' ifAbsent: ['text']);
								content: (codeDict at: 'Content' ifAbsent: ['']);
								yourself
						].
						newConv codeBlocks: newCodeBlocks.
						
						conversations add: newConv.
					].
				].
			].
		].
	].
	^ conversations
]
