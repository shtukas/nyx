# Todo

## TNodes

TNodes are JSON objects of the form

```
{
    "uuid"              : String
    "filename"          : String # Should be unique # Preferred L22
    "creationTimestamp" : Unixtime, with decimals
    "description"       : String
    "targets"           : Array[TNodeTarget]
    "classification"    : Array[ClassificationItem]
}
```

- `TNodeTarget` is a union of the following types

	```
	{
	    "uuid" : String
	    "type" : "line-2A35BA23"
	    "line" : String # Line
	}
	{
	    "uuid"     : String
	    "type"     : "text-A9C3641C"
	    "filename" : String # Should be unique # Preferred L22
	}
	{
	    "uuid" : String
	    "type" : "url-EFB8D55B"
	    "url"  : <url>
	}
	{
	    "uuid" : String
	    "type" : "unique-name-C2BF46D6"
	    "name" : String
	}
	{
	    "uuid"       : String
	    "type"       : "perma-dir-11859659"
	    "foldername" : String # Should be unique # Preferred L22
	}
	```

- `ClassificationItem` is a union of the following types

	```
	{
	    "uuid"     : String
	    "type"     : "tag-18303A17"
	    "tag"      : String
	}
	{
	    "uuid"     : String
	    "type"     : "timeline-329D3ABD"
	    "timeline" : String
	}
	```

