Class {
	#name : #ChatGPTAnalyzer,
	#superclass : #Object,
	#instVars : [
		'jsonData',
		'repoTokensData',
		'repoData'
	],
	#category : #'MSR-Model'
}

{ #category : #accessing }
ChatGPTAnalyzer >> analyzeFromJsonFile: fileName [
	| jsonFile parsedJson conversations repos |

	"Limpiar datos anteriores para evitar acumulación"
	self instVarNamed: 'jsonData' put: nil.
	self instVarNamed: 'repoData' put: nil.

	jsonFile := fileName asFileReference.
	parsedJson := STONJSON fromString: jsonFile contents.

	conversations := OrderedCollection new.
	repos := OrderedCollection new.

	parsedJson at: 'Sources' ifPresent: [ :sourcesArray |
		sourcesArray do: [ :sourceDict |

			| repoLanguage totalPromptTokens totalAnswerTokens modelSet |

			repoLanguage := sourceDict at: 'RepoLanguage' ifAbsent: [ 'Unknown' ].
			totalPromptTokens := 0.
			totalAnswerTokens := 0.
			modelSet := Set new.

			sourceDict at: 'ChatgptSharing' ifPresent: [ :sharingArray |
				sharingArray do: [ :sharingDict |

					| model tokensPrompt tokensAnswer |

					model := sharingDict at: 'Model' ifAbsent: [ 'Unknown' ].
					modelSet add: model.

					tokensPrompt := sharingDict at: 'TokensOfPrompts' ifAbsent: [ 0 ].
					tokensAnswer := sharingDict at: 'TokensOfAnswers' ifAbsent: [ 0 ].

					totalPromptTokens := totalPromptTokens + tokensPrompt.
					totalAnswerTokens := totalAnswerTokens + tokensAnswer.

					"Agregar cada conversación individual a jsonData"
					(sharingDict at: 'Conversations' ifAbsent: [ #() ]) do: [ :conversation |
						conversations add: (Dictionary newFrom: {
							#ListOfCode -> (conversation at: 'ListOfCode' ifAbsent: [ #() ]).
							#Answer -> (conversation at: 'Answer' ifAbsent: [ '' ]).
							#Prompt -> (conversation at: 'Prompt' ifAbsent: [ '' ]).
							#Model -> model.
							#RepoLanguage -> repoLanguage.
						})
					].
				].
			].

			"Agregar un resumen por repositorio a repoData"
			repos add: (Dictionary newFrom: {
				#RepoLanguage -> repoLanguage.
				#TotalPromptTokens -> totalPromptTokens.
				#TotalAnswerTokens -> totalAnswerTokens.
				#TotalTokens -> (totalPromptTokens + totalAnswerTokens).
				#Models -> modelSet asArray.
				#ChatgptSharingCount -> ((sourceDict at: 'ChatgptSharing' ifAbsent: [ #() ]) size).
			}).
		].
	].

	"Guardar resultados en las variables de instancia"
	self instVarNamed: 'jsonData' put: conversations.
	self instVarNamed: 'repoData' put: repos.

	^ conversations

]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> gtCodeTypeCountFor: aView [
	<gtView>
	| typeCounts |

	typeCounts := Dictionary new.

	self jsonData do: [ :each |
		(each isDictionary and: [ each includesKey: 'ListOfCode' ]) ifTrue: [
			| list |
			list := each at: 'ListOfCode'.

			(list isCollection) ifTrue: [
				list do: [ :item |
					(item isDictionary and: [ item includesKey: 'Type' ]) ifTrue: [
						| type |
						type := item at: 'Type'.
						typeCounts at: type ifAbsentPut: [ 0 ].
						typeCounts at: type put: ((typeCounts at: type) + 1)
					]
				]
			]
		]
	].

	^ aView columnedList
		title: 'Language Usage Count';
		priority: 130;
		items: [ 
			typeCounts associations
				asSortedCollection: [ :a :b | a value > b value ]  "orden descendente"
		];
		column: 'Lenguaje' text: [ :assoc | assoc key ];
		column: 'Veces Repetido' text: [ :assoc | assoc value asString ].

]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> gtModelCountFor: aView [
	<gtView>
	| modelCounts |

	modelCounts := Dictionary new.

	self jsonData do: [ :each |
		(each isDictionary and: [ each includesKey: 'Model' ]) ifTrue: [
			| model |
			model := each at: 'Model'.
			modelCounts at: model ifAbsentPut: [ 0 ].
			modelCounts at: model put: ((modelCounts at: model) + 1)
		]
	].

	^ aView columnedList
		title: 'Model Usage Count';
		priority: 120;
		items: [ 
			modelCounts associations
				asSortedCollection: [ :a :b | a value > b value ] "orden descendente"
		];
		column: 'Model' text: [ :assoc | assoc key ];
		column: 'Veces Repetido' text: [ :assoc | assoc value asString ].

]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> gtModelsFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Models';
		priority: 100;
		items: [ 
			| data |
			data := self jsonData.

			"Ordenar de forma descendente por total de caracteres en ListOfCode"
			data asSortedCollection: [ :a :b |
				| charsA charsB |
				charsA := (a isDictionary and: [ a includesKey: 'ListOfCode' ])
					ifTrue: [
						| list |
						list := a at: 'ListOfCode'.
						(list isCollection)
							ifTrue: [ 
								list inject: 0 into: [ :sum :item | 
									(item isDictionary and: [ item includesKey: 'Content' ])
										ifTrue: [ sum + ((item at: 'Content') size) ]
										ifFalse: [ sum ] ] ]
							ifFalse: [ 0 ]
					]
					ifFalse: [ 0 ].

				charsB := (b isDictionary and: [ b includesKey: 'ListOfCode' ])
					ifTrue: [
						| list |
						list := b at: 'ListOfCode'.
						(list isCollection)
							ifTrue: [ 
								list inject: 0 into: [ :sum :item | 
									(item isDictionary and: [ item includesKey: 'Content' ])
										ifTrue: [ sum + ((item at: 'Content') size) ]
										ifFalse: [ sum ] ] ]
							ifFalse: [ 0 ]
					]
					ifFalse: [ 0 ].

				"Descendente: el mayor primero"
				charsA > charsB
			]
		];

		"Columna Model"
		column: 'Model' text: [ :each | 
			(each isDictionary and: [ each includesKey: 'Model' ])
				ifTrue: [ each at: 'Model' ]
				ifFalse: [ 'Unknown' ] ];

		"Columna Answer (chars)"
		column: 'Answer (chars)' text: [ :each | 
			(each isDictionary and: [ each includesKey: 'Answer' ])
				ifTrue: [ 
					| answer |
					answer := each at: 'Answer'.
					(answer isString)
						ifTrue: [ answer size asString ]
						ifFalse: [ 'N/A' ]
				]
				ifFalse: [ 'Unknown' ] ];

		"Columna Prompt (chars)"
		column: 'Prompt (chars)' text: [ :each |
			(each isDictionary and: [ each includesKey: 'Prompt' ])
				ifTrue: [ 
					| prompt |
					prompt := each at: 'Prompt'.
					(prompt isString)
						ifTrue: [ prompt size asString ]
						ifFalse: [ 'N/A' ]
				]
				ifFalse: [ 'Unknown' ] ];

		"Columna ListOfCode (chars)"
		column: 'ListOfCode (chars)' text: [ :each |
			(each isDictionary and: [ each includesKey: 'ListOfCode' ])
				ifTrue: [ 
					| list totalChars |
					list := each at: 'ListOfCode'.
					(list isCollection)
						ifTrue: [ 
							totalChars := list
								inject: 0
								into: [ :sum :item | 
									(item isDictionary and: [ item includesKey: 'Content' ])
										ifTrue: [ sum + ((item at: 'Content') size) ]
										ifFalse: [ sum ] ].
							list size asString , ' items / ' , totalChars asString , ' chars'
						]
						ifFalse: [ 'N/A' ]
				]
				ifFalse: [ 'Unknown' ] ].

]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> gtRepoTokensFor: aView [
	<gtView>
	| groupedData |
	
	"Agrupar los datos por lenguaje"
	groupedData := Dictionary new.
	self repoData do: [ :each |
		| lang prompts answers current |
		lang := (each at: #RepoLanguage ifAbsent: [ 'Unknown' ]) asString.
		prompts := each at: #TotalPromptTokens ifAbsent: [ 0 ]. "Corregido: clave correcta"
		answers := each at: #TotalAnswerTokens ifAbsent: [ 0 ]. "Corregido: clave correcta"
		current := groupedData at: lang ifAbsentPut: [ Dictionary newFrom: {
			#RepoLanguage -> lang.
			#TotalPrompts -> 0.
			#TotalAnswers -> 0.
		} ].
		current at: #TotalPrompts put: (current at: #TotalPrompts) + prompts.
		current at: #TotalAnswers put: (current at: #TotalAnswers) + answers.
	].

	"Mostrarlo en tabla ordenada por total de tokens (Prompt + Answer)"
	^ aView columnedList
		title: 'Repo Tokens';
		priority: 120;
		items: [ 
			(groupedData values
				asSortedCollection: [ :a :b | 
					((a at: #TotalPrompts) + (a at: #TotalAnswers))
						> ((b at: #TotalPrompts) + (b at: #TotalAnswers))
				])
		];
		column: 'Repo Language' text: [ :each | each at: #RepoLanguage ];
		column: 'Prompt Tokens' text: [ :each | (each at: #TotalPrompts) asString ];
		column: 'Answer Tokens' text: [ :each | (each at: #TotalAnswers) asString ];
		column: 'Total Tokens' text: [ :each | 
			((each at: #TotalPrompts) + (each at: #TotalAnswers)) asString ].
]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> gtUniqueRepoLanguageCountFor: aView [
	<gtView>
	| groupedData |

	groupedData := Dictionary new.
	self repoData do: [ :each |
		| lang count |
		lang := (each at: #RepoLanguage ifAbsent: [ 'Unknown' ]) asString.
		count := groupedData at: lang ifAbsentPut: [ 0 ].
		groupedData at: lang put: count + 1.
	].

	^ aView columnedList
		title: 'RepoCount';
		priority: 200;
		items: [ 
			(groupedData associations
				asSortedCollection: [ :a :b | a value > b value ])
		];
		column: 'Repo Language' text: [ :each | each key ];
		column: 'Count' text: [ :each | each value asString ].

]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> jsonData [
	^ jsonData
]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> jsonData: anObject [
	jsonData := anObject
]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> loadFromFile: fileName [
	jsonData := self analyzeFromJsonFile: fileName
]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> removeKey: anObject ifAbsent: anObject1 [ 
]

{ #category : #'as yet unclassified' }
ChatGPTAnalyzer >> repoData [
	^ repoData
]
