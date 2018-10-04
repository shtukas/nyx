#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

# -------------------------------------------------------------------------------------

NINJA_BINARY_FILEPATH = "/Galaxy/LucilleOS/Binaries/ninja"
NINJA_ITEMS_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Ninja/Items"

# NSXAgentNinja::getObjects()

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

# NSXAgentNinja::agentuuid()

class NSXAgentNinja

    def self.agentuuid()
        "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58"
    end

    def self.getObjects()
        packet = NinjaCLIProxy::packet()
        return [] if packet.nil?
        object = {
            "uuid"      => "96287511",
            "agent-uid" => self.agentuuid(),
            "metric"    => 0.2 + 0.3*packet["metric"], # The metric given by ninja is between 0 and 1
            "announce"  => "ninja: folderpath: #{packet["folderpath"]}",
            "commands"  => [],
            "default-expression" => "play",
            "item-data" => {
                "ninja-folderpath" => packet["folderpath"]
            }
        }
        [object]
    end

    def self.processObjectAndCommand(object, command)
        if command == "play" then
            folderpath = object["item-data"]["ninja-folderpath"]
            system("ninja api:play-folderpath '#{folderpath}'")
            NinjaCLIProxy::reset()
            return ["remove", object["uuid"]]
        end
        ["nothing"]
    end
end
