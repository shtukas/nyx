#!/usr/bin/ruby

# encoding: UTF-8

require_relative "TimeCommitments.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

# -------------------------------------------------------------------------------------

# GuardianTime::getCatalystObjects()

class GuardianTime
    def self.getCatalystObjects()
        if KeyValueStore::getOrNull(nil, "23ed1630-7c94-47b4-b50e-905a3e5f862a:#{Time.new.to_s[0,10]}").nil? and ![6,0].include?(Time.new.wday) and Time.new.hour>=10 then
            numberOfHours = LucilleCore::askQuestionAnswerAsString("Number of Guardian hours for today (empty default to 5): ")
            if numberOfHours.strip.size==0 then
                numberOfHours = "5"
            end
            numberOfHours = numberOfHours.to_f
            if numberOfHours>0 then
                item = {
                    "uuid"                => SecureRandom.hex(4),
                    "domain"              => "6596d75b-a2e0-4577-b537-a2d31b156e74",
                    "description"         => "Guardian",
                    "commitment-in-hours" => numberOfHours,
                    "timespans"           => [],
                    "last-start-unixtime" => 0
                }
                TimeCommitments::saveItem(item)
            end
            KeyValueStore::set(nil, "23ed1630-7c94-47b4-b50e-905a3e5f862a:#{Time.new.to_s[0,10]}","done")
        end
        [] 
    end
end
