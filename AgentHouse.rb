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
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"  => "House",
        "agent-uid"   => "f8a8b8e6-623f-4ce1-b6fe-3bc8b34f7a10",
        "get-objects" => lambda { AgentHouse::getObjects() },
        "object-command-processor" => lambda{ |object, command| AgentHouse::processObjectAndCommand(object, command) }
    }
)

# AgentHouse::getObjects()

class AgentHouse

    # AgentHouse::agentuuid()
    def self.agentuuid()
        "f8a8b8e6-623f-4ce1-b6fe-3bc8b34f7a10"
    end

    def self.shouldDoTask(task)
        return false if Time.new.hour < 6
        unixtime = KeyValueStore::getOrDefaultValue(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "7aec05d2-0156-404b-883a-4024348c1907:#{task}", "0").to_i
        periodInDays = task.split(";")[0].to_f 
        (Time.new.to_i-unixtime) > periodInDays*86400
    end

    def self.markTaskAsDone(task)
        KeyValueStore::set(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "7aec05d2-0156-404b-883a-4024348c1907:#{task}", Time.new.to_i)
    end

    def self.taskToCatalystObject(task)
        {
            "uuid"               => Digest::SHA1.hexdigest(task)[0,8],
            "agent-uid"          => self.agentuuid(),
            "metric"             => 0.950,
            "announce"           => "House: #{task}",
            "commands"           => ["done"],
            "default-expression" => "done",
            "is-running"         => false,
            ":task:"             => task
        }
    end

    def self.getObjects()
        return [] if KeyValueStore::getOrNull(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "6af0644d-175e-4af9-97fb-099f71b505f5:#{CommonsUtils::currentDay()}")
        tasksFilepath = "/Galaxy/DataBank/Catalyst/Agents-Data/House/tasks.txt"
        tasks = IO.read(tasksFilepath)
            .lines
            .map{|line| line.strip }
            .select{|line| line.size>0 }
            .select{|line| !line.start_with?("#") }
        tasks
            .select{|task| AgentHouse::shouldDoTask(task) }
            .map{|task| AgentHouse::taskToCatalystObject(task) }
    end

    def self.processObjectAndCommand(object, command)
        if command == "done" then
            AgentHouse::markTaskAsDone(object[":task:"])
            return ["remove", object["uuid"]]
        end
        ["nothing"]
    end
end