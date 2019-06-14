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

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# -------------------------------------------------------------------------------------

HOUSE_DATA_FOLDER = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/House/data"

class NSXData
    # To be decommissioned upon site.
    def self.getValueAsStringOrNull(datarootfolderpath, id)
        id = Digest::SHA1.hexdigest(id)
        pathfragment = "#{id[0,2]}/#{id[2,2]}"
        filepath = "#{datarootfolderpath}/#{pathfragment}/#{id}.data"
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end
    def self.getValueAsIntegerOrNull(datarootfolderpath, id)
        value = NSXData::getValueAsStringOrNull(datarootfolderpath, id)
        return nil if value.nil?
        value.to_i
    end
    def self.getValueAsIntegerOrDefaultValue(datarootfolderpath, id, defaultValue)
        value = NSXData::getValueAsIntegerOrNull(datarootfolderpath, id)
        return defaultValue if value.nil?
        value
    end
end

class NSXAgentHouse

    # NSXAgentHouse::agentuuid()
    def self.agentuuid()
        "f8a8b8e6-623f-4ce1-b6fe-3bc8b34f7a10"
    end

    # NSXAgentHouse::getValueAsIntegerOrDefaultValue(task)
    def self.getValueAsIntegerOrDefaultValue(task)
        value = KeyValueStore::getOrNull(HOUSE_DATA_FOLDER, "9970d93a-9715-45b1-b751-aba99bb2e84f:#{task}")
        return value.to_i if value
        NSXData::getValueAsIntegerOrDefaultValue(HOUSE_DATA_FOLDER, "7aec05d2-0156-404b-883a-4024348c1907:#{task}", 0)
    end

    # NSXAgentHouse::markTaskAsDone(task)
    def self.markTaskAsDone(task)
        KeyValueStore::set(HOUSE_DATA_FOLDER, "9970d93a-9715-45b1-b751-aba99bb2e84f:#{task}", Time.new.to_i)
    end

    def self.shouldDoTask(task)
        return false if Time.new.hour < 6
        unixtime = NSXAgentHouse::getValueAsIntegerOrDefaultValue(task)
        periodInDays = task.split(";")[0].to_f 
        (Time.new.to_i-unixtime) > periodInDays*86400
    end

    def self.taskToCatalystObject(task)
        uuid = Digest::SHA1.hexdigest(task)[0,8]
        {
            "uuid"               => uuid,
            "agentuid"           => self.agentuuid(),
            "metric"             => 0.7,
            "announce"           => "House: #{task}",
            "commands"           => ["done"],
            "defaultExpression"  => "done",
            ":task:"             => task
        }
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
        NSXAgentHouse::getTasks()
            .select{|task| NSXAgentHouse::shouldDoTask(task) }
            .map{|task| NSXAgentHouse::taskToCatalystObject(task) }
    end

    # NSXAgentHouse::getAllObjects()
    def self.getAllObjects()
        NSXAgentHouse::getTasks()
            .map{|task| NSXAgentHouse::taskToCatalystObject(task) }
    end

    def self.processObjectAndCommand(object, command)
        if command == "done" then
            NSXAgentHouse::markTaskAsDone(object[":task:"])
            ["remove", object["uuid"]]
        end
        [nil]
    end
end