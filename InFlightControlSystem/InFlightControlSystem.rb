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
    "uuid"     : String,
    "lucilleLocationBasename" : String
    "position" : Float
}

Companion {
    "uuid"          : String
    "startunixtime" : Float
    "timePoints"    : Array[TimePoints]
}

TimePoint = {
    "unixtime" : Float
    "timespan" : Float
}

=end

# --------------------------------------------------------------------

# ---------------
# IO Items

def waveuuid()
    "f1e7bf19-ef85-4e93-a904-6287dbc8ad4e"
end

def waveItem()
    {
        "uuid" => waveuuid(),
        "lucilleLocationBasename" => nil,
        "position" => 0
    }
end

def itemsFolderpath()
    "/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/items"
end

def getItems()
    items = Dir.entries(itemsFolderpath())
        .select{|filename| filename[-5, 5] == ".json" }
        .map{|filename| JSON.parse(IO.read("#{itemsFolderpath()}/#{filename}")) }
    items + [ waveItem() ]
end

def getTopThreeItems()
    getItems()
        .sort{|i1, i2| i1["position"] <=> i2["position"] }
        .first(3)
end

def saveItem(item)
    return if item["uuid"] == waveuuid()
    uuid = item["uuid"]
    filepath = "#{itemsFolderpath()}/#{uuid}.json"
    File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
end

def getItemByUUIDOrNull(uuid)
    if uuid == waveuuid() then
        return waveItem()
    end
    filepath = "#{itemsFolderpath()}/#{uuid}.json"
    return nil if !File.exists?(filepath)
    JSON.parse(IO.read(filepath))
end

# ---------------
# IO Companions

def companionsKeyPrefix()
    getTopThreeItems()
        .map{|item| item["uuid"] }
        .sort
        .join("-")
end

def getItemCompanion(uuid)
    companion = KeyValueStore::getOrNull(nil, "#{companionsKeyPrefix()}:#{uuid}")
    if companion.nil? then
        companion = {
            "uuid"          => uuid,
            "startunixtime" => nil,
            "timePoints"    => []
        }
    else
        companion = JSON.parse(companion)
        if companion["timePoints"].nil? then
            companion["timePoints"] = companion["timesPoints"] # for the old ones
        end
    end
    companion
end

def saveItemCompanion(companion)
    KeyValueStore::set(nil, "#{companionsKeyPrefix()}:#{companion["uuid"]}", JSON.generate(companion))
end

# ---------------
# Run Management

def startItem(uuid)
    companion = getItemCompanion(uuid)
    return if companion["startunixtime"]
    companion["startunixtime"] = Time.new.to_i
    saveItemCompanion(companion)
    return if uuid == waveuuid()

    # When we start a ifcs item we also want to start the corresponding lucille item
    item = getItemByUUIDOrNull(uuid)
    return if item.nil?
    system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Lucille/lucille-open-and-start-location-basename '#{item["lucilleLocationBasename"]}'")
end

def stopItem(uuid)
    companion = getItemCompanion(uuid)
    return if companion["startunixtime"].nil?
    unixtime = companion["startunixtime"]
    timespan = [Time.new.to_i - unixtime, 3600*2].min
        # We prevent time spans greater than 2 hours,
        # to void what happened when I left Wave running an entire night.
    companion["startunixtime"] = nil
    companion["timePoints"] << {
        "unixtime" => Time.new.to_i,
        "timespan" => timespan
    } 
    saveItemCompanion(companion)

    # When we stop a ifcs item we also want to stop the corresponding lucille item
    item = getItemByUUIDOrNull(uuid)
    return if item.nil?
    system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Lucille/lucille-stop-location-basename '#{item["lucilleLocationBasename"]}'")
end

# ---------------
# Operations

def flightControlIsActive()
    b1 = ( Time.new.hour >= 9 and Time.new.hour < 21 )
    b2 = getTopThreeItems().any?{|item| getItemCompanion(item["uuid"])["startunixtime"] }
    b1 or b2
end

def itemIsTopItem(uuid)
    getTopThreeItems().any?{|i| i["uuid"] == uuid }
