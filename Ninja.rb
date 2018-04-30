#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

# -------------------------------------------------------------------------------------

NINJA_BINARY_FILEPATH = "/Galaxy/LucilleOS/Binaries/ninja"
NINJA_DROPOFF_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Ninja-DropOff"
NINJA_ITEMS_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Ninja/Items"

class Ninja

    # Ninja::collectDropOffObjects()
    def self.collectDropOffObjects()
        Dir.entries(NINJA_DROPOFF_FOLDERPATH)
            .select{|filename| filename[0, 1] != '.' }
            .map{|filename| "#{NINJA_DROPOFF_FOLDERPATH}/#{filename}" }
            .each{|sourcelocation|
                folderpath = "#{NINJA_ITEMS_REPOSITORY_FOLDERPATH}/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y%m")}/#{Time.new.strftime("%Y%m%d")}/#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}-ninja"
                FileUtils.mkpath(folderpath)
                if File.file?(sourcelocation) then
                    FileUtils.cp(sourcelocation,folderpath)
                else
                    FileUtils.cp_r(sourcelocation,folderpath)
                end
                LucilleCore::removeFileSystemLocation(sourcelocation)
            }
    end

    def self.pendingCountAtBeginningOfDay()
        key = "6f6e355b-300d-42b1-a94b-117c37c06f1a:#{Time.new.to_s[0,10]}"
        count = KeyValueStore::getOrNull(nil, key)
        if count.nil? then
            count = `/Galaxy/LucilleOS/Binaries/ninja api:catalyst:pendingcount`.to_i
            KeyValueStore::set(nil, key, count)
            count
        else
            count.to_i
        end
    end

    def self.dayActivityCount()
        `/Galaxy/LucilleOS/Binaries/ninja api:catalyst:today-activity-count`.to_i
    end

    def self.metric()
        todaydone = Ninja::dayActivityCount()
        todaytotal = Ninja::pendingCountAtBeginningOfDay()
        return 0 if todaydone > todaytotal
        0.2 + 0.4 * Math.exp( - todaydone.to_f / todaytotal )
    end

    # Ninja::getCatalystObjectsFromScratch()
    def self.getCatalystObjectsFromScratch()
        Ninja::collectDropOffObjects()
        objects = []
        metric = Ninja::metric()
        objects << {
            "uuid" => "90d11712",
            "metric" => metric,
            "announce" => "ninja training",
            "commands" => [],
            "command-interpreter" => lambda{|object, command|  
                Ninja::commandInterpreter(object, commands)
            }
        } 
        objects
    end

    # Ninja::getCatalystObjects()
    def self.getCatalystObjects()
        Ninja::collectDropOffObjects()
        JSON.parse(KeyValueStore::getOrDefaultValue(nil, "B64F5806-5864-49E8-9FD3-AE7B90719C19", "[]"))
            .map{ |object|
                object["command-interpreter"] = lambda{|object, command| Ninja::commandInterpreter(object, command) } # overriding this after deserialistion 
                object
            }
    end

    # Ninja::commandInterpreter(object, command)
    def self.commandInterpreter(object, command)
        system('ninja play')
        KeyValueStore::set(nil, "B64F5806-5864-49E8-9FD3-AE7B90719C19", JSON.generate(Ninja::getCatalystObjectsFromScratch()))
    end
end

# -------------------------------------------------------------------------------------

KeyValueStore::set(nil, "B64F5806-5864-49E8-9FD3-AE7B90719C19", JSON.generate(Ninja::getCatalystObjectsFromScratch()))
