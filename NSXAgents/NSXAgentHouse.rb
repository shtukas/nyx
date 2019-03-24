#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

# -------------------------------------------------------------------------------------

HOUSE_DATA_FOLDER = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/House/data"

class NSXAgentHouse

    # NSXAgentHouse::agentuuid()
    def self.agentuuid()
        "f8a8b8e6-623f-4ce1-b6fe-3bc8b34f7a10"
    end

    def self.shouldDoTask(task)
        return false if Time.new.hour < 6
        unixtime = NSXData::getValueAsIntegerOrDefaultValue(HOUSE_DATA_FOLDER, "7aec05d2-0156-404b-883a-4024348c1907:#{task}", 0)
        periodInDays = task.split(";")[0].to_f 
        (Time.new.to_i-unixtime) > periodInDays*86400
    end

    def self.markTaskAsDone(task)
        NSXData::setWritableValue(HOUSE_DATA_FOLDER, "7aec05d2-0156-404b-883a-4024348c1907:#{task}", Time.new.to_i)
    end

    def self.taskToCatalystObject(task)
        uuid = Digest::SHA1.hexdigest(task)[0,8]
        {
            "uuid"               => uuid,
            "agentuid"           => self.agentuuid(),
            "prioritization"     => "high",
            "announce"           => "House: #{task}",
            "commands"           => ["done"],
            "defaultExpression"  => "done",
            ":task:"             => task
        }
    end

    # NSXAgentHouse::shouldDisplayObjects()
    def self.shouldDisplayObjects()
        NSXData::getValueAsStringOrDefaultValue(HOUSE_DATA_FOLDER, "efb5d391-71ff-447e-a670-728d8061e95a:#{NSXMiscUtils::currentDay()}", "true") == "true"
    end

    # NSXAgentHouse::getTasks()
    def self.getTasks()
        tasksFilepath = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/House/tasks.txt"
        IO.read(tasksFilepath)
            .lines
            .map{|line| line.strip }
            .select{|line| line.size>0 }
            .select{|line| !line.start_with?("#") }
    end

    # NSXAgentHouse::getObjects()
    def self.getObjects()
        return [] if !NSXMiscUtils::isLucille18()
        if !NSXAgentHouse::shouldDisplayObjects() then
            return []
        end
        NSXAgentHouse::getTasks()
            .select{|task| NSXAgentHouse::shouldDoTask(task) }
            .map{|task| NSXAgentHouse::taskToCatalystObject(task) }
    end

    def self.processObjectAndCommand(object, command)
        if command == "done" then
            NSXAgentHouse::markTaskAsDone(object[":task:"])
        end
    end

    # NSXAgentHouse::interface()
    def self.interface()
        puts "Welcome to House Interface"
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation:", ["show", "hide", "select for done"])
        if operation == "show" then
            NSXData::setWritableValue(HOUSE_DATA_FOLDER, "efb5d391-71ff-447e-a670-728d8061e95a:#{NSXMiscUtils::currentDay()}", "true")
        end
        if operation == "hide" then
            NSXData::setWritableValue(HOUSE_DATA_FOLDER, "efb5d391-71ff-447e-a670-728d8061e95a:#{NSXMiscUtils::currentDay()}", "false")
        end
        if operation == "select for done" then
            task = LucilleCore::selectEntityFromListOfEntitiesOrNull("task:", NSXAgentHouse::getTasks())
            return if task.nil?
            NSXAgentHouse::markTaskAsDone(task)
        end
    end

end