#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'json'
require 'date'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'find'
require 'colorize'
require "/Galaxy/local-resources/Ruby-Libraries/SetsOperator.rb"
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require_relative "Constants.rb"
require_relative "Events.rb"
require_relative "MiniFIFOQ.rb"
require_relative "Config.rb"
require_relative "GenericTimeTracking.rb"
require_relative "CatalystDevOps.rb"
require_relative "CollectionsOperator.rb"
require_relative "NotGuardian"
require_relative "FolderProbe.rb"
require_relative "CommonsUtils"

# -------------------------------------------------------------------------------------

=begin
    Data
        file: Array[Item]
        Item {
            "uuid"                : String
            "domain"              : String # Two items of the same domain share their timespans
            "description"         : String
            "commitment-in-hours" : Float
            "timespans"           : Array[Float]
            "is-running"          : Boolean
            "last-start-unixtime" : Int

            "metric"                          : Float # optional, if present determines the metric.
            "uuids-for-generic-time-tracking" : Array[String] # optional
            "paused"                          : Boolean # Optional
        }
=end

# The secondary uuids are uuids to use for activity related events, start and stop.
# We use then for when the item is used as a proxy for something that actually itself 
# maintains activity at the GenericTimeTracking.

# -------------------------------------------------------------------------------------

GENERIC_TIME_COMMITMENTS_ITEMS_SETUUID = "64cba051-9761-4445-8cd5-8cf49c105ba1"
GENERIC_TIME_COMMITMENTS_ITEMS_REPOSITORY_PATH = "#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Agents-Data/time-commitments/items"

# -------------------------------------------------------------------------------------

# TimeCommitments::getItems()
# TimeCommitments::getItemByUUID(uuid)
# TimeCommitments::saveItem(item)
# TimeCommitments::writeDataToDisk(data)
# TimeCommitments::startItem(item)
# TimeCommitments::stopItem(item)
# TimeCommitments::getNonRunningOverflowingItemOrNull(items)
# TimeCommitments::getDifferentItemOrNull(item, items)
# TimeCommitments::getDifferentNonRunningUnderflowingOfSameDomainOfMaxMetricItemOrNull(items, domain)
# TimeCommitments::itemToLiveTimespan(item)
# TimeCommitments::garbageCollectionItems(items)
# TimeCommitments::garbageCollectionGlobal()
# TimeCommitments::getUniqueDomains(items)
# TimeCommitments::generalUpgradeFromFlockServer()
# TimeCommitments::processObjectAndCommandFromCli(object, command)

