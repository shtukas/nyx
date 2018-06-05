#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

require_relative "Events.rb"
require_relative "MiniFIFOQ.rb"
# -------------------------------------------------------------------------------------

NINJA_BINARY_FILEPATH = "/Galaxy/LucilleOS/Binaries/ninja"
NINJA_ITEMS_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Ninja/Items"

# Ninja::generalUpgrade()

class NinjaCLIProxy
    @@packet = nil
    def self.packet()
        if @@packet.nil? then
            @@packet = JSON.parse(`ninja api:next-folderpath-or-null`)[0]
        end
        @@packet
    end
    def self.reset()
        @@packet = nil
    end
end

class Ninja

    def self.agentuuid()
        "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58"
    end

    def self.interface()
        
    end

    def self.generalUpgrade()
        packet = NinjaCLIProxy::packet()
        return if packet.nil?
        object = {
            "uuid" => "96287511",
            "agent-uid" => self.agentuuid(),
            "metric" => packet["metric"],
            "announce" => "ninja: folderpath: #{packet["folderpath"]}",
            "commands" => [],
            "default-expression" => "play",
            "item-data" => {
                "ninja-folderpath" => packet["folderpath"]
            }
        }
        DRbObject.new(nil, "druby://:18171").flockOperator_addOrUpdateObject(object)
    end

    def self.processObjectAndCommand(object, command)
        folderpath = object["item-data"]["ninja-folderpath"]
        system("ninja api:play-folderpath '#{folderpath}'")
        NinjaCLIProxy::reset()
        DRbObject.new(nil, "druby://:18171").flockOperator_removeObjectIdentifiedByUUID(object["uuid"])
    end
end
