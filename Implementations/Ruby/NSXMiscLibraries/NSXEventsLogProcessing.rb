
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

class NSXEventsLogProcessing

    # NSXEventsLogProcessing::processEvents()
    def self.processEvents()

         NSXEventsLog::eventGarbageCollection()

         NSXEventsLog::allEventsOfGivenTypeNotByInstanceForClientOnlyOnce("DoNotShowUntilDateTime", NSXMiscUtils::instanceName(), "80256506-8e94-40e5-8209-97d719d3cfcd")
         .each{|event|
            NSXDoNotShowUntilDatetime::setDatetime(event["payload"]["objectuuid"], event["payload"]["datetime"], true)
         }

         NSXEventsLog::allEventsOfGivenTypeNotByInstanceForClientOnlyOnce("NSXAgentWave/CommandProcessor/done", NSXMiscUtils::instanceName(), "3d804ca9-a500-4ec1-89fd-fd537015934d")
         .each{|event|
            NSXAgentWaveUtils::performDone2(event["payload"]["objectuuid"], true)
         }

         NSXEventsLog::allEventsOfGivenTypeNotByInstanceForClientOnlyOnce("NSXAgentWave/CommandProcessor/description:", NSXMiscUtils::instanceName(), "90c10492-a99f-4e15-9689-51f858884bcd")
         .each{|event|
            NSXAgentWaveUtils::setItemDescription(event["payload"]["objectuuid"], event["payload"]["description"])
         }

         NSXEventsLog::allEventsOfGivenTypeNotByInstanceForClientOnlyOnce("NSXAgentWave/CommandProcessor/destroy", NSXMiscUtils::instanceName(), "338f5090-7e41-46a7-87dd-170e7a8929c9")
         .each{|event|
            NSXAgentWaveUtils::archiveWaveItem(event["payload"]["objectuuid"])
         }

         NSXEventsLog::allEventsOfGivenTypeNotByInstanceForClientOnlyOnce("NSXRunTimes/addPoint", NSXMiscUtils::instanceName(), "ea311818-6325-44ae-aa31-cd3617bb35cb")
         .each{|event|
            NSXRunTimes::addPoint(event["payload"]["collectionuid"], event["payload"]["unixtime"], event["payload"]["algebraicTimespanInSeconds"])
         }

    end

end
