# Nyx

## History

The original Nyx was a command line tool and web interface used by Pascal as a [Personal Information Management system](https://en.wikipedia.org/wiki/Personal_information_management). In **2015**, I wrote a [detailed entry](http://weblog.alseyn.net/index.php?uuid=40bd59d4-48de-454a-9a50-2c2a1c919e32) about what Nyx fundamentally is, and how it was built at the time.

### Nyx points

Nyx Points are objects of the form

```
{
    uuid
    creationTimestamp: Float
    referenceDateTime: DateTime Iso8601
    description
    targets          : String JSON Array[NyxTarget]
    tags             : String JSON Array[String]
}
```


`NyxTarget` is a union of the following types

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

## PermaDirs

**PermaDirs** are just directories, with fixed immutable foldernames. The uuid of the `perma-dir-11859659` object is the name of the corresponding directory. They are a more controlled version of general directories with marks (those that are targets of `lstore-directory-mark-BEE670D0` objects).

## Tags

The overall organization of the Nyx system is that of tags.



