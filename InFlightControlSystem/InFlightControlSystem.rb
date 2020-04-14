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

def itemsFolderpath()
    "/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/items"
end

def getItems2()
    Dir.entries(itemsFolderpath())
        .select{|filename| filename[-5, 5] == ".json" }
        .map{|filename| JSON.parse(IO.read("#{itemsFolderpath()}/#{filename}")) }
end

def saveItem2(item)
    uuid = item["uuid"]
    filepath = "#{itemsFolderpath()}/#{uuid}.json"
    File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
end

def companionsKeyPrefix()
    getItems2()
        .map{|item| item["uuid"] }
        .sort
        .join("-")
end

def getCompanion(uuid)
    companion = KeyValueStore::getOrNull(nil, "#{companionsKeyPrefix()}:#{uuid}")
    if companion.nil? then
        companion = {
            "uuid"         => uuid,
            "runningState" => nil,
            "timesPoints"  => []
        }
    else
        companion = JSON.parse(companion)
    end
    companion
end

def saveCompanion(companion)
    KeyValueStore::set(nil, "#{companionsKeyPrefix()}:#{companion["uuid"]}", JSON.generate(companion))
end

def getItemTimespan(uuid)
    companion = getCompanion(uuid)
    x1 = 0
    if companion["runningState"] then
        x1 = Time.new.to_i - companion["runningState"]
    end
    x1 + companion["timesPoints"].map{|point| point["timespan"] }.inject(0, :+)
end

def getItemTimespanDifferentialInHoursOrNull(uuid)
    timespan = getItemTimespan(uuid)
    differentTimespans = getItems2()
                            .select{|item| item["uuid"] != uuid }
                            .map {|item| getItemTimespan(item["uuid"]) }
    return nil if differentTimespans.nil?
    (timespan - differentTimespans.min).to_f/3600
end

def itemsOrderedByTimespan()
    getItems2().sort{|i1, i2| getItemTimespan(i1["uuid"]) <=> getItemTimespan(i2["uuid"]) }
end

def startItem(uuid)
    companion = getCompanion(uuid)
    return if companion["runningState"]
    companion["runningState"] = Time.new.to_i
    saveCompanion(companion)
end

def stopItem(uuid)
    companion = getCompanion(uuid)
    return if companion["runningState"].nil?
    unixtime = companion["runningState"]
    timespan = Time.new.to_i - unixtime
    companion["runningState"] = nil
    companion["timesPoints"] << {
        "unixtime" => Time.new.to_i,
        "timespan" => timespan
    } 
    saveCompanion(companion)
end

def getNextAction() # [ nil | String, lambda ]

    runningitems = itemsOrderedByTimespan()
                .select{|item| getCompanion(item["uuid"])["runningState"] }
    lowestitem = itemsOrderedByTimespan()[0]

    if runningitems.size == 0 then
        return [ "start: #{lowestitem["description"]}".red , lambda { startItem(lowestitem["uuid"]) } ]
    end

    firstrunningitem = runningitems[0]

    if firstrunningitem["uuid"] == lowestitem["uuid"] then
        return [ nil , lambda { stopItem(firstrunningitem["uuid"]) } ]
    else
        return [ "stop: #{firstrunningitem["description"]}".red , lambda { stopItem(firstrunningitem["uuid"]) } ]
    end
end

def getReportLine() 
    report = [ "In Flight Control System 🛰️ " ]
    itemsOrderedByTimespan()
        .select{|item| getCompanion(item["uuid"])["runningState"] }
        .each{|item| 
            d1 = getItemTimespanDifferentialInHoursOrNull(item["uuid"])
            d2 = d1 ? " (#{d1.round(2)} hours)" : ""
            report << "running: #{item["description"]}#{d2}".green 
        }
    nextaction = getNextAction()
    if nextaction then
        report << nextaction[0] # can be null
    end
    report.compact.join(" ; ")
end

def getReportText()
    nsize = getItems2().map{|item| item["description"].size }.max
    report = itemsOrderedByTimespan()
                .map{|item| 
                    companion = getCompanion(item["uuid"])
                    "#{item["description"].ljust(nsize)} (#{"%6.2f" % (getItemTimespan(item["uuid"]).to_f/3600)} hours)"
                }
    report.join("\n")
end

def selectItemOrNull()
    LucilleCore::selectEntityFromListOfEntitiesOrNull("item", getItems2(), lambda{|item| item["description"] })
end

def onScreenNotification(title, message)
    title = title.gsub("'","")
    message = message.gsub("'","")
    message = message.gsub("[","|")
    message = message.gsub("]","|")
    command = "terminal-notifier -title '#{title}' -message '#{message}'"
    system(command)
end
