#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "time"

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# -------------------------------------------------------------------------------------

BABY_NIGHTS_DATA_FOLDER = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/BabyNights/data"
BABY_NIGHT_KVSTORE_FOLDER = "/Galaxy/DataBank/Catalyst/Agents-Data/BabyNights/kvstore"
BABY_NIGHTS_OPERATION_DROP = "dropping luc"
BABY_NIGHTS_OPERATION_PICKUP = "pick luc up"
BABY_NIGHTS_OPERATION_NIGHT = "night"

$OPERATIONS_TO_REWARDS = {
    BABY_NIGHTS_OPERATION_DROP   => 0.3,
    BABY_NIGHTS_OPERATION_PICKUP => 0.55,
    BABY_NIGHTS_OPERATION_NIGHT  => 1
}

# event: [<date>, <weekname>, <operation>]

class NSXAgentBabyNights

    # NSXAgentBabyNights::daynames()
    def self.daynames()
        ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    end

    # NSXAgentBabyNights::evenTrace(event)
    def self.evenTrace(event)
        Digest::SHA1.hexdigest(JSON.generate(event))
    end

    # NSXAgentBabyNights::markEventAsProcessed(event)
    def self.markEventAsProcessed(event)
        KeyValueStore::setFlagTrue(BABY_NIGHT_KVSTORE_FOLDER, "64a57a44-bc77-4c79-a70a-dc9b256083b3:#{NSXAgentBabyNights::evenTrace(event)}")
    end

    # NSXAgentBabyNights::trueIfEventAsBeenProcessed(event)
    def self.trueIfEventAsBeenProcessed(event)
        KeyValueStore::flagIsTrue(BABY_NIGHT_KVSTORE_FOLDER, "64a57a44-bc77-4c79-a70a-dc9b256083b3:#{NSXAgentBabyNights::evenTrace(event)}")
    end

    # NSXAgentBabyNights::next(event)
    def self.next(event)
        if event[2] == BABY_NIGHTS_OPERATION_DROP then
            return [ event[0], event[1], BABY_NIGHTS_OPERATION_PICKUP ]
        end
        if event[2] == BABY_NIGHTS_OPERATION_PICKUP then
            return [ event[0], event[1], BABY_NIGHTS_OPERATION_NIGHT ]
        end
        if event[2] == BABY_NIGHTS_OPERATION_NIGHT then
            newdate = Date.parse(event[0])+1
            return [ newdate.to_s, NSXAgentBabyNights::daynames()[newdate.to_time.wday], BABY_NIGHTS_OPERATION_DROP ]
        end
    end

    # NSXAgentBabyNights::nearbyEvents()
    def self.nearbyEvents()
        events = []
        events << [ NSXMiscUtils::nDaysAgo(7), NSXAgentBabyNights::daynames()[Date.parse(NSXMiscUtils::nDaysAgo(7)).to_time.wday], BABY_NIGHTS_OPERATION_DROP ]
        loop {
            event = NSXAgentBabyNights::next(events.last)
            break if event[0] > NSXMiscUtils::nDaysAgo(0)
            events << event
        }
        events
    end

    # NSXAgentBabyNights::isPendingEvent(event)
    def self.isPendingEvent(event)
        return false if event[1] == "saturday" and event[2] == BABY_NIGHTS_OPERATION_DROP
        return false if event[1] == "saturday" and event[2] == BABY_NIGHTS_OPERATION_PICKUP
        return false if event[1] == "sunday" and event[2] == BABY_NIGHTS_OPERATION_DROP
        return false if event[1] == "sunday" and event[2] == BABY_NIGHTS_OPERATION_PICKUP
        return false if NSXAgentBabyNights::trueIfEventAsBeenProcessed(event)
        if  event[0] == NSXMiscUtils::currentDay() then
            if event[2] == BABY_NIGHTS_OPERATION_DROP then
                return Time.new.hour >= 9
            end
            if event[2] == BABY_NIGHTS_OPERATION_PICKUP then
                return Time.new.hour >= 18
            end
            if event[2] == BABY_NIGHTS_OPERATION_NIGHT then
                return Time.new.hour >= 20
            end
        else
           return true
        end
    end

    # NSXAgentBabyNights::pendingEvents()
    def self.pendingEvents()
        NSXAgentBabyNights::nearbyEvents().select{|event| NSXAgentBabyNights::isPendingEvent(event) }
    end

    # NSXAgentBabyNights::agentuuid()
    def self.agentuuid()
        "83837e64-554b-4dd0-a478-04386d8010ea"
    end

    def self.names()
        ["pascal", "tracy", "holidays"]
    end

    # NSXAgentBabyNights::getObjects()
    def self.getObjects()
        if NSXAgentBabyNights::pendingEvents().size>0 then
            NSXAgentBabyNights::getAllObjects()
        else
            []
        end
    end

    # NSXAgentBabyNights::getAllObjects()
    def self.getAllObjects()
        [
            {
                "uuid"      => "4b9bcf0a",
                "agentuid"  => self.agentuuid(),
                "metric"    => 1,
                "announce"  => "👶 Mining",
                "commands"  => [],
                "defaultExpression" => "update"
            }
        ]
    end

    # NSXAgentBabyNights::processEvent(event)
    def self.processEvent(event)
        puts event.join(', ')
        xname = LucilleCore::selectEntityFromListOfEntitiesOrNull("Name", ["pascal", "tracy", "exception"])
        if xname == "exception" then
            NSXAgentBabyNights::markEventAsProcessed(event)
            return
        end
        data = JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/BabyNights/data.json"))
        reward = $OPERATIONS_TO_REWARDS[event[2]]
        data[xname] = data[xname] + reward
        puts event.join(', ')
        puts "👶 Mining: [Pascal: #{data["pascal"].round(2)}, Tracy: #{data["tracy"].round(2)}]"
        if data["pascal"] >= 10 and data["tracy"] >= 10 then
            data["pascal"] = data["pascal"] - 10 
            data["tracy"] = data["tracy"] - 10 
            puts "👶 Mining [Pascal: #{data["pascal"].round(2)}, Tracy: #{data["tracy"].round(2)}]"
        end
        LucilleCore::pressEnterToContinue()
        File.open("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/BabyNights/data.json", "w"){|f| f.puts(JSON.pretty_generate(data)) }
        NSXAgentBabyNights::markEventAsProcessed(event)
    end

    # NSXAgentBabyNights::processObjectAndCommand(object, command)
    def self.processObjectAndCommand(object, command)
        if command == "update" then
            NSXAgentBabyNights::pendingEvents().each{|event|
                NSXAgentBabyNights::processEvent(event)
            }
            return ["remove", object["uuid"]]
        end
        [nil]
    end
end
