#!/usr/bin/ruby

# encoding: UTF-8

# -------------------------------------------------------------------------------------

NINJA_BINARY_FILEPATH = "/Galaxy/LucilleOS/Binaries/ninja"
NINJA_DROPOFF_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Ninja-DropOff"
NINJA_ITEMS_REPOSITORY_FOLDERPATH = "/Galaxy/DataBank/Ninja/Items"

class Ninja

    # Ninja::collectNinjaObjects()
    def self.collectNinjaObjects()
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

    # Ninja::getCatalystObjects()
    def self.getCatalystObjects()

        Ninja::collectNinjaObjects()

        objects = []
        pendingcount = `/Galaxy/LucilleOS/Binaries/ninja api:catalyst:pendingcount`.to_i
        dayactivitycount = `/Galaxy/LucilleOS/Binaries/ninja api:catalyst:last-24-hours-activity-count`.to_i
        metric = pendingcount==0 ? 0 : 0.2 + 0.1*Math.exp(-dayactivitycount.to_f/20)
            # The second term raise the metric from 0 to 1 as the pending count increases
            # The third term collapse from 1 to 0 as the last-24-hours-activity-count raises
        objects << {
            "uuid" => "44a372b9-32d4-4fb7-884d-efba45616961",
            "metric" => metric,
            "announce" => "(#{"%.3f" % metric}) ninja play",
            "commands" => [],
            "default-commands" => ['play'],
            "command-interpreter" => lambda{|object, command|  
                if command=='play' then
                    system('ninja play')
                end
            }
        } 
        objects
    end
end
