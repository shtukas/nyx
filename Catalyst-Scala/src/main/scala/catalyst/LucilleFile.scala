package catalyst

import scala.io.Source

object LucilleFile {
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
}