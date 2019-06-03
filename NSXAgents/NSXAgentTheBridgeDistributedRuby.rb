#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

# -------------------------------------------------------------------------------------

class NSXAgentTheBridgeDistributedRuby

    # NSXAgentTheBridgeDistributedRuby::agentuuid()
    def self.agentuuid()
        "9fad55cf-3f41-45ae-b480-5cbef40ce57f"
    end

    # NSXAgentTheBridgeDistributedRuby::servicePortNumbers()
    def self.servicePortNumbers()
        [12345, 12350, 12355, 12360, 12365, 12370]
    end

    # NSXAgentTheBridgeDistributedRuby::getObjects()
    def self.getObjects()
        NSXAgentTheBridgeDistributedRuby::servicePortNumbers()
            .map{|postNumber|
                begin
                    DRbObject.new(nil, "druby://:12345").catalystObjects()
                rescue
                    object = {}
                    object["uuid"] = "0c1daadd-5759-4775-9b42-957bf9701506:#{postNumber}"
                    object["agentuid"] = nil
                    object["metric"] = 1
                    object["announce"] = "Error while calling NSXAgentTheBridgeDistributedRuby service #{servicePort}"
                    object["commands"] = []
                    [object]
                end
            }
            .flatten
    end

    # NSXAgentTheBridgeDistributedRuby::getAllObjects()
    def self.getAllObjects()
        []
    end

    # NSXAgentTheBridgeDistributedRuby::processObjectAndCommand(object, command)
    def self.processObjectAndCommand(object, command)
        servicePort = object["service-port"]
        DRbObject.new(nil, "druby://:#{servicePort}").processObjectAndCommand(object, command)
    end
end

