#!/usr/bin/ruby

# encoding: UTF-8

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "time"

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

# -------------------------------------------------------------------------------------

class LucilleMetric
    def initialize()
        @counter = 0
    end
    def metric()
        @counter = @counter + 1
        0.70 - @counter.to_f/1000
    end
end

class NSXAgentCalendarTodos

    # NSXAgentCalendarTodos::agentuid()
    def self.agentuid()
        "853908e3-fe0e-47ac-bb8f-4421a6e7da96"
    end

    # NSXAgentCalendarTodos::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        NSXAgentCalendarTodos::getAllObjects()
            .select{|object| object["uuid"] == uuid }
            .first
    end

    # NSXAgentCalendarTodos::getObjects()
    def self.getObjects()
        NSXAgentCalendarTodos::getAllObjects()
    end

    # NSXAgentCalendarTodos::getAllObjects()
    def self.getAllObjects()
        pair = NSXLucilleCalendarFileUtils::getUniqueStruct3FilepathPair()
        $LUCILLE_CALENDAR_FILEPATH_44AF92E9 = pair["filepath"]
        struct3 = pair["struct3"]
        pattern = struct3["pattern"]
        metric = LucilleMetric.new()
        todos = struct3["todo"]
        todos.map{|section|
            {
                "uuid"           => NSXLucilleCalendarFileUtils::sectionToUUID(section),
                "agentuid"       => NSXAgentCalendarTodos::agentuid(),
                "contentItem"    => {
                    "type" => "line-and-body",
                    "line" => "cal todo: " + section.lines.to_a.first.strip,
                    "body" => "cal todo: " + section.strip
                },
                "metric"         => metric.metric(),
                "commands"       => ["[]"],
                "defaultCommand" => "[]",
                "isDone"         => nil,
                "sectionuuid"    => NSXLucilleCalendarFileUtils::sectionToUUID(section)
            }
        }
    end

    # NSXAgentCalendarTodos::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)
        if command == "done" then
            object = NSXAgentCalendarTodos::getObjectByUUIDOrNull(objectuuid)
            return if object.nil?
            sectionuuid = object["sectionuuid"]
            NSXLucilleCalendarFileUtils::removeSectionIdentifiedBySectionUUID(sectionuuid)
            return
        end
        if command == "[]" then
            object = NSXAgentCalendarTodos::getObjectByUUIDOrNull(objectuuid)
            return if object.nil?
            sectionuuid = object["sectionuuid"]
            NSXLucilleCalendarFileUtils::applyNextTransformationToSectionIdentifiedBySectionUUID(sectionuuid)
            return
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentCalendarTodos",
            "agentuid"    => NSXAgentCalendarTodos::agentuid(),
        }
    )
rescue
end
