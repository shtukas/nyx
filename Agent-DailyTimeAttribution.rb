#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require_relative "Agent-TimeCommitments.rb"
require_relative "Events.rb"
require_relative "MiniFIFOQ.rb"
# -------------------------------------------------------------------------------------

# DailyTimeAttribution::generalFlockUpgrade()

class DailyTimeAttribution
    def self.agentuuid()
        "11fa1438-122e-4f2d-9778-64b55a11ddc2"
    end

    def self.interface()
        
    end

    def self.generalFlockUpgrade()
        FlockOperator::removeObjectsFromAgent(self.agentuuid())
        if FKVStore::getOrNull("16b84bf4-a032-44f7-a190-85476ca27ccd:#{Time.new.to_s[0,10]}").nil? and Time.new.hour>=6 then
            object =
                {
                    "uuid"      => "2ef32868",
                    "agent-uid" => self.agentuuid(),
                    "metric"    => 1,
                    "announce"  => "DailyTimeAttribution",
                    "commands"  => [],
                    "default-expression" => "16b84bf4-a032-44f7-a190-85476ca27ccd"
                }
            FlockOperator::addOrUpdateObject(object)
        end
        if FKVStore::getOrNull("23ed1630-7c94-47b4-b50e-905a3e5f862a:#{Time.new.to_s[0,10]}").nil? and ![6,0].include?(Time.new.wday) and Time.new.hour>=8 then
            object =
                {
                    "uuid"      => "2ef32868",
                    "agent-uid" => self.agentuuid(),
                    "metric"    => 1,
                    "announce"  => "DailyTimeAttribution",
                    "commands"  => [],
                    "default-expression" => "23ed1630-7c94-47b4-b50e-905a3e5f862a"
                }
            FlockOperator::addOrUpdateObject(object)
        end
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command == "16b84bf4-a032-44f7-a190-85476ca27ccd" then
            distribution = {}
            CollectionsOperator::collectionsUUIDs().each{|collectionuuid|
                distribution[collectionuuid] = {
                    "collectionuuid" => collectionuuid,
                    "style"          => CollectionsOperator::getCollectionStyle(collectionuuid),
                    "collectionname" => CollectionsOperator::collectionUUID2NameOrNull(collectionuuid),
                    "time-commitment-in-hours" => 0,
                    "is-Guardian-time" => false
                }
            }
            puts "Daily Time Attribution: Projects recommendations:"
            distribution.each{|collectionuuid, collectiondata|
                next if collectiondata["style"] != "PROJECT"
                puts "   - #{collectiondata["collectionname"]} : recommended: #{CollectionsOperator::getObjectTimeCommitmentInHours(collectionuuid)} hours"
            }
            puts "Daily Time Attribution: Projects pascal commitments:"
            distribution.each{|collectionuuid, collectiondata|
                next if collectiondata["style"] != "PROJECT"
                collectiondata["time-commitment-in-hours"] = LucilleCore::askQuestionAnswerAsString("  - #{collectiondata["collectionname"]} (hours): ").to_f
                if collectiondata["time-commitment-in-hours"] > 0 then
                    collectiondata["is-Guardian-time"] = CollectionsOperator::isGuardianTime?(collectionuuid)
                end
            }
            distribution.each{|collectionuuid, collectiondata|
                next if collectiondata["style"] != "PROJECT"
                next if collectiondata["time-commitment-in-hours"] == 0
                item = {
                    "uuid"                => SecureRandom.hex(4),
                    "domain"              => "0b91cb59-6a25-40e2-87eb-abb65af078c0:#{collectionuuid}",
                    "description"         => "Time commitment point for: #{collectiondata["collectionname"]}",
                    "commitment-in-hours" => collectiondata["time-commitment-in-hours"],
                    "timespans"           => [],
                    "last-start-unixtime" => 0,
                    "uuids-for-generic-time-tracking" => [collectionuuid, CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY], # the collection and the entire collection agent
                    "only-on-day"         => CommonsUtils::currentDay()
                }
                TimeCommitments::saveItem(item)
                if collectiondata["is-Guardian-time"] then
                    item = {
                        "uuid"                => SecureRandom.hex(4),
                        "domain"              => "6596d75b-a2e0-4577-b537-a2d31b156e74",
                        "description"         => "Guardian",
                        "commitment-in-hours" => -collectiondata["time-commitment-in-hours"],
                        "timespans"           => [],
                        "last-start-unixtime" => 0,
                        "only-on-day"         => CommonsUtils::currentDay()
                    }
                    TimeCommitments::saveItem(item)
                end
            }
            puts "Daily Time Attribution: Threads recommendations:"
            distribution.each{|collectionuuid, collectiondata|
                next if collectiondata["style"] != "THREAD"
                puts "   - #{collectiondata["collectionname"]}"
            }
            puts "Daily Time Attribution: Projects pascal commitments:"
            distribution.each{|collectionuuid, collectiondata|
                next if collectiondata["style"] != "THREAD"
                collectiondata["time-commitment-in-hours"] = LucilleCore::askQuestionAnswerAsString("  - #{collectiondata["collectionname"]} (hours): ").to_f
                if collectiondata["time-commitment-in-hours"] > 0 then
                    collectiondata["is-Guardian-time"] = CollectionsOperator::isGuardianTime?(collectionuuid)
                end
            }
            distribution.each{|collectionuuid, collectiondata|
                next if collectiondata["style"] != "THREAD"
                next if collectiondata["time-commitment-in-hours"] == 0
                item = {
                    "uuid"                => SecureRandom.hex(4),
                    "domain"              => "0b91cb59-6a25-40e2-87eb-abb65af078c0:#{collectionuuid}",
                    "description"         => "Time commitment point for: #{collectiondata["collectionname"]}",
                    "commitment-in-hours" => collectiondata["time-commitment-in-hours"],
                    "timespans"           => [],
                    "last-start-unixtime" => 0,
                    "uuids-for-generic-time-tracking" => [collectionuuid, CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY], # the collection and the entire collection agent
                    "only-on-day"         => CommonsUtils::currentDay()
                }
                TimeCommitments::saveItem(item)
                if collectiondata["is-Guardian-time"] then
                    item = {
                        "uuid"                => SecureRandom.hex(4),
                        "domain"              => "6596d75b-a2e0-4577-b537-a2d31b156e74",
                        "description"         => "Guardian",
                        "commitment-in-hours" => -collectiondata["time-commitment-in-hours"],
                        "timespans"           => [],
                        "last-start-unixtime" => 0,
                        "only-on-day"         => CommonsUtils::currentDay()
                    }
                    TimeCommitments::saveItem(item)
                end
            }
            FKVStore::set("16b84bf4-a032-44f7-a190-85476ca27ccd:#{Time.new.to_s[0,10]}", "done")
        end
        if command == "23ed1630-7c94-47b4-b50e-905a3e5f862a" then
            numberOfHours = LucilleCore::askQuestionAnswerAsString("Guardian hours for today (empty default to 5): ")
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
                    "last-start-unixtime" => 0,
                    "only-on-day"         => CommonsUtils::currentDay()
                }
                TimeCommitments::saveItem(item)
            end
            FKVStore::set("23ed1630-7c94-47b4-b50e-905a3e5f862a:#{Time.new.to_s[0,10]}", "done")
        end
    end
end