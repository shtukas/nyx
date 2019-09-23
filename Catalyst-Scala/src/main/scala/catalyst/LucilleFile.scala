package catalyst

object LucilleFile {
    def getLines(): Array[String] = {
        Array(
            "Buy some bread"
        )
    }
    def printLines(): Unit = {
        getLines().foreach{line => println(line)}
    }
}