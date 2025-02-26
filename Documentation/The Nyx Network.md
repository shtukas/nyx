Nyx is a network of nodes. Nodes are abstract datatypes that need to have the equivalent of

- a description
- a datetime (often the creation datetime, but it's mostly the "relavant" datatime, notably for items that are to be considered on a timeline)
- the list of node uuids that this node is connected to (this defines bidirectional edges between nodes of the graph)
- a list of notes, pieces of text, attached to the node (this allows for notes to be added to nodes whose main payload is not text)
- a list of tags, used for search (in addition of the description)

- Each node also have a payload, which is the main contents of the node.