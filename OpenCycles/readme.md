We are now using Aether files to store Open Cycles data.

The file names carry are l22 strings which also are the UUIDs of the items. Example

```
20200416-110732-623024.data
```

The expected kv entries are

- uuid
- description

And then a single aionreference hardcoded to "1815ea639314" pointing at a file or a folder.

### Mercury Channels

Text to become Open Cycles item payload `text`

- channel: b4efb93f-488d-4984-96bd-d4e453ebb00e
- payload: String