#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

# -------------------------------------------------------------------------------------

$ninja_packet = nil

class NSXAgentTheBridgeDistributedRuby

    # NSXAgentTheBridgeDistributedRuby::agentuuid()
    def self.agentuuid()
        "9fad55cf-3f41-45ae-b480-5cbef40ce57f"
    end

    # NSXAgentTheBridgeDistributedRuby::getObjects()
    def self.getObjects()
        DRbObject.new(nil, "druby://:12345").catalystObjects()
    end

    # NSXAgentTheBridgeDistributedRuby::getAllObjects()
    def self.getAllObjects()
        []
    end

    # NSXAgentTheBridgeDistributedRuby::processObjectAndCommand(object, command)
    def self.processObjectAndCommand(object, command)
        DRbObject.new(nil, "druby://:12345").processObjectAndCommand(object, command)
    end
end

