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
        "agent-name"      => "AgentTimeProton",
        "agent-uid"       => "201cac75-9ecc-4cac-8ca1-2643e962a6c6",
        "general-upgrade" => lambda { AgentTimeProton::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentTimeProton::processObjectAndCommand(object, command) }
    }
)

class AgentTimeProton
    def self.agentuuid()
        "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        TimeProtonUtils::timeProtonsWithFilepaths()
            .each{|pair|
                timeProton, filepath = pair
                object = TimeProtonUtils::makeCatalystObjectFromTimeProtonAndFilepath(timeProton, filepath)
                TheFlock::addOrUpdateObject(object)
            }
    end

    def self.processObjectAndCommand(object, command)
        uuid = object["uuid"]
        timeProton = object["item-data"]["timeProton"]
        filepath   = object["item-data"]["filepath"]
        if command=='start' then
            TimeProtonUtils::startTimeProton(uuid)
        end
        if command=='stop' then
            TimeProtonUtils::stopTimeProton(uuid)
        end
        if command=="time:" then
            timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
            TimeProtonUtils::timeProtonAddTime(timeprotonuuid, timeInHours)
        end
        if command=='edit' then
            filename = "#{SecureRandom.hex}.json"
            filepath = "/tmp/#{filename}"
            timeProton = JSON.parse(CommonsUtils::editTextUsingTextmate(JSON.pretty_generate(timeProton)))
            timeProtonFilepath = TimeProtonUtils::getTimeProtonFilepathFromItsUUIDOrNull(timeProton["uuid"])
            TimeProtonUtils::commitTimeProtonToDisk(timeProton, File.basename(timeProtonFilepath))
        end
        if command=='destroy'
            loop {
                break if timeProton["target"]
                puts "This timeProton has a list target, I need to destroy the list first"
                puts "Not implemented yet!"
                LucilleCore::pressEnterToContinue()
                return
                break
            }
            filepath = object["item-data"]["filepath"]
            FileUtils.rm(filepath)
        end
        if command=='list:'
            TimeProtonUtils::setInteractivelySelectedTargetForTimeProton(timeProton["uuid"])
        end
    end
end
