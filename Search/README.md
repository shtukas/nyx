Each subsystem implements its own searching capabilities, Search is the aggregator.

"Implementing the search interface" means that each subystem is able to return an array of `SearchResult`s when given a pattern.

```
SearchResult {
	"subsystem"   : String
	"description" : String
	"uniqueId"    : String
}
```

- subsystem: name of the subsystem
- description: Description of the entity matched
- uniqueId: Unique identifier of the entity matched (semantically valid inside the corresponding subsystem)

Each subsystem should also provide a way to access to the element referred to by a given uniqueId.

