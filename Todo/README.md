# Todo

## TNodes

TNodes are JSON objects of the form

```
{
    "uuid"              : String # L22 # primary part of the filename
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
	    "filename" : String # L22.txt
	}
	{
	    "uuid" : String
	    "type" : "url-01EFB604"
	    "url"  : <url>
	}
	{
	    "uuid" : String
	    "type" : "unique-name-11C4192E"
	    "name" : String
	}
	{
	    "uuid"       : String
	    "type"       : "perma-dir-AAD08D8B"
	    "foldername" : String # L22
	}
	```

- `ClassificationItem` is a union of the following types

	```
	{
	    "uuid"     : String
	    "type"     : "tag-8ACC01B9"
	    "tag"      : String
	}
	{
	    "uuid"     : String
	    "type"     : "timeline-49D07018"
	    "timeline" : String
	}
	```

