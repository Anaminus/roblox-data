# JSON Format

Notes about this doc:

- `bool`, `int`, `string`, `null` indicate that a value is of the given type.
- `...` indicates that an array may contain more of the previous values.
- `|` indicates one value or the other is possible.

## Header

	{
		"Schema" : 1,
		"Domain" : string,
		"List"   : [
			{
				"Date"          : int,
				"PlayerHash"    : string,
				"PlayerVersion" : string,
				"StudioVersion" : [ int, int, int, int ]
			},
			...
		]
	}

## API Dumps

	[
		{
			"type"       : "Class",
			"tags"       : [ string, ... ],
			"Name"       : string,
			"Superclass" : string | null
		},
		{
			"type"      : "Property",
			"tags"      : [ string, ... ],
			"Name"      : string,
			"Class"     : string,
			"ValueType" : string
		},
		{
			"type"       : "Function",
			"tags"       : [ string, ... ],
			"Name"       : string,
			"Class"      : string,
			"ReturnType" : string,
			"Arguments"  : [
				{
					"Name"    : string,
					"Type"    : string,
					"Default" : string | null
				},
				...
			]
		},
		{
			"type"       : "YieldFunction",
			"tags"       : [ string, ... ],
			"Name"       : string,
			"Class"      : string,
			"ReturnType" : string,
			"Arguments"  : [
				{
					"Name"    : string,
					"Type"    : string,
					"Default" : string | null
				},
				...
			]
		},
		{
			"type"      : "Event",
			"tags"      : [ string, ... ],
			"Name"      : string,
			"Class"     : string,
			"Arguments" : [
				{
					"Name" : string,
					"Type" : string
				},
				...
			]
		},
		{
			"type"       : "Callback",
			"tags"       : [ string, ... ],
			"Name"       : string,
			"Class"      : string,
			"ReturnType" : string,
			"Arguments"  : [
				{
					"Name" : string,
					"Type" : string
				},
				...
			]
		},
		{
			"type" : "Enum",
			"tags" : [ string, ... ],
			"Name" : string,
		},
		{
			"type"  : "EnumItem",
			"tags"  : [ string, ... ],
			"Name"  : string,
			"Value" : int
		},
		...
	]

## ReflectionMetadata

	[
		{
			"Name"               : string,
			"Summary"            : string,
			"Browsable"          : bool,
			"Deprecated"         : bool,
			"Preliminary"        : bool,
			"IsBackend"          : bool,
			"ExplorerOrder"      : int,
			"ExplorerImageIndex" : int,
			"PreferredParent"    : string,
			"Members": [
				{
					"Name"        : string,
					"Summary"     : string,
					"Browsable"   : bool,
					"Deprecated"  : bool,
					"Preliminary" : bool,
					"IsBackend"   : bool
				},
				...
			]
		},
		...
	]
