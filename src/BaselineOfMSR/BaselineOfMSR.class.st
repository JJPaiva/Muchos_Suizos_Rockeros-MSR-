Class {
	#name : #BaselineOfMSR,
	#superclass : #BaselineOf,
	#category : #BaselineOfMSR
}

{ #category : #loading }
BaselineOfMSR class >> loadLepiter [
	IceRepository registry  
		detect: [ :aRepository |
			aRepository name = 'Muchos_Suizos_Rockeros-MSR-' ]
		ifFound: [ :aRepository | 
			| defaultDatabase currentProperties |
			defaultDatabase := LeDatabasesRegistry defaultLogicalDatabase.
			currentProperties := defaultDatabase properties.
			currentProperties addRegisteredDirectory: aRepository repositoryDirectory / 'lepiter'.
			defaultDatabase reload ]
		ifNone: [
			self inform: 'Repository not found.' ]
]

{ #category : #baseline }
BaselineOfMSR >> baseline: spec [
	<baseline>
		^ spec for: #common do: [
			spec package: 'MSR'
		]
]
