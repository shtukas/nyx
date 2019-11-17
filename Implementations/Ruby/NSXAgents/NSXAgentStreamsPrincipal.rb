#!/usr/bin/ruby

# encoding: UTF-8
require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

class NSXAgentStreamsPrincipal

    # NSXAgentStreamsPrincipal::agentuid()
    def self.agentuid()
        "b3e8dccb-77fc-4e13-a895-2d0608bd6abf"
    end

    # NSXAgentStreamsPrincipal::getObjects()
    def self.getObjects()
        NSXAgentStreamsPrincipal::getAllObjects()
    end

    # NSXAgentStreamsPrincipal::getAllObjects()
    def self.getAllObjects()
        NSXStreamsUtils::streamPrincipals()
            .reject{|streamprincipal| streamprincipal["streamuuid"] == "03b79978bcf7a712953c5543a9df9047" }
            .map{|streamprincipal| NSXStreamsUtils::streamPrincipalToCatalystObject(streamprincipal) }
    end

    # NSXAgentStreamsPrincipal::getObjectByUUIDOrNull(objectuuid)
    def self.getObjectByUUIDOrNull(objectuuid)
        NSXAgentStreamsPrincipal::getAllObjects()
            .select{|object| object["uuid"] == objectuuid }
            .first
    end

    # NSXAgentStreamsPrincipal::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)
        object = NSXAgentStreamsPrincipal::getObjectByUUIDOrNull(objectuuid)
        return if object.nil?
        if command == "open" then
            streamPrincipal = object["metadata"]["streamPrincipal"]
            if streamPrincipal["atlas-reference"] then
                filepath = NSXAtlasReferenceUtils::referenceToLocationOrNull(streamPrincipal["atlas-reference"])
                if filepath then
                    system("open '#{filepath}'")
                    LucilleCore::pressEnterToContinue()
                else
                    puts "-> Could not determine atlas-reference file for '#{streamPrincipal["description"]}'"
                    LucilleCore::pressEnterToContinue()
                end
            else
                puts "-> #{streamPrincipal["description"]} has not content"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if command == "time:" then
            streamuuid = object["metadata"]["streamuuid"]
            timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
            timespanInSeconds = timeInHours*3600
            NSXRunTimes::addPoint(streamuuid, Time.new.to_i, timespanInSeconds)
            return
        end
        if command == "start" then
            return if NSXRunner::isRunning?(objectuuid)
            NSXRunner::start(objectuuid)
            return
        end
        if command == "stop" then
            return if !NSXRunner::isRunning?(objectuuid)
            timespanInSeconds = NSXRunner::stop(objectuuid)
            streamuuid = object["metadata"]["streamuuid"]
            NSXRunTimes::addPoint(streamuuid, Time.new.to_i, timespanInSeconds)
            NSXEventsLog::issueEvent(NSXMiscUtils::instanceName(), "NSXRunTimes/addPoint",
                {
                    "collectionuid" => streamuuid,
                    "unixtime" => Time.new.to_i,
                    "algebraicTimespanInSeconds" => timespanInSeconds
                }
            )
            return
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentStreamsPrincipal",
            "agentuid"    => NSXAgentStreamsPrincipal::agentuid(),
        }
    )
rescue
end
