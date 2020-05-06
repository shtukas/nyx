
### Lucille Next Gen

An Lucille's claim is an object

```
{
    "uuid"         : String
    "creationtime" : unixtime with decimals
    "description"  : String
    "target"       : null | CatalystStandardTarget
    "timeline"     : String
}
```

Special timelines are "Inbox", and "Infinity". 

Inbox is not actually declared by, say Vienna or Lucille-Inbox processing, but is the default timeline for any Lucille item without one. An item on that timeline is meant to either be immediately consumed (eg: online comics), or recast to the appropriate timeline.

Infinity contains the streams of entertainement consumables.

### Mercury Channels

URL to become Lucille item payload `url`

- channel: F771D7FE-1802-409D-B009-5EB95BA89D86
- payload: String