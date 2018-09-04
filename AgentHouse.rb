#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "House",
        "agent-uid"       => "f8a8b8e6-623f-4ce1-b6fe-3bc8b34f7a10",
        "general-upgrade" => lambda { AgentHouse::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentHouse::processObjectAndCommand(object, command) }
    }
)

# AgentHouse::generalFlockUpgrade()

class AgentHouse
    def self.agentuuid()
        "f8a8b8e6-623f-4ce1-b6fe-3bc8b34f7a10"
    end

    def self.shouldDoTask(task)
        unixtime = FKVStore::getOrDefaultValue("7aec05d2-0156-404b-883a-4024348c1907:#{task}", "0").to_i
        periodInDays = task.split(";")[0].to_f 
        (Time.new.to_i-unixtime) > periodInDays*86400
    end

    def self.markTaskAsDone(task)
        FKVStore::set("7aec05d2-0156-404b-883a-4024348c1907:#{task}", Time.new.to_i)
    end

    def self.taskToCatalystObject(task)
        {
            "uuid"               => Digest::SHA1.hexdigest(task)[0,8],
            "agent-uid"          => self.agentuuid(),
            "metric"             => 1,
            "announce"           => "House: #{task}",
            "commands"           => ["done"],
            "default-expression" => "done",
            "is-running"         => false,
            ":task:"             => task
        }
    end

    def self.generalFlockUpgrade()
        tasksFilepath = "/Galaxy/DataBank/Catalyst/Agents-Data/House/tasks.txt"
        tasks = IO.read(tasksFilepath)
            .lines
            .map{|line| line.strip }
            .select{|line| line.size>0 }
            .select{|line| !line.start_with?("#") }

        TheFlock::removeObjectsFromAgent(self.agentuuid())

        objects = tasks
            .select{|task| AgentHouse::shouldDoTask(task) }
            .map{|task| AgentHouse::taskToCatalystObject(task) }

        TheFlock::addOrUpdateObjects(objects)

    end

    def self.processObjectAndCommand(object, command)
        if command == "done" then
            AgentHouse::markTaskAsDone(object[":task:"])
        end 
    end
end