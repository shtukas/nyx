#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
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
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"  => "AgentTimeProton",
        "agent-uid"   => "201cac75-9ecc-4cac-8ca1-2643e962a6c6",
        "get-objects" => lambda { AgentTimeProton::getObjects() },
        "object-command-processor" => lambda{ |object, command| AgentTimeProton::processObjectAndCommand(object, command) }
    }
)

class AgentTimeProton
    def self.agentuuid()
        "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
    end

    def self.getObjects()
        TimeProtonUtils::timeProtonsWithFilepaths()
            .map{|pair|
                timeProton, filepath = pair
                TimeProtonUtils::makeCatalystObjectFromTimeProtonAndFilepath(timeProton, filepath)
            }
    end

    def self.processObjectAndCommand(object, command)
        uuid = object["uuid"]
        timeProton = object["item-data"]["timeProton"]
        filepath   = object["item-data"]["filepath"]
        if command=='start' then
            TimeProtonUtils::startTimeProton(uuid)
            return ["reload-agent-objects", self::agentuuid()]
        end
        if command=='stop' then
            TimeProtonUtils::stopTimeProton(uuid)
            return ["reload-agent-objects", self::agentuuid()]
        end
        if command=="time:" then
            timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
            TimeProtonUtils::timeProtonAddTime(timeProton["uuid"], timeInHours)
            return ["reload-agent-objects", self::agentuuid()]
        end
        if command=='dive' then
            TimeProtonUtils::timeProtonDive(timeProton)
            return ["reload-agent-objects", self::agentuuid()]
        end
        ["nothing"]
    end
end
