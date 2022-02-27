
### Librarian Objects

To be acceptable, an object must have at least two keys: "uuid" and "mikuType". We can retrieve objects individually by "uuid" or collectively by MikuTypes.

### Librarian Notes

...

### Abstracting Atom away from the Library

There is a way to abstract CoreData, away from the library

1. Introduce an Atom config object

```
{
    "managedFolderRepositoryPath" : String
    "aionPointsElizabethFactory"  : Lambda: Input -> Elizabeth Instance
}
```

2. Modify the signature of some of the public functions