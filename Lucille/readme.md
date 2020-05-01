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

- uuid
- description
- timeline

And then a single aion reference hardcoded to "1815ea639314" pointing at a file or a folder.