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

def companionsKeyPrefix()
    getItems()
        .map{|item| item["uuid"] }
        .sort
        .join("-")
end

def getCompanion(uuid)
    status = KeyValueStore::getOrNull(nil, "#{companionsKeyPrefix()}:#{uuid}")
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
    KeyValueStore::set(nil, "#{companionsKeyPrefix()}:#{status["uuid"]}", JSON.generate(status))
end

def getItemTimespan(uuid)
    status = getCompanion(uuid)
    status["timesPoints"].map{|point| point["timespan"] }.inject(0, :+)
end

def itemsOrderedByTimespan()
    getItems().sort{|i1, i2| getItemTimespan(i1["uuid"]) <=> getItemTimespan(i2["uuid"]) }
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
        .each{|item| report << "running: #{item["description"]}".green }
    nextaction = getNextAction()
    if nextaction then
        report << nextaction[0] # can be null
    end
    report.compact.join(" ; ")
end

def getReportText()
    nsize = getItems().map{|item| item["description"].size }.max
    report = itemsOrderedByTimespan()
                .map{|item| 
                    companion = getCompanion(item["uuid"])
                    "#{item["description"].ljust(nsize)} (#{"%6.2f" % (getItemTimespan(item["uuid"]).to_f/3600)} hours)"
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
