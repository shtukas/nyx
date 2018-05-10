#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"
=begin
    # The set of values that we support is whatever that can be json serialisable.
    FIFOQueue::size(repositorylocation or nil, queueuuid)
    FIFOQueue::values(repositorylocation or nil, queueuuid)
    FIFOQueue::push(repositorylocation or nil, queueuuid, value)
    FIFOQueue::getFirstOrNull(repositorylocation or nil, queueuuid)
    FIFOQueue::takeFirstOrNull(repositorylocation or nil, queueuuid)
    FIFOQueue::takeWhile(repositorylocation, queueuuid, xlambda: Element -> Boolean)
=end
# -------------------------------------------------------------------------------------

NINJA_BINARY_FILEPATH = "/Galaxy/LucilleOS/Binaries/ninja"
NINJA_ITEMS_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Ninja/Items"

class Ninja

    def self.getFolderpathOrNull()
        folderpath = FIFOQueue::getFirstOrNull(nil, "folderpaths-f363-4a11-9251-b7301406e261")
        if folderpath.nil? then
            JSON.parse(`ninja api:pending`).shuffle.each{|folderpath|
                FIFOQueue::push(nil, "folderpaths-f363-4a11-9251-b7301406e261", folderpath)
            }
        end
        FIFOQueue::getFirstOrNull(nil, "folderpaths-f363-4a11-9251-b7301406e261")
    end

    # Ninja::getCatalystObjects()
    def self.getCatalystObjects()
        FIFOQueue::takeWhile(nil, "timestamps-5bd4-431b-9eef-24ca1d005a3c", lambda{|unixtime| (Time.new.to_i - unixtime)>86400 })
        folderpath = Ninja::getFolderpathOrNull()
        if folderpath.nil? then
            return []
        end
        metric = 0.2 + 0.4*Math.exp(-FIFOQueue::size(nil, "timestamps-5bd4-431b-9eef-24ca1d005a3c").to_f/16)
        [
            {
                "uuid" => "96287511",
                "metric" => metric,
                "announce" => "ninja: folderpath: #{File.basename(folderpath)}",
                "commands" => [],
                "command-interpreter" => lambda{|object, command|
                    folderpath = object["ninja-folderpath"]
                    system("ninja api:play-folderpath '#{folderpath}'")
                    FIFOQueue::takeFirstOrNull(nil, "folderpaths-f363-4a11-9251-b7301406e261")
                    FIFOQueue::push(nil, "timestamps-5bd4-431b-9eef-24ca1d005a3c", Time.new.to_i)
                },
                "ninja-folderpath" => folderpath
            }
        ]
    end
end