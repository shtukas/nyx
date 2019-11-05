
# encoding: UTF-8

require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "json"

# ----------------------------------------------------------------------

=begin

Event (
    "uuid"          : String
    "timestamp"     : Float
    "instanceName"  : String
    "eventType"     : String
    "payload"       : Value or Object
)

The event is stored on disk in a file with name <l22DateString>.event

=end

class NSXEventsLog

    # NSXEventsLog::l22DateStringToFilepath(l22)
    def self.l22DateStringToFilepath(l22)
        # 20191030-173258-161373
        folderpath1 = "#{DATABANK_CATALYST_FOLDERPATH}/Events-Log/Events"
        pathFragment = "#{l22[0,4]}/#{l22[0,6]}/#{l22[0,8]}"
        folderpath2 = "#{folderpath1}/#{pathFragment}"
        folderpath3 = LucilleCore::indexsubfolderpath(folderpath2)
        "#{folderpath3}/#{l22}.json"
    end

    # NSXEventsLog::issueEvent(instanceName: String, eventType: String, payload: Payload)
    def self.issueEvent(instanceName, eventType, payload)
        l22 = NSXMiscUtils::timeStringL22()
        event = {}
        event["uuid"] = SecureRandom.uuid
        event["timestamp"] = Time.new.to_f
        event["instanceName"] = instanceName
        event["eventType"] = eventType
        event["payload"] = payload
        File.open(NSXEventsLog::l22DateStringToFilepath(l22), "w"){|f| f.puts(JSON.pretty_generate(event)) }
    end

    # NSXEventsLog::eventEnumerator()
    def self.eventEnumerator()
        Enumerator.new do |events|
            Find.find("#{DATABANK_CATALYST_FOLDERPATH}/Events-Log/Events") do |path|
                next if !File.file?(path)
                next if File.basename(path)[-5, 5] != '.json'
                events << JSON.parse(IO.read(path))
            end
        end
    end

    # NSXEventsLog::eventsOrdered()
    def self.eventsOrdered()
        NSXEventsLog::eventEnumerator()
            .to_a
            .sort{|e1, e2| e1["timestamp"] <=> e2["timestamp"] }
    end

    # NSXEventsLog::markEventAsHavingBeenGivenToClient(eventuuid, clientID)
    def self.markEventAsHavingBeenGivenToClient(eventuuid, clientID)
        KeyValueStore::setFlagTrue(nil, "#{eventuuid}/#{clientID}")
    end

    # NSXEventsLog::trueIfEventHasBeenGivenToClient(eventuuid, clientID)
    def self.trueIfEventHasBeenGivenToClient(eventuuid, clientID)
        KeyValueStore::flagIsTrue(nil, "#{eventuuid}/#{clientID}")
    end

    # NSXEventsLog::allEventsOfGivenTypeNotByInstanceForClientOnlyOnce(eventType, instanceName, clientID)
    def self.allEventsOfGivenTypeNotByInstanceForClientOnlyOnce(eventType, instanceName, clientID)
        events = NSXEventsLog::eventsOrdered()
            .select{|event| event["eventType"] == eventType }
            .reject{|event| event["instanceName"] == instanceName }
            .reject{|event| NSXEventsLog::trueIfEventHasBeenGivenToClient(event["uuid"], clientID) }
        events.each{|event| NSXEventsLog::markEventAsHavingBeenGivenToClient(event["uuid"], clientID) }
        events
    end

end
