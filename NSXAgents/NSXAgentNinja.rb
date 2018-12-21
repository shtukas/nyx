#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

# -------------------------------------------------------------------------------------

NINJA_BINARY_FILEPATH = "/Galaxy/LucilleOS/Binaries/ninja"
NINJA_ITEMS_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Ninja/Items"

# NSXAgentNinja::getObjects()

$ninja_packet = nil

# NSXAgentNinja::agentuuid()

class NSXAgentNinja

    def self.agentuuid()
        "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58"
    end

    def self.getObjects()
        if $ninja_packet.nil? then
            $ninja_packet = JSON.parse(`ninja api:next-folderpath-or-null`)[0]
        end
        return [] if $ninja_packet.nil?
        object = {
            "uuid"      => "96287511",
            "agent-uid" => self.agentuuid(),
            "metric"    => 0.2 + 0.6*$ninja_packet["metric"], # The metric given by ninja is between 0 and 1
            "announce"  => "ninja: folderpath: #{$ninja_packet["folderpath"]}",
            "commands"  => [],
            "default-expression" => "play",
            "item-data" => {
                "ninja-folderpath" => $ninja_packet["folderpath"]
            }
        }
        [object]
    end

    def self.processObjectAndCommand(object, command)
        if command == "play" then
            folderpath = object["item-data"]["ninja-folderpath"]
            system("ninja api:play-folderpath '#{folderpath}'")
            $ninja_packet = nil
        end
    end

    def self.interface()

    end

end
