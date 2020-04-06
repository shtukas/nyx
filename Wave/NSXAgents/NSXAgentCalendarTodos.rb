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

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/Todo.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Starburst/Starburst.rb"

# -------------------------------------------------------------------------------------

class LucilleMetric
    def initialize()
        @counter = 0
    end
    def metric()
        @counter = @counter + 1
        0.75 - @counter.to_f/1000
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

    # NSXAgentCalendarTodos::sectionToCommandsAndDefaultCommand(section)
    def self.sectionToCommandsAndDefaultCommand(section)
        if section.lines.to_a.size == 1 then
            [ ["done", ">todo", ">starburst"], "done" ]
        else
            [ ["[]", ">todo", ">starburst"], "[]"]
        end
    end

    # NSXAgentCalendarTodos::getAllObjects()
    def self.getAllObjects()
        pair = NSXLucilleCalendarFileUtils::getUniqueStruct3FilepathPair()
        struct3 = pair["struct3"]
        pattern = struct3["pattern"]
        metric = LucilleMetric.new()
        todos = struct3["todo"]
        todos.map{|section|
            commanding = NSXAgentCalendarTodos::sectionToCommandsAndDefaultCommand(section)
            possiblyLineReturn = ( section.lines.to_a.size == 1 ) ? "" : "\n"
            {
                "uuid"           => NSXLucilleCalendarFileUtils::sectionToUUID(section),
                "agentuid"       => NSXAgentCalendarTodos::agentuid(),
                "contentItem"    => {
                    "type" => "line-and-body",
                    "line" => "cal todo: " + section.lines.to_a.first.strip,
                    "body" => "cal todo: #{possiblyLineReturn}" + section.strip
                },
                "metric"         => metric.metric(),
                "commands"       => commanding[0],
                "defaultCommand" => commanding[1],
                "isDone"         => nil,
                "sectionuuid"    => NSXLucilleCalendarFileUtils::sectionToUUID(section),
                "section"        => section
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
        if command == ">todo" then
            object = NSXAgentCalendarTodos::getObjectByUUIDOrNull(objectuuid)
            return if object.nil?
            text = object["section"]
            puts "text:"
            text.lines.each{|line|
                puts "    " + line
            }
            if LucilleCore::askQuestionAnswerAsBoolean("Edit text? ", false) then
                text = NSXMiscUtils::editTextUsingTextmate(text)
            end
            File.open("#{Todo::pathToTodoInbox()}/#{NSXMiscUtils::timeStringL22()}.text.txt", "w"){|f| f.puts(text) }
            sectionuuid = object["sectionuuid"]
            NSXLucilleCalendarFileUtils::removeSectionIdentifiedBySectionUUID(sectionuuid)
            return
        end
        if command == ">starburst" then
            object = NSXAgentCalendarTodos::getObjectByUUIDOrNull(objectuuid)
            return if object.nil?
            starburstFoldername = Starburst::selectExistingStarburstNameOrMakeANewOneReturnName()
            text = object["section"]
            nextIndex = Starburst::maxIndexAtStarburstName(starburstFoldername) + 1
            starburstFolderpath = Starburst::starburstNameToFolderpath(starburstFoldername)
            File.open("#{starburstFolderpath}/#{nextIndex}.txt", "w"){|f| f.puts(text) }
            sectionuuid = object["sectionuuid"]
            NSXLucilleCalendarFileUtils::removeSectionIdentifiedBySectionUUID(sectionuuid)
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
