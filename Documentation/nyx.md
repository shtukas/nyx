Part 1: 

I designed and using a system like this. The basic ideas are those of nodes and edges. Nodes have several types, each type corresponds to the type of data it holds. The simplest ones are text and single files (often pictures, .pdf files etc), up to entire file hierarchies (files and folders and subfolders etc).

The interface to the graph is a console application (I never put some efforts into giving it a graphical user interface). I can search for contents and it returns the list of nodes that corresponds to the search. Then, if I select a node I can have basic information about it, including the nodes it is connected to, and then I can chose to either follow an edge and land on another node, or expose the content of that node. The most interesting case here is exposing file hierarchies; in that case the entire hierarchy is rebuilt and written somewhere (think of it as mounting a virtual drive).

Part 2: 

So... it just occurred to me that you need to know about [https://perkeep.org](https://perkeep.org) , I have been following it since the beginning when it was called Camlistore, and notably this talk [https://www.youtube.com/watch?v=yxSzQIwXM1k](https://www.youtube.com/watch?v=yxSzQIwXM1k) ( from this page: https://perkeep.org/doc/ ).

The reason why I mention this is because it is where I got the idea of encoding a file hierarchy in a key value store.  

So here is how it works: The nodes are json objects in my case, something simple like   

```
{
   "uuid"     : string
   "unixtime" : integer
   "title"    : string
   "payload"  : Payload
}
```

The payload, (let me just give you two) 

```
{
    "type" : "text"
    "hash" : some hash 
}
```

The hash is the hash of that piece of text once you send it to the content addressed store (but the fact that it's content addressed is not necessary, you could just have a randomly generated key corresponding to the text as a value in a key value store) ( btw: https://en.wikipedia.org/wiki/Content-addressable_storage )

So that was the easy case. The more interesting case is

```
{
    "type" : "aion-point"
    "hash" : some hash 
}
```

So Aion is something I invented (inspired by Camlistore), a way to send an entire file hierarchy to a content addressed store (or just a regular key value store), and I need to mention here that the nodes go to a SQLite database, but I use my regular file system for the blobs of the store. If I have a binary blob and its SHA256 is 12345678, I store it as [root of the store]/12/SHA256-12345678

The hash in this case is computed recursively, it's actually a Merkle root ( https://en.wikipedia.org/wiki/Merkle_tree )

So if I have say a folder called "Pictures" with three files in it, "picture1.jpg", "picture2.jpg" and an empty folder called "extra"

picture1.jpg's data will be sent to the store, and the return value is a hash. I then build this

```
{
    "type"     : "file"
    "filename" : "picture1.jpg"
    "hash"     : <hash of the picture>
}
```

And then that json object, I serialise it and send it to the store, to get hash1. I do the same with picture2.jpg, and get hash2. The empty folder, I just build the object 

```
{
    "type"     : "directory"
    "name"     : "extra"
    "contents" : []
}
```

and commit that to the store to get hash3.

It's now time to build an object for the "Pictures" directory

```
{
    "type"     : "directory"
    "name"     : "Pictures"
    "contents" : [hash1, hash2, hash3]
}
```

And then I commit that to the store to get hash4, hash4 is then the hash I put in the aion-point object.

So your graph could have two nodes 

```
{
   "uuid"     : 
   "unixtime" : 
   "title"    : "Recipe of bread"
   "payload"  : {
       "type" : "text"
       "hash" : some hash 
   }
}

{
   "uuid"     : 
   "unixtime" : 
   "title"    : "my holiday pictures"
   "payload"  : {
       "type" : "aion-point"
       "hash" : some hash 
   }
}
```

In the former case, the hash is the hash of a piece of text and in the second case, it could be the top hash of file hierarchy containing million of files (but manipulated as one tiny object: the merkle root)

Given a file hierarchy, you can build the aion point, recursively from the leaves, and given a aion-point and assuming you have the data blobs, you can rebuild the entire file hierarchy.

Then you can have another table in your database to record the fact that two nodes are connected. (You could also let the nodes carry that information, but you need to update two nodes when a link is made or destroyed).

The entire system is: your SQLite file (json nodes and edges) and a possibly big (but contained) store where the binary blobs are stored. (Using a content addressed store instead of a kv store ensure automatic deduplication, and lots of other goodies).

Last but not least, at some point I had half a terabytes of data in that system :) That in itself doesn't tell you how big is the graph, just how big the store is (the graph, for argument's sake, could be a single node that points to a file hierarchy that big.)