class TimeCommitments

    def self.agentuuid()
        "03a8bff4-a2a4-4a2b-a36f-635714070d1d"
    end

    def self.getItems()
        SetsOperator::values(GENERIC_TIME_COMMITMENTS_ITEMS_REPOSITORY_PATH, GENERIC_TIME_COMMITMENTS_ITEMS_SETUUID)
            .compact
    end

    def self.getItemByUUID(uuid)
        SetsOperator::getOrNull(GENERIC_TIME_COMMITMENTS_ITEMS_REPOSITORY_PATH, GENERIC_TIME_COMMITMENTS_ITEMS_SETUUID, uuid)
    end

    def self.saveItem(item)
        SetsOperator::insert(GENERIC_TIME_COMMITMENTS_ITEMS_REPOSITORY_PATH, GENERIC_TIME_COMMITMENTS_ITEMS_SETUUID, item["uuid"], item)
    end

    def self.writeDataToDisk(data)
        data.each{|item|
            SetsOperator::insert(GENERIC_TIME_COMMITMENTS_ITEMS_REPOSITORY_PATH, GENERIC_TIME_COMMITMENTS_ITEMS_SETUUID, item["uuid"], item)
        }
    end

    def self.startItem(item)
        return item if item["is-running"]
        item["paused"] = false
        item["is-running"] = true
        item["last-start-unixtime"] = Time.new.to_i
        if item["uuids-for-generic-time-tracking"] then
            item["uuids-for-generic-time-tracking"].each{|uuid|
                GenericTimeTracking::start(uuid)
            }
        end
        item
    end

    def self.stopItem(item)
        item["paused"] = false
        if item["is-running"] then
            item["is-running"] = false
            item["timespans"] << Time.new.to_i - item["last-start-unixtime"]
            if item["uuids-for-generic-time-tracking"] then
                item["uuids-for-generic-time-tracking"].each{|uuid|
                    GenericTimeTracking::stop(uuid)
                }
            end
        end
        item
    end

    def self.pauseItem(item)
        self.stopItem(item)
        item["paused"] = true
        item
    end

    def self.getNonRunningOverflowingItemOrNull(items)
        items
            .select{|item| !item["is-running"] }
            .select{|item| item["timespans"].inject(0,:+) >= item["commitment-in-hours"]*3600  }
            .first
    end

    def self.getDifferentItemOrNull(item, items)
        items.select{|i| i["uuid"]!=item["uuid"] }.first
    end

    def self.getNonRunningUnderflowingItemOfGivenDomainOfMaxMetricOrNull(items, domain)
        items
            .select{|i| !i["is-running"] }
            .select{|i| i["timespans"].inject(0,:+) < i["commitment-in-hours"]*3600  }
            .select{|i| i["domain"]==domain }
            .map{|i|
                i["metric-temp"] = i["metric"] ? i["metric"] : 0
                i
            }
            .sort{|i1, i2| i1["metric-temp"]<=>i2["metric-temp"] }
            .map{|i|
                i.delete("metric-temp")
                i
            }
            .reverse
            .first
    end

    def self.itemToLiveTimespan(item)
        item["timespans"].inject(0,:+) + ( item["is-running"] ? Time.new.to_i - item["last-start-unixtime"] : 0 )
    end

    def self.garbageCollectionItems(items)
        if items.size==1 then
            item = items.first
            if !item["is-running"] and (item["timespans"].inject(0,:+) >= item["commitment-in-hours"]*3600) then
                SetsOperator::delete(GENERIC_TIME_COMMITMENTS_ITEMS_REPOSITORY_PATH, GENERIC_TIME_COMMITMENTS_ITEMS_SETUUID, item["uuid"])
                return
            end
        end
        if ( overflowingItem = TimeCommitments::getNonRunningOverflowingItemOrNull(items) ) then
            if ( recipientItem = TimeCommitments::getDifferentItemOrNull(overflowingItem, items) ) then
                recipientItem["timespans"] << ( overflowingItem["timespans"].inject(0,:+) - overflowingItem["commitment-in-hours"]*3600 )
                TimeCommitments::saveItem(recipientItem)
                SetsOperator::delete(GENERIC_TIME_COMMITMENTS_ITEMS_REPOSITORY_PATH, GENERIC_TIME_COMMITMENTS_ITEMS_SETUUID, overflowingItem["uuid"])
            end
        end
    end

    def self.garbageCollectionGlobal()
        items = TimeCommitments::getItems()
        domains = TimeCommitments::getUniqueDomains(items)
        domains.each{|domain|
            domainItems = items.select{|item| item["domain"]==domain }
            TimeCommitments::garbageCollectionItems(domainItems)
        }
    end

    def self.getUniqueDomains(items)
        items.map{|item| item["domain"] }.uniq
    end

    def self.interfaceFromCli()
        puts "Welcome to TimeCommitments interface"
        if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to add a time commitment ? ") then
            item = {
                "uuid"                => SecureRandom.hex(4),
                "domain"              => SecureRandom.hex(8),
                "description"         => LucilleCore::askQuestionAnswerAsString("description: "),
                "commitment-in-hours" => LucilleCore::askQuestionAnswerAsString("hours: ").to_f,
                "timespans"           => [],
                "last-start-unixtime" => 0
            }
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            TimeCommitments::saveItem(item)
        end
    end

    def self.generalUpgradeFromFlockServer()
        TimeCommitments::garbageCollectionGlobal()
        FlockOperator::removeObjectsFromAgent(self.agentuuid())
        objects = TimeCommitments::getItems()
            .select{|item| item["commitment-in-hours"] > 0 }
            .map{|item|
                uuid = item['uuid']
                ratioDone = (TimeCommitments::itemToLiveTimespan(item).to_f/3600)/item["commitment-in-hours"]
                if ratioDone>1 then
                    message "#{item['description']} is done"
                    system("terminal-notifier -title Catalyst -message '#{message}'")
                    sleep 2
                end
                metric = 0.6 + 0.1*Math.exp(-ratioDone*3) + CommonsUtils::traceToMetricShift(uuid)
                metric = item['metric'] ? item['metric'] : metric
                metric = 2 - CommonsUtils::traceToMetricShift(uuid) if item["is-running"] or item["paused"]
                announce = "time commitment: #{item['description']} (#{ "%.2f" % (100*ratioDone) } % of #{item["commitment-in-hours"]} hours done)"
                if item["paused"] then
                    announce = "[PAUSED] #{announce}"
                end
                commands = item["is-running"] ? ["pause", "stop"] : ["start", "stop"]
                defaultExpression = item["is-running"] ? "stop" : "start"
                object  = {}
                object["uuid"]      = uuid
                object["agent-uid"] = self.agentuuid()
                object["metric"]    = metric
                object["announce"]  = announce
                object["commands"]  = commands
                object["default-expression"]     = defaultExpression
                object["metadata"]               = {}
                object["metadata"]["is-running"] = item["is-running"]
                object["metadata"]["time-commitment-item"] = item
                object
            }
        objects = 
            if objects.select{|object| object["metric"]>1 }.size>0 then
                objects.select{|object| object["metric"]>1 }
            else
                objects
            end
        FlockOperator::addOrUpdateObjects(objects)
    end

    def self.processObjectAndCommandFromCli(object, command)
        uuid = object['uuid']
        if command == "start" then
            TimeCommitments::saveItem(TimeCommitments::startItem(TimeCommitments::getItemByUUID(uuid)))
        end
        if command == "stop" then
            TimeCommitments::saveItem(TimeCommitments::stopItem(TimeCommitments::getItemByUUID(uuid)))
        end
        if command == "pause" then
            TimeCommitments::saveItem(TimeCommitments::pauseItem(TimeCommitments::getItemByUUID(uuid)))
        end
    end
end