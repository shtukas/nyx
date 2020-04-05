# Nyx

## History

The original Nyx was a command line tool and web interface used by Pascal as a [Personal Information Management system](w). In **2015**, I wrote a [detailed entry](http://weblog.alseyn.net/index.php?uuid=40bd59d4-48de-454a-9a50-2c2a1c919e32) about what Nyx fundamentally is, and how it was built at the time.

## Permanodes


```
{
    "uuid"              : String
    "filename"          : String # Should be unique # Preferred L22
    "creationTimestamp" : Float
    "referenceDateTime" : DateTime Iso8601
    "description"       : String
    "targets"           : Array[PermanodeTarget]
    "classification"    : Array[ClassificationItem]
}
```

- And example of `DateTime Iso8601` is `2018-12-06T23:23:48Z`. 

- `referenceDateTime` is usually fixed and used to give dating to the data referenced by the permanode.

- `PermanodeTarget` is a union of the following types

    ```
    {
        "uuid" : String
        "type" : "lstore-directory-mark-BEE670D0"
        "mark" : String # UUID
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

nb: The definition of PermaDirs specify that the uuid is a UUID. We shall respect that, but in any case it is important that the first 4 characters of the uuid be random hexadecimal characters.

Note 27th Feb: The intent, for the moment, is to migrate data to PermaDirs without worrying about redundancy or size. Once the migration is done I will maybe make a mirror file file system and perform better data management.

## Dependencies

Nyx has a dependency on `peco` [https://github.com/peco/peco](https://github.com/peco/peco), which is used as part of the command line user interface.

## Night 

Night is the graphical user interface, written in [Elm](https://elm-lang.org).
