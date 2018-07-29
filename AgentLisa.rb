#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'json'
require 'date'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'find'
require 'json'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "AgentLisa",
        "agent-uid"       => "201cac75-9ecc-4cac-8ca1-2643e962a6c6",
        "general-upgrade" => lambda { AgentLisa::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentLisa::processObjectAndCommand(object, command) },
        "interface"       => lambda{ AgentLisa::interface() }
    }
)

class AgentLisa

    def self.agentuuid()
        "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
    end

    def self.interface()
        
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        LisaUtils::lisasWithFilepaths()
            .map{|data|
                lisa, filepath = data
                LisaUtils::makeCatalystObjectFromLisaAndFilepath(lisa, filepath)
            }
            .each{|object|
                if object["is-running"] and object["item-data"]["ratio"] > 1 then
                    system("terminal-notifier -title 'Catalyst Lisa' -message '#{object["item-data"]["lisa"]["description"]} is done'")
                    sleep 2
                end
                TheFlock::addOrUpdateObject(object) 
            }
    end

    def self.processObjectAndCommand(object, command)
        uuid = object["uuid"]
        lisa = object["item-data"]["lisa"]
        if command=='start' then
            Chronos::start(uuid)
            # If a starting lisa is targetting a list, that list should become the default display
            lisa = object["item-data"]["lisa"]
            if lisa["target"] then
                puts "This lisa has a target: #{JSON.generate(lisa["target"])}"
                LucilleCore::pressEnterToContinue()
                if lisa["target"][0] == "list" then
                    displaymode = ["list", lisa["target"][1]] # Yes displaymode is lisa["target"] :)
                    DisplayModeManager::putDisplayMode(displaymode)
                    # --------------------------------------------------------------------------
                    # Marker: a53eb0fc-b557-4265-a13b-a6e4a397cf87
                    # And now we are attempting a reverse look up so that CommonsUtils::flockObjectsUpdatedForDisplay()
                    # ... knows this came from a Lisa
                    FKVStore::set("lisauuid:50047ec7-3a7d-4d55-a191-708ae19e9d9f", lisa["uuid"])
                    # This is not perfect but will do until list display modes can be set by non lisa entities
                    # --------------------------------------------------------------------------
                end
            end
        end
        if command=='stop' then
            Chronos::stop(uuid)
            if lisa["target"] then
                if lisa["target"][0] == "list" then
                    displaymode = ["default"]
                    DisplayModeManager::putDisplayMode(displaymode)
                end
            end
            lisauuid = lisa["uuid"]
            timestructure = lisa["time-structure"]
            timedoneInHours, timetodoInHours, ratio = LisaUtils::metricsForTimeStructure(lisauuid, timestructure)
            if ratio>1 and !lisa["repeat"] then
                puts "destroying lisa: #{JSON.generate(lisa)}"
                LucilleCore::pressEnterToContinue()
                filepath = object["item-data"]["filepath"]
                FileUtils.rm(filepath)
            end
        end
        if command=="add-time" then
            timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
            Chronos::addTimeInSeconds(uuid, timeInHours*3600)
        end
        if command=='destroy' 
            filepath = object["item-data"]["filepath"]
            FileUtils.rm(filepath)
        end
        if command=='set-target'
            LisaUtils::ui_setInteractivelySelectedTargetForLisa(lisa["uuid"])
        end
    end
end
