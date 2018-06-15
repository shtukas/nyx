#!/usr/bin/ruby

# encoding: UTF-8
require 'json'
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "Ninja",
        "agent-uid"       => "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58",
        "general-upgrade" => lambda { AgentNinja::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentNinja::processObjectAndCommandFromCli(object, command) },
        "interface"       => lambda{ AgentNinja::interface() }
    }
)

NINJA_BINARY_FILEPATH = "/Galaxy/LucilleOS/Binaries/ninja"
NINJA_ITEMS_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Ninja/Items"

# AgentNinja::generalFlockUpgrade()

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

# AgentNinja::agentuuid()

class AgentNinja

    def self.agentuuid()
        "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58"
    end

    def self.interface()
        
    end

    def self.generalFlockUpgrade()
        packet = NinjaCLIProxy::packet()
        return if packet.nil?
        object = {
            "uuid"      => "96287511",
            "agent-uid" => self.agentuuid(),
            "metric"    => packet["metric"],
            "announce"  => "ninja: folderpath: #{packet["folderpath"]}",
            "commands"  => [],
            "default-expression" => "play",
            "item-data" => {
                "ninja-folderpath" => packet["folderpath"]
            }
        }
        TheFlock::addOrUpdateObject(object)
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command == "play" then
            folderpath = object["item-data"]["ninja-folderpath"]
            system("ninja api:play-folderpath '#{folderpath}'")
            NinjaCLIProxy::reset()
            TheFlock::removeObjectIdentifiedByUUID(object["uuid"])
        end
    end
end
