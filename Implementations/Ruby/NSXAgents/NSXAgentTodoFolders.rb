#!/usr/bin/ruby

# encoding: UTF-8
require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

class NSXAgentTodoFolders

    # NSXAgentTodoFolders::agentuid()
    def self.agentuid()
        "09cc9943-1fa0-45a4-8d22-a37e0c4ddf0c"
    end

    # NSXAgentTodoFolders::getObjects()
    def self.getObjects()
        NSXTodoFolders::catalystObjectsForListing()
    end

    # NSXAgentTodoFolders::getAllObjects()
    def self.getAllObjects()
        NSXTodoFolders::catalystObjects()
    end

    # NSXAgentTodoFolders::stop(objectuuid)
    def self.stop(objectuuid)
        return if !NSXRunner::isRunning?(objectuuid)
        timespan = NSXRunner::stop(objectuuid)
        object = NSXTodoFolders::getObjectByUUIDOrNull(objectuuid)
        return if object.nil?
        NSXRunTimes::addPoint(object["x-folderuuid"], Time.new.to_i, timespan)
    end

    # NSXAgentTodoFolders::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)
        if command == "start" then
            return if NSXRunner::isRunning?(objectuuid)
            NSXRunner::start(objectuuid)
            return
        end
        if command == "[]" then
            puts "TODO: implement `[]`"
            LucilleCore::pressEnterToContinue()
            return
        end
        if command == "open" then
            object = NSXTodoFolders::getObjectByUUIDOrNull(objectuuid)
            return if object.nil?
            filepath = "/Users/pascal/Galaxy/Todo/#{object["x-typeProfile"]["foldername"]}/#{object["x-typeProfile"]["itemname"]}"
            system("open '#{filepath}'")
            return
        end
        if command == "stop" then
            NSXAgentTodoFolders::stop(objectuuid)
            return
        end
        if command == "destroy" then
            NSXAgentTodoFolders::stop(objectuuid)
            object = NSXTodoFolders::getObjectByUUIDOrNull(objectuuid)
            return if object.nil?
            foldername = object["x-typeProfile"]["foldername"]
            filepath = "/Users/pascal/Galaxy/Todo/#{foldername}/#{object["x-typeProfile"]["itemname"]}"
            if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to remove '#{filepath}' ? ") then
                NSXMiscUtils::copyLocationToCatalystBin(filepath)
                LucilleCore::removeFileSystemLocation(filepath)
                NSXTodoFolders::increaseFolderOrdinalBase(foldername)
            end
            return
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentTodoFolders",
            "agentuid"    => NSXAgentTodoFolders::agentuid(),
        }
    )
rescue
end
