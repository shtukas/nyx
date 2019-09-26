package catalyst.agents

import catalyst.model._

import scala.io.Source

object LucilleFile {
    val agentuid = "f7b21eb4-c249-4f0a-a1b0-d5d584c03316"

    def getLines(): Array[String] = {
        Source.fromFile("/Users/pascal/Desktop/Lucille18.txt" ,"UTF-8")
          .mkString
          .split("@marker-539d469a-8521-4460-9bc4-5fb65da3cd4b")
          .head
          .lines
          .toArray
          .filter(str => str.length > 0)
    }
    def printLines(): Unit = {
        getLines().foreach{line => println(line)}
    }
    def getObjects(): Array[CatalystObject] = {
        getLines().map{line => CatalystObject(
            "uuid-190373", // TODO
            agentuid,
            CatalystObjectContents(line),
            CatalystObjectScheduleTodoAndInformAgent(1),
            false)
        }
    }
}