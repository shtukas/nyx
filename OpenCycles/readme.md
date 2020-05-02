We are now using Aether files to store Open Cycles data.

The file names carry are l22 strings which also are the UUIDs of the items. Example

```
20200416-110732-623024.data
```

The expected kv entries are

- uuid
- description

And then a single aionreference hardcoded to "1815ea639314" pointing at a file or a folder.


