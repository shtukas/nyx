#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require_relative "Agent-TimeCommitments.rb"
# -------------------------------------------------------------------------------------

# GuardianTime::flockGeneralUpgrade(flock)

class GuardianTime
    def self.agentuuid()
        "11fa1438-122e-4f2d-9778-64b55a11ddc2"
    end

    def self.interface()
        
    end

    def self.flockGeneralUpgrade(flock)
        if KeyValueStore::getOrNull(CATALYST_COMMON_XCACHE_REPOSITORY, "23ed1630-7c94-47b4-b50e-905a3e5f862a:#{Time.new.to_s[0,10]}").nil? and ![6,0].include?(Time.new.wday) and Time.new.hour>=8 then
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
            KeyValueStore::set(CATALYST_COMMON_XCACHE_REPOSITORY, "23ed1630-7c94-47b4-b50e-905a3e5f862a:#{Time.new.to_s[0,10]}","done")
        end
        return [flock, []] # We do not return anything else. The side effect is the creation of the TimeCommitment Items
    end

    def self.upgradeFlockUsingObjectAndCommand(flock, object, command)
        return [flock, []] # Nothing to do, this agent doesn't create objects that it handles itself.
    end
end