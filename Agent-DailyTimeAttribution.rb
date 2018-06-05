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

# DailyTimeAttribution::generalUpgradeFromFlockServer()

class DailyTimeAttribution
    def self.agentuuid()
        "11fa1438-122e-4f2d-9778-64b55a11ddc2"
    end

    def self.interfaceFromCli()
        
    end

    def self.generalUpgradeFromFlockServer()

        if DRbObject.new(nil, "druby://:18171").fKVStore_getOrNull("16b84bf4-a032-44f7-a190-85476ca27ccd:#{Time.new.to_s[0,10]}").nil? and Time.new.hour>=6 then
            distribution = {}
            CollectionsOperator::collectionsUUIDs().each{|collectionuuid|
                distribution[collectionuuid] = {
                    "collectionuuid" => collectionuuid,
                    "collectionname" => CollectionsOperator::collectionUUID2NameOrNull(collectionuuid),
                    "time-commitment-in-hours" => 0,
                    "is-Guardian-time" => false
                }
            }
            puts "Daily Time Attribution: Time in hours, and yes/no for Guardian Time"
            distribution.each{|collectionuuid, collectiondata|
                collectiondata["time-commitment-in-hours"] = LucilleCore::askQuestionAnswerAsString("Today's hours for #{collectiondata["collectionname"]}: ").to_f
                if collectiondata["time-commitment-in-hours"] > 0 then
                    collectiondata["is-Guardian-time"] = LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("    Is Guardian time? ")
                end
            }
            loop {
                puts "Summary:"
                distribution.each{|collectionuuid, collectiondata|
                    next if collectiondata["time-commitment-in-hours"] == 0
                    puts "   - #{collectiondata["collectionname"]} : #{collectiondata["time-commitment-in-hours"]}"
                }
                puts "    Total: #{distribution.keys.map{|collectionuuid| distribution[collectionuuid]["time-commitment-in-hours"] }.inject(0, :+)} hours"
                if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to update the times? ") then
                    puts "Not implemented yet"
                    LucilleCore::pressEnterToContinue()
                    #next
                end
                break
            }
            distribution.each{|collectionuuid, collectiondata|
                next if collectiondata["time-commitment-in-hours"] == 0
                item = {
                    "uuid"                => SecureRandom.hex(4),
                    "domain"              => "0b91cb59-6a25-40e2-87eb-abb65af078c0:#{collectionuuid}",
                    "description"         => "Time commitment point for: #{collectiondata["collectionname"]}",
                    "commitment-in-hours" => collectiondata["time-commitment-in-hours"],
                    "timespans"           => [],
                    "last-start-unixtime" => 0
                }
                puts JSON.pretty_generate(collectiondata)
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                TimeCommitments::saveItem(item)
                if collectiondata["is-Guardian-time"] then
                    item = {
                        "uuid"                => SecureRandom.hex(4),
                        "domain"              => "6596d75b-a2e0-4577-b537-a2d31b156e74",
                        "description"         => "Guardian",
                        "commitment-in-hours" => -collectiondata["time-commitment-in-hours"],
                        "timespans"           => [],
                        "last-start-unixtime" => 0
                    }
                    puts JSON.pretty_generate(item)
                    LucilleCore::pressEnterToContinue()
                    TimeCommitments::saveItem(item)
                end
            }
            FKVStore::set("16b84bf4-a032-44f7-a190-85476ca27ccd:#{Time.new.to_s[0,10]}", "done")
        end

        if FKVStore::getOrNull("23ed1630-7c94-47b4-b50e-905a3e5f862a:#{Time.new.to_s[0,10]}").nil? and ![6,0].include?(Time.new.wday) and Time.new.hour>=8 then
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
            FKVStore::set("23ed1630-7c94-47b4-b50e-905a3e5f862a:#{Time.new.to_s[0,10]}", "done")
        end
    end

    def self.processObjectAndCommandFromCli(object, command)

    end
end