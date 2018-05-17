#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"
# -------------------------------------------------------------------------------------

NINJA_BINARY_FILEPATH = "/Galaxy/LucilleOS/Binaries/ninja"
NINJA_ITEMS_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Ninja/Items"

# Ninja::flockGeneralUpgrade(flock)

class NinjaFolderPathFeeder
    def initialize()
        @folderpaths = []
    end
    def next()
        if @folderpaths.empty? then
            @folderpaths = JSON.parse(`ninja api:pending`).shuffle
        end
        @folderpaths.shift
    end
end

$ninjaFolderPathFeeder = NinjaFolderPathFeeder.new()

class NinjaTimestampManager
    def addTimestamp()
        FIFOQueue::push(CATALYST_COMMON_XCACHE_REPOSITORY, "timestamps-5bd4-431b-9eef-24ca1d005a3c", Time.new.to_i)
    end
    def getTimestamps()
        FIFOQueue::takeWhile(CATALYST_COMMON_XCACHE_REPOSITORY, "timestamps-5bd4-431b-9eef-24ca1d005a3c", lambda{|unixtime| (Time.new.to_i - unixtime)>86400 })
        FIFOQueue::values(CATALYST_COMMON_XCACHE_REPOSITORY, "timestamps-5bd4-431b-9eef-24ca1d005a3c")
    end
end

$ninjaTimestampManager = NinjaTimestampManager.new()

class Ninja

    def self.agentuuid()
        "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58"
    end

    def self.interface()
        
    end

    def self.flockGeneralUpgrade(flock)
        folderpath = $ninjaFolderPathFeeder.next()
        if folderpath.nil? then
            return [flock, []]
        end
        metric = 0.195 + 0.4*Math.exp(-$ninjaTimestampManager.getTimestamps().size.to_f/16) + Jupiter::traceToMetricShift("deb58288-31e9-4d20-848d-8ac33d3701ee")
        object = {
            "uuid" => "96287511",
            "agent-uid" => self.agentuuid(),
            "metric" => metric,
            "announce" => "ninja: folderpath: #{File.basename(folderpath)}",
            "commands" => [],
            "item-data" => {
                "ninja-folderpath" => folderpath
            }
        }
        flock = FlockPureTransformations::addOrUpdateObject(flock, object)
        [flock, []] # We do not emit an event as the object is transcient
    end

    def self.upgradeFlockUsingObjectAndCommand(flock, object, command)
        folderpath = object["item-data"]["ninja-folderpath"]
        system("ninja api:play-folderpath '#{folderpath}'")
        $ninjaTimestampManager.addTimestamp()
        return [flock, []]
    end
end
