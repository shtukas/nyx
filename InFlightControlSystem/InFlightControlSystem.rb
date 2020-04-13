#!/Users/pascal/.rvm/rubies/ruby-2.5.1/bin/ruby

# encoding: UTF-8

require 'colorize'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

# --------------------------------------------------------------------

=begin

Item {
    "uuid"        : String,
    "description" : String
}

Companion {
    "uuid"         : String
    "runningState" : Float
    "timesPoints"  : Array[TimePoints]
}

TimePoint = {
    "unixtime" : Float
    "timespan" : Float
}

=end

# --------------------------------------------------------------------

def getItems()
    BTreeSets::values(nil, "867c6e0d-5c02-4488-b829-8563c140e177")
end

def saveItem(item)
    BTreeSets::set(nil, "867c6e0d-5c02-4488-b829-8563c140e177", item["uuid"], item)
end

def collectionCompanionKeyPrefix()
    getItems()
        .map{|item| item["uuid"] }
        .sort
        .join("-")
end

def getCompanion(uuid) # unixtime or null
    status = KeyValueStore::getOrNull(nil, "#{collectionCompanionKeyPrefix()}:#{uuid}")
    if status.nil? then
        status = {
            "uuid"         => uuid,
            "runningState" => nil,
            "timesPoints"  => []
        }
    else
        status = JSON.parse(status)
    end
    status
end

def saveCompanion(status)
    KeyValueStore::set(nil, "#{collectionCompanionKeyPrefix()}:#{status["uuid"]}", JSON.generate(status))
end

def getItemTimestamp(uuid)
    status = getCompanion(uuid)
    status["timesPoints"].map{|point| point["timespan"] }.inject(0, :+)
end

def itemsOrderedByTimespan()
    getItems().sort{|i1, i2| getItemTimestamp(i1["uuid"]) <=> getItemTimestamp(i2["uuid"]) }
end

def startItem(uuid)
    status = getCompanion(uuid)
    return if status["runningState"]
    status["runningState"] = Time.new.to_i
    saveCompanion(status)
end

def stopItem(uuid)
    status = getCompanion(uuid)
    return if status["runningState"].nil?
    unixtime = status["runningState"]
    timespan = Time.new.to_i - unixtime
    status["runningState"] = nil
    status["timesPoints"] << {
        "unixtime" => Time.new.to_i,
        "timespan" => timespan
    } 
    saveCompanion(status)
end

def determineRecommendedNextAction() # [ String, lambda ]
    items = itemsOrderedByTimespan()
                .select{|item| getCompanion(item["uuid"])["runningState"] }
                .select{|item| 
                    companion = getCompanion(item["uuid"])
                    timepercentage = 100*(Time.new.to_i - companion["runningState"]).to_f/3600
                    timepercentage > 100
                }
    if !items.empty? then
        return [ "shutdown: #{items[0]["description"]}" , lambda { stopItem(items[0]["uuid"]) } ]
    end

    items = itemsOrderedByTimespan()
                .select{|item| getCompanion(item["uuid"])["runningState"] }
    item = itemsOrderedByTimespan()[0]
    if !items.empty? and items.none?{|i| i["uuid"]==item["uuid"] } then
        return [ "shutdown: #{items[0]["description"]}" , lambda { stopItem(items[0]["uuid"]) } ]
    end

    items = itemsOrderedByTimespan()
                .select{|item| getCompanion(item["uuid"])["runningState"] }
    item = itemsOrderedByTimespan()[0]
    if items.any?{|i| i["uuid"]==item["uuid"] } then
        return nil
    end

    [ "start: #{item["description"]}".red , lambda { startItem(item["uuid"]) } ]
end

def getReportLine() 
    report = [ "In Flight Control System 🛰️ " ]
    itemsOrderedByTimespan()
        .select{|item| getCompanion(item["uuid"])["runningState"] }
        .each{|item| report << "running: #{item["description"]}".green }
    nextaction = determineRecommendedNextAction()
    if nextaction then
        report << nextaction[0]
    end
    report.join(" ; ")
end

def getReportText()
    nsize = getItems().map{|item| item["description"].size }.max
    report = itemsOrderedByTimespan()
                .map{|item| 
                    companion = getCompanion(item["uuid"])
                    "#{item["description"].ljust(nsize)} (#{"%6.2f" % (getItemTimestamp(item["uuid"]).to_f/3600)} hours)"
                }
    report.join("\n")
end

def selectItemOrNull()
    LucilleCore::selectEntityFromListOfEntitiesOrNull("item", getItems(), lambda{|item| item["description"] })
end


def onScreenNotification(title, message)
    title = title.gsub("'","")
    message = message.gsub("'","")
    message = message.gsub("[","|")
    message = message.gsub("]","|")
    command = "terminal-notifier -title '#{title}' -message '#{message}'"
    system(command)
end
