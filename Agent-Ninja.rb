#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"
# -------------------------------------------------------------------------------------

NINJA_BINARY_FILEPATH = "/Galaxy/LucilleOS/Binaries/ninja"
NINJA_ITEMS_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Ninja/Items"

# Ninja::flockGeneralUpgrade(flock)

class Ninja

    def self.agentuuid()
        "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58"
    end

    def self.getFolderpathOrNull()
        folderpath = FIFOQueue::getFirstOrNull(CATALYST_COMMON_XCACHE_REPOSITORY, "folderpaths-f363-4a11-9251-b7301406e261")
        if folderpath.nil? then
            JSON.parse(`ninja api:pending`).shuffle.each{|folderpath|
                FIFOQueue::push(CATALYST_COMMON_XCACHE_REPOSITORY, "folderpaths-f363-4a11-9251-b7301406e261", folderpath)
            }
        end
        FIFOQueue::getFirstOrNull(CATALYST_COMMON_XCACHE_REPOSITORY, "folderpaths-f363-4a11-9251-b7301406e261")
    end

    def self.interface()
        
    end

    def self.flockGeneralUpgrade(flock)
        return [flock, []]
        FIFOQueue::takeWhile(CATALYST_COMMON_XCACHE_REPOSITORY, "timestamps-5bd4-431b-9eef-24ca1d005a3c", lambda{|unixtime| (Time.new.to_i - unixtime)>86400 })
        folderpath = Ninja::getFolderpathOrNull()
        if folderpath.nil? then
            return [flock, []]
        end
        metric = 0.195 + 0.4*Math.exp(-FIFOQueue::size(CATALYST_COMMON_XCACHE_REPOSITORY, "timestamps-5bd4-431b-9eef-24ca1d005a3c").to_f/16) + Jupiter::traceToMetricShift("deb58288-31e9-4d20-848d-8ac33d3701ee")
        objects = [
            {
                "uuid" => "96287511",
                "agent-uid" => self.agentuuid(),
                "metric" => metric,
                "announce" => "ninja: folderpath: #{File.basename(folderpath)}",
                "commands" => [],
                "item-data" => {
                    "ninja-folderpath" => folderpath
                }
            }
        ]
        flock["objects"] = flock["objects"] + objects
        [
            flock,
            objects.map{|o|  
                {
                    "event-type" => "Catalyst:Catalyst-Object:1",
                    "object"     => o
                }                
            }   
        ]
    end

    def self.upgradeFlockUsingObjectAndCommand(flock, object, command)
        return [flock, []]
        folderpath = object["item-data"]["ninja-folderpath"]
        system("ninja api:play-folderpath '#{folderpath}'")
        FIFOQueue::takeFirstOrNull(CATALYST_COMMON_XCACHE_REPOSITORY, "folderpaths-f363-4a11-9251-b7301406e261")
        FIFOQueue::push(CATALYST_COMMON_XCACHE_REPOSITORY, "timestamps-5bd4-431b-9eef-24ca1d005a3c", Time.new.to_i)
    end
end