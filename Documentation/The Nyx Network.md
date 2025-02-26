###

Nyx is a network of nodes. Nodes are abstract datatypes that need to have the equivalent of

- a description
- a datetime (often the creation datetime, but it's mostly the "relavant" datatime, notably for items that are to be considered on a timeline)
- the list of node uuids that this node is linked to (this defines bidirectional edges between nodes of the graph)
- a list of notes, pieces of text, attached to the node (this allows for notes to be added to nodes whose main payload is not text)
- a list of tags, used for search (in addition of the description)

- Each node also has a payload of zero or more pieces of data.

###

On disk, each node is declared by a text file. All such files are in ~/Galaxy/DataHub/Nyx/data/nodes

filename: [anything].nyxnode-4be8.txt

Example:

```
uuid: f32643f9-72b0-46e0-9b54-41554b53a9f7
description: This is a description
datetime: 2025-02-26T14:29:32Z
linkeduuid: da0c2a46-834f-4289-be60-675a8d1508a9
linkeduuid: e5cca6c6-ec91-4b78-8234-c93943dba945
tag: mercury
tag: venus
tag: earth
note: {"uuid": "6e163b59-8f2c-4a79-8f3c-434840968c5c", "datetime": "2025-02-26T14:31:43Z", "note": "This is a note"}
note: {"uuid": "4b63b290-3c1f-40ee-b87a-798342505a68", "datetime": "2025-02-26T14:33:09Z", "note": "This is another note"}
payload: {"uuid": "4b63b290-3c1f-40ee-b87a-798342505a68", "datetime": "2025-02-26T14:33:09Z", "type": "url", "url": "http://example.com"}
```

The notes are json encoded objects of the form:
```
{
    "uuid": string,
    "datetime": datetime,
    "note": string
}
```

The payloads are json encoded objects of the form:
```
{
    "uuid": "4b63b290-3c1f-40ee-b87a-798342505a68",
    "datetime": "2025-02-26T14:33:09Z",
    "type": "url",
    "url": "http://example.com"
}
```

The list of types is clarified below

###

Some nodes are self contained, and the entire node is contained in the nyxnode-4be8.txt file, but often the payload cannot be encoded in the text file. Sometimes because it's binary data, or because the payload is more complex, for instance a Nx01 reference on disk, contained in a directory. In those cases, each payload type is using it's own techniques and conventions to manage the payload.
