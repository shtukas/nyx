
# encoding: UTF-8

require "/Users/pascal/Galaxy/2020-LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/2020-LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
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

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

# ----------------------------------------------------------------------

=begin

Event (
    "uuid"                : String
    "timestamp"           : Float
    "l22"                 : l22DateTimeString
    "targetInstanceName"  : String
    "eventType"           : String
    "payload"             : Value or Object
    "filepath"            : [ re set at retrieval ]
)

The event is stored on disk in a file with name <l22DateTimeString>.json

=end

class NSXEventsLog

    # NSXEventsLog::l22StringToFilepath(l22)
    def self.l22StringToFilepath(l22)
        # 20191030-173258-161373
        "#{DATABANK_CATALYST_FOLDERPATH}/Events-Log/Events/#{l22}.json"
    end

    # NSXEventsLog::issueEventForTarget(targetInstanceName: String, eventType: String, payload: Payload)
    def self.issueEventForTarget(targetInstanceName, eventType, payload)
        l22 = NSXMiscUtils::timeStringL22()
        filepath = NSXEventsLog::l22StringToFilepath(l22)
        event = {}
        event["uuid"] = SecureRandom.uuid
        event["timestamp"] = Time.new.to_f
        event["l22"] = l22
        event["targetInstanceName"] = targetInstanceName
        event["eventType"] = eventType
        event["payload"] = payload
        event["filepath"] = filepath
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(event)) }
    end

    # NSXEventsLog::issueEvent(eventType: String, payload: Payload)
    def self.issueEvent(eventType, payload)
        NSXMiscUtils::instanceNames()
            .reject{|instanceName| instanceName == NSXMiscUtils::thisInstanceName() }
            .each{|targetInstanceName| NSXEventsLog::issueEventForTarget(targetInstanceName, eventType, payload) }
    end

    # NSXEventsLog::eventEnumerator()
    def self.eventEnumerator()
        Enumerator.new do |events|
            Find.find("#{DATABANK_CATALYST_FOLDERPATH}/Events-Log/Events") do |path|
                next if !File.file?(path)
                next if File.basename(path)[-5, 5] != '.json'
                event = JSON.parse(IO.read(path))
                event["filepath"] = path
                events << event
            end
        end
    end

    # NSXEventsLog::eventsOrdered()
    def self.eventsOrdered()
        NSXEventsLog::eventEnumerator()
            .to_a
            .sort{|e1, e2| e1["timestamp"] <=> e2["timestamp"] }
    end

end

class NSXEventsLogProcessing

    # NSXEventsLogProcessing::processEvents()
    def self.processEvents()

        NSXEventsLog::eventsOrdered()
            .select{|event| event["targetInstanceName"] == NSXMiscUtils::thisInstanceName() }
            .each{|event|

                if event["eventType"] == "DoNotShowUntilDateTime" then
                    NSXDoNotShowUntilDatetime::setDatetime(event["payload"]["objectuuid"], event["payload"]["datetime"], true)
                    FileUtils.rm(event["filepath"])
                    next
                end

                if event["eventType"] == "NSXAgentWave/CommandProcessor/done" then
                    NSXWaveUtils::performDone2(event["payload"]["objectuuid"], true)
                    FileUtils.rm(event["filepath"])
                    next
                end

                if event["eventType"] == "NSXAgentWave/CommandProcessor/description:" then
                    NSXWaveUtils::setItemDescription(event["payload"]["objectuuid"], event["payload"]["description"])
                    FileUtils.rm(event["filepath"])
                    next
                end

                if event["eventType"] == "NSXAgentWave/CommandProcessor/destroy" then
                    NSXWaveUtils::archiveWaveItem(event["payload"]["objectuuid"])
                    FileUtils.rm(event["filepath"])
                    next
                end

                if event["eventType"] == "NSXRunTimes/addPoint" then
                    NSXRunTimes::addPoint(event["payload"]["collectionuid"], event["payload"]["unixtime"], event["payload"]["algebraicTimespanInSeconds"])
                    FileUtils.rm(event["filepath"])
                    next
                end

            }

    end

end
