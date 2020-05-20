## Startlight

Starlight is the navigation network built on the top of the Catalyst data points.

### CoreData, Catalyst Standard Targets and Data Points

The data hierarchy of Catalyst goes as follows:

At the bottom we have files and folders, they are managed through a simple interface by **CoreData**, which is integrated in **Catalyst Standard Targets**.

The Standard Targets represent pieces of data (six types at the time those lines are written). They represent where and how Pascal likes storing information (sometimes pointers to other data sources).

**Data Points** are collections of standard targets with some metadata.

In practice both standard targets and data points are mentally thought of atomic information.

### Navigation Network

The navigation network is a semantic network of nodes and the paths between them. Each node is a portal to a collection of Data Points.

## Startlight

```
StartlightNode {
    "uuid"              : String
    "catalystType"      : "catalyst-type:starlight-node"
    "creationTimestamp" : Float # Unixtime with decimals
    "name"              : String
}

StarlightPath {
    "uuid"        : String
    "catalystType"      : "catalyst-type:starlight-path"
    "creationTimestamp" : Float # Unixtime with decimals
    "sourceuuid"  : String # uuid of a StartlightNode
    "targetuuid"  : String # uuid of a StartlightNode
}

StarlightDataClaim {
    "uuid"      : String
    "creationTimestamp" : Float # Unixtime with decimals
    "nodeuuid"  : String
    "pointuuid" : String
}
```
