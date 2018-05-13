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
require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
require 'colorize'
require "/Galaxy/local-resources/Ruby-Libraries/SetsOperator.rb"
require_relative "Commons.rb"
# -------------------------------------------------------------------------------------

GENERIC_TIME_COMMITMENTS_ITEMS_SETUUID = "64cba051-9761-4445-8cd5-8cf49c105ba1"
GENERIC_TIME_COMMITMENTS_ITEMS_REPOSITORY_PATH = "#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/time-commitments/items"

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
            "metric"              : Float # optional, if present determines the metric.
        }
=end

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
# TimeCommitments::getCatalystObjects()

class TimeCommitments

    def self.agentuuid()
        "03a8bff4-a2a4-4a2b-a36f-635714070d1d"
    end

    def self.processObject(object, command)
        uuid = object['uuid']
        if command=='start' then
            TimeCommitments::saveItem(TimeCommitments::startItem(TimeCommitments::getItemByUUID(uuid)))
            item = TimeCommitments::getItemByUUID(uuid)
            ratioDone = (TimeCommitments::itemToLiveTimespan(item).to_f/3600)/item["commitment-in-hours"]
            metric = 2 - Saturn::traceToMetricShift(uuid) if item["is-running"]
            object["announce"] = "time commitment: #{item['description']} (#{ "%.2f" % (100*ratioDone) } % of #{item["commitment-in-hours"]} hours done)"
            object["commands"] = ["stop"]
            object["default-expression"] = "stop"
            return object
        end
        if command=="stop" then
            TimeCommitments::saveItem(TimeCommitments::stopItem(TimeCommitments::getItemByUUID(uuid)))
            item = TimeCommitments::getItemByUUID(uuid)
            ratioDone = (TimeCommitments::itemToLiveTimespan(item).to_f/3600)/item["commitment-in-hours"]
            metric = 0.7 + 0.1*Math.exp(-ratioDone*3) + Saturn::traceToMetricShift(uuid)
            object["announce"] = "time commitment: #{item['description']} (#{ "%.2f" % (100*ratioDone) } % of #{item["commitment-in-hours"]} hours done)"
            object["commands"] = ["start"]
            object["default-expression"] = "start"
            return object
        end
        nil
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
        item["is-running"] = true
        item["last-start-unixtime"] = Time.new.to_i
        item
    end

    def self.stopItem(item)
        return item if !item["is-running"]
        item["is-running"] = false
        item["timespans"] << Time.new.to_i - item["last-start-unixtime"]
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

    def self.getCatalystObjects()
        TimeCommitments::garbageCollectionGlobal()
        objects = TimeCommitments::getItems()
        .map{|item|
            uuid = item['uuid']
            ratioDone = (TimeCommitments::itemToLiveTimespan(item).to_f/3600)/item["commitment-in-hours"]
            metric = item['metric'] ? item['metric'] : ( 0.7 + 0.1*Math.exp(-ratioDone*3) + Saturn::traceToMetricShift(uuid) )
            metric = 2 - Saturn::traceToMetricShift(uuid) if item["is-running"]
            announce = "time commitment: #{item['description']} (#{ "%.2f" % (100*ratioDone) } % of #{item["commitment-in-hours"]} hours done)"
            commands = item["is-running"] ? ["stop"] : ["start"]
            defaultExpression = item["is-running"] ? "stop" : "start"
            {
                "uuid" => uuid,
                "metric" => metric,
                "announce" => announce,
                "commands" => commands,
                "default-expression" => defaultExpression,
                "agent-uid" => self.agentuuid()
            }
        }
        if objects.select{|object| object["metric"]>1 }.size>0 then
            objects.select{|object| object["metric"]>1 }
        else
            objects
        end
    end
end