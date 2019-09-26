package catalyst

import catalyst.libs.DisplayUtils

object Hello extends App {
  agents.LucilleFile
    .getObjects()
    .foreach{o => println(DisplayUtils.catalystObjectToString(o))
  }
}

