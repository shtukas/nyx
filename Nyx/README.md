# Nyx

## History

The original Nyx was a command line tool and web interface used by Pascal as a [Personal Information Management system](https://en.wikipedia.org/wiki/Personal_information_management). In **2015**, I wrote a [detailed entry](http://weblog.alseyn.net/index.php?uuid=40bd59d4-48de-454a-9a50-2c2a1c919e32) about what Nyx fundamentally is, and how it was built at the time.

## Permanodes


```
{
    "uuid"              : String
    "filename"          : String # Should be unique # Preferred L22
    "creationTimestamp" : Float
    "referenceDateTime" : DateTime Iso8601
    "description"       : String
    "targets"           : Array[PermanodeTarget]
    "taxonomy"          : Array[String]
}
```

- And example of `DateTime Iso8601` is `2018-12-06T23:23:48Z`. 

- `referenceDateTime` is usually fixed and used to give dating to the data referenced by the permanode.

- `PermanodeTarget` is a union of the following types

    ```
    {
        "uuid" : String
        "type" : "url-EFB8D55B"
        "url"  : <url>
    }
    {
        "uuid"       : String UUID
        "type"       : "file-3C93365A"
        "filename"   : String
    }
    {
        "uuid" : String
        "type" : "unique-name-C2BF46D6"
        "name" : String
    }
    {
        "uuid" : String
        "type" : "lstore-directory-mark-BEE670D0"
        "mark" : String # UUID
    }
    {
        "uuid"       : String UUID
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

## PermaDirs

**PermaDirs** are just directories, with fixed immutable foldernames. The uuid of the `perma-dir-11859659` object is the name of the corresponding directory. They are a more controlled version of general directories with marks (those that are targets of `lstore-directory-mark-BEE670D0` objects).

## Taxonomy

The overall organization of the Nyx system is that of nodes connected by a directed edges. The direction is meant to represent semantic flows in Pascal's mind. Permanodes belong to one or more nodes. 

For instance a picture of Justin Bieber represented by a permanode will belong to the node (Justin Bieber) and might also belong to the node (Paris) (if, say, the picture was taken in Paris). We will also specify the existence of the node (Canada) and a directed link from (Canada) to (Justin Bieber).

To specify the nodes that a permanode belongs to and the graph, we use the taxonomy key. Element of that array are string interpreted either as node names or directed liks between two nodes. 

Example: 

```
["Justin Bieber", "Paris", "Canada -> Justin Bieber"]
```

says that the permanode belongs to the two nodes "Justin Bieber" and "Paris" and that there is a directed link from "Canada" to "Justin Bieber". 

There is no need to "create" nodes, other than mentionning them in a taxonomy.

## Dependencies

Nyx has a dependency on `peco` [https://github.com/peco/peco](https://github.com/peco/peco), which is used as part of the command line user interface.


