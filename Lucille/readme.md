Special timelines are "[Inbox]", and "[Infinity]". 

[Inbox] is not actually declared by, say Vienna or Lucille-Inbox processing, but is the default timeline for any Lucille item without one. An item on that timeline is meant to either be immediately consumed (eg: online comics), or recast to the appropriate timeline.

[Infinity] contains the streams of entertainement consumables.

### Aether

We are now using Aether files to store Lucille data.

The file names carry are l22 strings which also are the UUIDs of the items. Example

```
20200416-110732-623024.data
```

The expected kv entries are

```
- uuid
- description
- payloadType
- timeline

```

The possible values for payloadType are

- aionpoint
- text
- url

When "aionpoint" a single aion reference hardcoded to "1815ea639314" pointing at a file or a folder.

When "text", the content is held in the kv store at key "472ec67c0dd6"

When "url", the url is held in the kv store at key "67c2db721728"

### Mercury Channels

Text to become Lucille item payload `text`

- channel: AF39EC62-4779-4C00-85D9-D2F19BD2D71E
- payload: {
    "text"
    "timeline"
}

URL to become Lucille item payload `url`

- channel: F771D7FE-1802-409D-B009-5EB95BA89D86
- payload: String