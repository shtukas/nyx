# Todo

```
{
    "uuid"              : String
    "filename"          : String # Should be unique # Preferred L22
    "creationTimestamp" : Float
    "description"       : String
    "targets"           : Array[Target]
    "classification"    : Array[String]
}
```

- And example of `DateTime Iso8601` is `2018-12-06T23:23:48Z`. 

- `referenceDateTime` is usually fixed and used to give dating to the data referenced by the permanode.

- `Target` is a union of the following types

    ```
    {
        "uuid" : String
        "type" : "url-EFB8D55B"
        "url"  : <url>
    }
    {
        "uuid": String,
        "type": "line-2A35BA23",
        "line": String # Line
    }
    {
        "uuid"        : String,
        "type"        : "text-A9C3641C",
        "zetaKey"     : String
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
        "zetaKey"    : String # Contains the key where the Aion root hash is stored
    }
    ```

### Limitations

TNodes get their shapes from the general Nyx Permanodes, but we impose limitations on them

- Only one target
- Only one timelime


### Zeta Files

```
(todo zeta file)
    uuid              : String
    filename          : String # filename to the Zeta file
    creationTimestamp : Float
    description       : String
    targets           : JSON String
    classification    : JSON String
```

