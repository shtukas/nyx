#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

# NSXAgentStreams::getObjects()

class NSXAgentStreams

    # NSXAgentStreams::agentuuid()
    def self.agentuuid()
        "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1"
    end

    def self.getObjects()
        NSXStreamsUtils::pickUpXStreamDropOff()
        ["Right-Now", "Today-Important", "XStream"]
            .map{|streamName|
                NSXStreamsUtils::getStreamItemsOrdered(streamName)
                    .select{|item|
                        objectuuid = item["uuid"][0,8]
                        NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(objectuuid).nil?                      
                    }
                    .first(3)
                    .map{|item| NSXStreamsUtils::streamItemToStreamCatalystObject(streamName, item) }
            }
            .flatten
    end

    def self.processObjectAndCommand(object, command)
        if command=="start" then
            NSXStreamsUtils::startStreamItem(object["data"]["stream-item"]["uuid"])
            return ["reload-agent-objects", NSXAgentStreams::agentuuid()]          
        end
        if command=="stop" then
            NSXStreamsUtils::stopStreamItem(object["data"]["stream-item"]["uuid"])
            return ["reload-agent-objects", NSXAgentStreams::agentuuid()]          
        end
        if command=="open" then
            NSXStreamsUtils::viewItem(object["data"]["stream-item"]["filename"])
            return ["nothing"]          
        end
        if command=="done" then
            NSXStreamsUtils::destroyItem(object["data"]["stream-item"]["filename"])           
            return ["reload-agent-objects", NSXAgentStreams::agentuuid()]
        end
        if command==">xstream" then
            itemuuid = object["data"]["stream-item"]["uuid"]
            globalPosition = LucilleCore::selectEntityFromListOfEntitiesOrNull("position relatively to stream:", ["front", "back"])
            newOrdinal = (globalPosition == "front") ? NSXStreamsUtils::newFrontPositionOrdinalForXStream() : NSXStreamsUtils::newLastPositionOrdinalForXStream()
            NSXStreamsUtils::moveToXStreamAtOrdinal(itemuuid, newOrdinal)
            return ["reload-agent-objects", NSXAgentStreams::agentuuid()]
        end
        ["nothing"]
    end

    def self.interface()

    end

end