"
I encapsulate basic behavior of a web-based API endpoint.

An endpoint object is meant to capture a specific functionality or a limited set of similar functionalities of a web-based service. In the simplest form an endpoint: 
	a) captures approapriate request parameters (e.g. using instance variables); 
	b) defines messages that execute various aspects of the endpoint;
	c) defines messages that instantiate other endpoints.
	
For example, a RESTful endpoint would capture nouns in instance variables and define verbs in terms of various messages.

I work in tandem with ==WSClient== to configure an http transport and execute requests. There's also ==WSPluggableEndpoint== which is commonly used for scripting.

Instance Variables
	wsClient:		<WSClient>

Example:

[[[
			Object subclass: #MyEndpoint
				uses: TWSEndpoint
				instanceVariableNames: 'query limit'
				classVariableNames: ''
				package: 'MyPackage'
				
			MyEndoint class>>endpointPath
				^ Path / 'search'
				
			MyEndpoint>>configureOn: http
				http addQuery: { #query -> query. #limit -> limit } asDictionary.

			MyEndpoint>>search
				<get>
				^ self execute
]]]

A few pointers when subclassing:
	1. On the class side define #endpointPath that returns a path relative to ==WSClient>>baseUrl==. This is required for organizational reason. You can override this on the instance side.
	2. Optionally, override #configureOn: to configure HTTP prior to executing requests.
	3. When defining request-executing methods: 
		- include pragma for the HTTP method to be used: e.g. <get> (List of valid method symbols is defined in ==WSClient class>>#supportedHttpMethods)
		- optionally, you can override the final request path using <path: '/some/path'> pragma.
		- be sure to call #execute at some point - that will prepare and execute appropriate HTTP request. 
	   
"
Trait {
	#name : #TWSEndpoint,
	#instVars : [
		'wsClient'
	],
	#category : #'Ethel-Core'
}

{ #category : #'accessing-context' }
TWSEndpoint classSide >> endpointParamsPragma [
	"By default retuns keywords defined by the framework, but can be overriden at the level of the endpoint itself"
	^ WSClient endpointParamsPragma 
]

{ #category : #accessing }
TWSEndpoint classSide >> endpointPath [
	"Path that represents a logical endpoint whose behavior is encapsulated by the implementing class. In cases where this cannot be determined at the class level - simply return the top-most meaingful path, or the root path. TThis value can be overriden in two places: 1) instance side #endpointPath and 2) at a method level by declarating there a pragma with the keyword returned by #endpointPathPragma"
	^ self subclassResponsibility
]

{ #category : #'accessing-context' }
TWSEndpoint classSide >> endpointPathPragma [
	"By default retuns keywords defined by the framework, but can be overriden at the level of the endpoint itself"
	^ WSClient endpointPathPragma 
]

{ #category : #'instance creation' }
TWSEndpoint classSide >> on: wsClient [
	^ self basicNew initializeOn: wsClient
]

{ #category : #accessing }
TWSEndpoint classSide >> pathReferences [
	^ (self wsEndpointExecutingMethods
		collect: [ :aMethod | aMethod -> (aMethod wsEndpointPath) ])
		asSet
]

{ #category : #'accessing-context' }
TWSEndpoint classSide >> supportedHttpMethods [
	^ WSClient supportedHttpMethods 
]

{ #category : #icons }
TWSEndpoint classSide >> systemIconName [
	^ self isTrait
		ifTrue: [ super systemIconName ]
		ifFalse: [ #hierarchy ]
]

{ #category : #endpoints }
TWSEndpoint >> / aStringOrEndpoint [
	| ep |

	ep := aStringOrEndpoint isWSEndpoint
		ifTrue: [ self wsClient / aStringOrEndpoint ]
		ifFalse: [ | path |

			path := (aStringOrEndpoint isKindOf: Path)
				ifTrue: [ self endpointPath resolvePath: aStringOrEndpoint ]
				ifFalse: [ self endpointPath / aStringOrEndpoint ].
			self wsClient / path ].
	self configureDerivedEndpoint: ep.
	^ ep
]

{ #category : #configuring }
TWSEndpoint >> configureDerivedEndpoint: anEndpoint [
	"Configures newly derived endpoint"
]

{ #category : #configuring }
TWSEndpoint >> configureOn: http [
	"Configures http transport prior to execution"
]

{ #category : #accessing }
TWSEndpoint >> endpointPath [
	^ self class endpointPath 
]

{ #category : #executing }
TWSEndpoint >> execute [
	^ self execute: nil
]

{ #category : #executing }
TWSEndpoint >> execute: anExecBlock [
	^ wsClient execute: self with: anExecBlock 
]

{ #category : #executing }
TWSEndpoint >> executingContext [
	| sender |

	sender := thisContext sender.
	[ sender isNotNil and: [ sender method isWSEndpointExecutionMethod not ] ]
		whileTrue: [ sender := sender sender ].

	^ sender
]

{ #category : #initialization }
TWSEndpoint >> initializeOn: aClient [
	self initialize.
	wsClient := aClient
]

{ #category : #configuring }
TWSEndpoint >> prepareForExecutingOn: http [
	| effectivePath contextValues segments |

	effectivePath := self endpointPath.
	contextValues := thisContext wsEndpointValues.

	self executingContext
		ifNotNil: [ :context | 
			context wsEndpointPath ifNotNil: [ :val | effectivePath := val ].
			(context
				wsEndpointHttpMethodUsing: wsClient class supportedHttpMethods)
				ifNotNil: [ :val | http method: val asUppercase asSymbol ].
			context wsEndpointTemps
				ifNotEmpty: [ :val | contextValues addAll: val ] ].

	segments := effectivePath segments
		collect: [ :segment | segment format: contextValues ].
	http url: wsClient baseUrl / segments
]

{ #category : #accessing }
TWSEndpoint >> wsClient [
	^ wsClient
]
