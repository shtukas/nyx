# encoding: UTF-8

=begin
{
    "type"  : "item"
    "item"  : item
}
{
    "type"  : "delete"
    "uuid"  : string
}
=end

class Broadcasts

    # Broadcasts::otherInstanceId()
    def self.otherInstanceId()
        map = {
            "Lucille26-pascal-honore" => "Lucille24-pascal",
            "Lucille24-pascal" => "Lucille26-pascal-honore",
        }
        map[Config::instanceId()]
    end

    # Broadcasts::send(message)
    def self.send(message)
        targetDirectory = "#{Config::pathToNyxData()}/broadcasts/#{Broadcasts::otherInstanceId()}"
        filepath = "#{targetDirectory}/#{CommonUtils::timeStringL22()}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(message)) }
    end

    # Broadcasts::processIncoming()
    def self.processIncoming()
        targetDirectory = "#{Config::pathToNyxData()}/broadcasts/#{Config::instanceId()}"
        LucilleCore::locationsAtFolder(targetDirectory)
        .select{|filepath| filepath[-5, 5] == ".json" }
        .sort
        .each{|filepath|
            message = JSON.parse(IO.read(filepath))
            puts "#{message}".yellow
            if message["type"] == "item" then
                Items::commitItemNoBroadcast(message["item"])
            end
            if message["type"] == "delete" then
                Items::deleteItemNoBroadcast(message["uuid"])
            end
            FileUtils.rm(filepath)
        }
    end
end