end

def getItemLiveTimespan(uuid)
    companion = getItemCompanion(uuid)
    x1 = 0
    if companion["startunixtime"] then
        x1 = Time.new.to_i - companion["startunixtime"]
    end
    x1 + companion["timePoints"].map{|point| point["timespan"] }.inject(0, :+)
end

def getItemLiveTimespanTopItemsDifferentialInHoursOrNull(uuid)
    timespan = getItemLiveTimespan(uuid)
    differentTimespans = getTopThreeItems()
                            .select{|item| item["uuid"] != uuid }
                            .map {|item| getItemLiveTimespan(item["uuid"]) }
    return nil if differentTimespans.empty?
    (timespan - differentTimespans.min).to_f/3600
end

def topItemsOrderedByTimespan()
    getTopThreeItems().sort{|i1, i2| getItemLiveTimespan(i1["uuid"]) <=> getItemLiveTimespan(i2["uuid"]) }
end

def itemsOrderedByPosition()
    getItems().sort{|i1, i2| i1["position"] <=> i2["position"] }
end

def getNextAction() # [ nil | String, lambda ]
    itemToDescription = lambda {|item|
        item["lucilleLocationBasename"] || "Wave"
    }
    runningitems = topItemsOrderedByTimespan()
        .select{|item| getItemCompanion(item["uuid"])["startunixtime"] }
    lowestitem = topItemsOrderedByTimespan()[0]
    if runningitems.size == 0 then
        return [ "start: #{itemToDescription.call(lowestitem)}".red , lambda { startItem(lowestitem["uuid"]) } ]
    end
    firstrunningitem = runningitems[0]
    if firstrunningitem["uuid"] == lowestitem["uuid"] then
        return [ nil , lambda { stopItem(firstrunningitem["uuid"]) } ]
    else
        return [ "stop: #{itemToDescription.call(firstrunningitem)}".red , lambda { stopItem(firstrunningitem["uuid"]) } ]
    end
end

def getReportText()
    itemToDescription = lambda {|item|
        item["lucilleLocationBasename"] || "Wave"
    }
    nsize = getItems()
        .select{|item| item["lucilleLocationBasename"] } # This is to avoid the Wave item
        .map{|item| item["lucilleLocationBasename"].size }
        .max
    itemsOrderedByPosition()
        .map{|item| 
            if itemIsTopItem(item["uuid"]) then
                companion = getItemCompanion(item["uuid"])
                "(#{"%5.3f" % item["position"]}) #{itemToDescription.call(item).ljust(nsize)} (#{"%6.2f" % (getItemLiveTimespan(item["uuid"]).to_f/3600)} hours)"
            else
                "(#{"%5.3f" % item["position"]}) #{item["lucilleLocationBasename"].ljust(nsize)}"
            end
        }
        .join("\n")
end

def getReportLine() 
    itemToDescription = lambda {|item|
        item["lucilleLocationBasename"] || "Wave"
    }
    report = [ "In Flight Control System 🛰️ " ]
    topItemsOrderedByTimespan()
        .select{|item| getItemCompanion(item["uuid"])["startunixtime"] }
        .each{|item| 
            d1 = getItemLiveTimespanTopItemsDifferentialInHoursOrNull(item["uuid"])
            d2 = d1 ? " (#{d1.round(2)} hours)" : ""
            report << "running: #{itemToDescription.call(item)}#{d2}".green 
        }
    nextaction = getNextAction()
    if nextaction then
        report << nextaction[0] # can be null
    end
    report.compact.join(" >> ")
end

def selectItemOrNull()
    LucilleCore::selectEntityFromListOfEntitiesOrNull("item", itemsOrderedByPosition(), lambda{|item| item["lucilleLocationBasename"] })
end

def onScreenNotification(title, message)
    title = title.gsub("'","")
    message = message.gsub("'","")
    message = message.gsub("[","|")
    message = message.gsub("]","|")
    command = "terminal-notifier -title '#{title}' -message '#{message}'"
    system(command)
end
