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
        "object-command-processor" => lambda{ |object, command| AgentLisa::processObjectAndCommand(object, command) }
    }
)

class AgentLisa
    def self.agentuuid()
        "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
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
                    system("terminal-notifier -title 'Catalyst Lisa' -message '#{object["item-data"]["lisa"]["description"].gsub("'","")} is done'")
                    sleep 2
                end
                TheFlock::addOrUpdateObject(object) 
            }
    end

    def self.processObjectAndCommand(object, command)
        uuid = object["uuid"]
        lisa = object["item-data"]["lisa"]
        if command=='start' then
            LisaUtils::startLisa(lisa)
        end
        if command=='stop' then
            LisaUtils::stopLisa(lisa)
        end
        if command=="add-time" then
            timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
            Chronos::addTimeInSeconds(uuid, timeInHours*3600)
        end
        if command=='edit' then
            filename = "#{SecureRandom.hex}.json"
            filepath = "/tmp/#{filename}"
            lisa = JSON.parse(CommonsUtils::editTextUsingTextmate(JSON.pretty_generate(lisa)))
            lisaFilepath = LisaUtils::getLisaFilepathFromLisaUUIDOrNull(lisa["uuid"])
            LisaUtils::commitLisaToDisk(lisa, File.basename(lisaFilepath))
        end
        if command=='destroy'
            loop {
                break if !lisa["target"]
                break if lisa["target"][0]!="list"
                puts "This lisa has a list target, I need to destroy the list first"
                puts "Not implemented yet!"
                LucilleCore::pressEnterToContinue()
                return
                break
            }
            filepath = object["item-data"]["filepath"]
            FileUtils.rm(filepath)
        end
        if command=='set-target'
            LisaUtils::ui_setInteractivelySelectedTargetForLisa(lisa["uuid"])
        end
    end
end
