## Startlight

Starlight is the navigation network built on the top of the Catalyst data points.

### CoreData, A10495s and Cliques

The data hierarchy of Catalyst goes as follows:

At the bottom we have files and folders, they are managed through a simple interface by **CoreData**, which is integrated in **A10495**s.

The A10495s represent pieces of data (six types at the time those lines are written). They represent where and how Pascal likes storing information (sometimes pointers to other data sources).

**Cliques** are collections of A10495s with some metadata.

### Navigation Network

The navigation network is a semantic network of timelines and the paths between them. Each timeline carries a collection of Cliques.

## Multiverse

```
Timeline {
    "catalystType"      : "catalyst-type:timeline"
    "creationTimestamp" : Float # Unixtime with decimals
    "uuid"              : String

    "name"              : String
} extends DataEntity

Stargate {
    "uuid"              : String
    "catalystType"      : "catalyst-type:starlight-path"
    "creationTimestamp" : Float # Unixtime with decimals

    "sourceuuid"        : String # uuid of a Timeline
    "targetuuid"        : String # uuid of a Timeline
}

TimelineOwnershipClaim {
    "uuid"              : String
    "catalystType"      : "catalyst-type:time-ownership-claim"
    "creationTimestamp" : Float # Unixtime with decimals

    "nodeuuid"          : String
    "targetuuid"        : String # Clique uuid or a A10495 uuid
}
```
