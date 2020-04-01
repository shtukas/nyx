#!/usr/bin/ruby

# encoding: UTF-8
require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

class NSXAgentTheBridge

    # NSXAgentTheBridge::agentuid()
    def self.agentuid()
        "a64c458b-e6a1-4d02-a35c-dd4e4a78f139"
    end

    # NSXAgentTheBridge::getObjects()
    def self.getObjects()
        NSXAgentTheBridge::getAllObjects()
    end

    # NSXAgentTheBridge::getAllObjects()
    def self.getAllObjects()
        JSON.parse(IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/Data/TheBridge/sources.json"))
        .map{|source|
            JSON.parse(`#{source}`)
        }
        .flatten
    end

    # NSXAgentTheBridge::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)

    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentTheBridge",
            "agentuid"    => NSXAgentTheBridge::agentuid(),
        }
    )
rescue
end
