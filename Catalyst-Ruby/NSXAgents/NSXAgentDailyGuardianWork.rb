#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

class NSXAgentDailyGuardianWork

    # NSXAgentDailyGuardianWork::agentuid()
    def self.agentuid()
        "a6d554fd-44bf-4937-8dc6-5c9f1dcdaeba"
    end

    # NSXAgentDailyGuardianWork::getObjects()
    def self.getObjects()
        NSXAgentDailyGuardianWork::getAllObjects()
    end

    # NSXAgentDailyGuardianWork::getAllObjects()
    def self.getAllObjects()
        return [] if [0,6].include?(Time.new.wday)
        return [] if Time.new.hour < 9
        return [] if KeyValueStore::flagIsTrue(nil, "33319c02-f1cd-4296-a772-43bb5b6ba07f:#{NSXMiscUtils::currentDay()}")
        uuid = "392eb09c-572b-481d-9e8e-894e9fa016d4-so1"
        announce = "Daily Guardian Work"
        contentItem = {
            "type" => "line",
            "line" => announce
        }
        object = {}
        object["uuid"]           = uuid
        object["agentuid"]       = "a6d554fd-44bf-4937-8dc6-5c9f1dcdaeba"
        object["contentItem"]    = contentItem
        object["metric"]         = 0.60
        object["commands"]       = ["done"]
        object["defaultCommand"] = nil
        [object]
    end

    # NSXAgentDailyGuardianWork::processObjectAndCommand(objectuuid, command, isLocalCommand)
    def self.processObjectAndCommand(objectuuid, command, isLocalCommand)
        if command == "done" then
            KeyValueStore::setFlagTrue(nil, "33319c02-f1cd-4296-a772-43bb5b6ba07f:#{NSXMiscUtils::currentDay()}")
            return 
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentDailyGuardianWork",
            "agentuid"    => NSXAgentDailyGuardianWork::agentuid(),
        }
    )
rescue
end

