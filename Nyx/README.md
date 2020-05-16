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
    taxonomy         : String JSON Array[String]
}
```


`NyxTarget` is a union of the following types

    ```
    {
        "type" : "url"
        "url"  : <url>
    }
    {
        "uuid"     : String UUID
        "type"     : "file"
        "filename" : String
    }
    {
        "type" : "unique-name"
        "name" : String
    }
    {
        "uuid" : String
        "type" : "directory-mark"
        "mark" : String # UUID
    }
    {
        "uuid"       : String UUID
        "type"       : "folder"
        "foldername" : String # Should be unique # Preferred L22
    }
    ```

## Tags

The overall organization of the Nyx system is that of taxonomy.



