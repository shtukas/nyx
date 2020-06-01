## Startlight

Starlight is the nickname of Catalyst's global navigation network.

### CoreData, DataPoints and Cliques

The data hierarchy of Catalyst goes as follows:

At the bottom we have files and folders, they are managed through a simple interface by **CoreData**, which is integrated in **DataPoint**s.

The DataPoints represent pieces of data (six types at the time those lines are written). They represent where and how Pascal likes storing information (sometimes pointers to other data sources).

**Cliques** are collections of DataPoints with some metadata.

### Navigation Network

The navigation network is a semantic network of nodes and the paths between them. Each node carries a collection of Cliques.
