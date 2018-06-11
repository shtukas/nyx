#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require_relative "AgentsManager.rb"
require_relative "Agent-TimeCommitments.rb"
require_relative "Events.rb"
require_relative "MiniFIFOQ.rb"
# -------------------------------------------------------------------------------------

AgentsManager::registerAgent(
    {
        "agent-name"      => "DailyTimeAttribution",
        "agent-uid"       => "11fa1438-122e-4f2d-9778-64b55a11ddc2",
        "general-upgrade" => lambda { DailyTimeAttribution::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| DailyTimeAttribution::processObjectAndCommandFromCli(object, command) },
        "interface"       => lambda{ DailyTimeAttribution::interface() }
    }
)

# DailyTimeAttribution::generalFlockUpgrade()

class DailyTimeAttribution
    def self.agentuuid()
        "11fa1438-122e-4f2d-9778-64b55a11ddc2"
    end

    def self.interface()
        
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        if FKVStore::getOrNull("16b84bf4-a032-44f7-a191-85476ca27ccd:#{Time.new.to_s[0,10]}").nil? and Time.new.hour>=6 then
            object =
                {
                    "uuid"      => "2ef32868",
                    "agent-uid" => self.agentuuid(),
                    "metric"    => 1,
                    "announce"  => "Daily times attribution",
                    "commands"  => [],
                    "default-expression" => "16b84bf4-a032-44f7-a191-85476ca27ccd"
                }
            TheFlock::addOrUpdateObject(object)
        end
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command == "16b84bf4-a032-44f7-a191-85476ca27ccd" then

            guardianWorkingHours = LucilleCore::askQuestionAnswerAsString("Today's Guardian working hours (empty defaults to 5): ")
            if guardianWorkingHours.size==0 then
                guardianWorkingHours = "5"
            end
            guardianWorkingHours = guardianWorkingHours.to_f

            item = {
                "uuid"                => SecureRandom.hex(4),
                "domain"              => "6596d75b-a2e0-4577-b537-a2d31b156e74",
                "description"         => "Guardian (misc, non project)",
                "commitment-in-hours" => guardianWorkingHours,
                "timespans"           => [],
                "last-start-unixtime" => 0
            }
            TimeCommitments::saveItem(item)

            projectHours = LucilleCore::askQuestionAnswerAsString("Projects hours (empty defaults to 3): ")
            if projectHours.size==0 then
                projectHours = "3"
            end
            projectHours = projectHours.to_f 

            halvesEnum = CollectionsCore::projectsPositionalCoefficientSequence()
            CollectionsCore::collectionsFolderpaths() # Comes with the right order
                .select{|folderpath| IO.read("#{folderpath}/collection-style")=="PROJECT" }
                .each{|folderpath|
                    File.open("#{folderpath}/collection-time-positional-coefficient", "w"){|f| f.write(halvesEnum.next)}
                }

            CollectionsCore::collectionsUUIDs()
                .select{|collectionuuid| CollectionsCore::getCollectionStyle(collectionuuid)=="PROJECT" }
                .each{|collectionuuid| 
                timeCommitment = projectHours * CollectionsCore::getCollectionTimeCoefficient(collectionuuid) 
                    item = {
                        "uuid"                => SecureRandom.hex(4),
                        "domain"              => "2b3285ed-cbd4-4ccb-86c0-aba702e1a680:#{collectionuuid}",
                        "description"         => "Time commitment point for project #{ CollectionsCore::isGuardianTime?(collectionuuid) ? "(Guardian timed)" : "" }: #{CollectionsCore::collectionUUID2NameOrNull(collectionuuid)}",
                        "commitment-in-hours" => timeCommitment,
                        "timespans"           => [],
                        "last-start-unixtime" => 0,
                        "uuids-for-generic-time-tracking" => [collectionuuid, CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY], # the collection and the entire collection agent
                        "33be3505:collection-uuid" => collectionuuid
                    }
                    TimeCommitments::saveItem(item)
                    if  CollectionsCore::isGuardianTime?(collectionuuid) then
                        item = {
                            "uuid"                => SecureRandom.hex(4),
                            "domain"              => "6596d75b-a2e0-4577-b537-a2d31b156e74",
                            "description"         => "Guardian (misc, non project)",
                            "commitment-in-hours" => -timeCommitment,
                            "timespans"           => [],
                            "last-start-unixtime" => 0
                        }
                        TimeCommitments::saveItem(item)
                    end
                }

            threadsHours = LucilleCore::askQuestionAnswerAsString("Threads hours (empty defaults to 2): ")
            if threadsHours.size==0 then
                threadsHours = "2"
            end
            threadsHours = threadsHours.to_f 

            collectionuuids = CollectionsCore::collectionsUUIDs()
                .select{|collectionuuid| CollectionsCore::getCollectionStyle(collectionuuid)=="THREAD" }
            
            collectionuuids.each{|collectionuuid| 
                timeCommitment = threadsHours.to_f/collectionuuids.size # denominator greater than zero otherwise this would not be executed 
                    item = {
                        "uuid"                => SecureRandom.hex(4),
                        "domain"              => "2b3285ed-cbd4-4ccb-86c0-aba702e1a680:#{collectionuuid}",
                        "description"         => "Time commitment point for thread #{ CollectionsCore::isGuardianTime?(collectionuuid) ? "(Guardian timed)" : "" }: #{CollectionsCore::collectionUUID2NameOrNull(collectionuuid)}",
                        "commitment-in-hours" => timeCommitment,
                        "timespans"           => [],
                        "last-start-unixtime" => 0,
                        "uuids-for-generic-time-tracking" => [collectionuuid, CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY], # the collection and the entire collection agent
                        "33be3505:collection-uuid" => collectionuuid
                    }
                    TimeCommitments::saveItem(item)
                    if  CollectionsCore::isGuardianTime?(collectionuuid) then
                        item = {
                            "uuid"                => SecureRandom.hex(4),
                            "domain"              => "6596d75b-a2e0-4577-b537-a2d31b156e74",
                            "description"         => "Guardian (misc, non project)",
                            "commitment-in-hours" => -timeCommitment,
                            "timespans"           => [],
                            "last-start-unixtime" => 0
                        }
                        TimeCommitments::saveItem(item)
                    end
                }

            FKVStore::set("16b84bf4-a032-44f7-a191-85476ca27ccd:#{Time.new.to_s[0,10]}", "done")
        end
    end
end