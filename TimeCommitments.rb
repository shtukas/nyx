#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require 'json'

=begin

  -- reading the string and building the object
     dataset = IO.read($dataset_location)
     JSON.parse(dataset)

  -- printing the string
     file.puts JSON.pretty_generate(dataset)

=end

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

require_relative "Commons.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require 'colorize'

require "/Galaxy/local-resources/Ruby-Libraries/SetsOperator.rb"
=begin
    # setuuids are used as namespace, therefore the same uuid in different sets are different values.
    SetsOperator::insert(repositorylocation or nil, setuuid, valueuuid, value)
    SetsOperator::getOrNull(repositorylocation or nil, setuuid, valueuuid)
    SetsOperator::delete(repositorylocation or nil, setuuid, valueuuid)
    SetsOperator::values(repositorylocation or nil, setuuid)
=end

# -------------------------------------------------------------------------------------

GENERIC_TIME_COMMITMENTS_ITEMS_SETUUID = "64cba051-9761-4445-8cd5-8cf49c105ba1"
GENERIC_TIME_COMMITMENTS_ITEMS_REPOSITORY_PATH = "/Galaxy/DataBank/Catalyst/time-commitments/items"

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
# TimeCommitments::extractNonRunningOverflowingItemOrNull(items)
# TimeCommitments::extractDifferentItemOrNull(items, item)
# TimeCommitments::itemToLiveTimespan(item)
# TimeCommitments::garbageCollectionItems(items)
# TimeCommitments::garbageCollectionGlobal()
# TimeCommitments::getUniqueDomains(items)
# TimeCommitments::getCatalystObjects()

class TimeCommitments

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

    def self.extractNonRunningOverflowingItemOrNull(items)
        items
            .select{|item| !item["is-running"] }
            .select{|item| item["timespans"].inject(0,:+) >= item["commitment-in-hours"]*3600  }
            .first
    end

    def self.extractDifferentItemOrNull(items, item)
        items.select{|i| i["uuid"]!=item["uuid"] }.first
    end

    def self.itemToLiveTimespan(item) 
        item["timespans"].inject(0,:+) + ( item["is-running"] ? Time.new.to_i - item["last-start-unixtime"] : 0 )
    end

    def self.garbageCollectionItems(items)
        if ( overflowingItem = TimeCommitments::extractNonRunningOverflowingItemOrNull(items) ) then
            if ( recipientItem = TimeCommitments::extractDifferentItemOrNull(items, overflowingItem) ) then
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
        TimeCommitments::getItems()
        .map{|item|
            uuid = item['uuid']
            ratioDone = (TimeCommitments::itemToLiveTimespan(item).to_f/3600)/item["commitment-in-hours"]
            metric = item["is-running"] ? 2 : ( item['metric'] ? item['metric'] : ( 0.810 + Math.exp(ratioDone).to_f/1000 ) )
            announce = "[#{uuid}] time commitment: #{item['description']} (#{ "%.2f" % (100*ratioDone) } % of #{item["commitment-in-hours"]} hours done)"
            announce = item["is-running"] ? announce.green : announce
            commands = item["is-running"] ? ["stop"] : ["start"]
            defaultcommands = item["is-running"] ? ["stop"] : ["start"]
            {
                "uuid" => uuid,
                "metric" => metric,
                "announce" => announce,
                "commands" => commands,
                "command-interpreter" => lambda{|object, command|
                    uuid = object['uuid']
                    if command=='start' then
                        item = TimeCommitments::getItemByUUID(uuid)
                        item = TimeCommitments::startItem(item)
                        TimeCommitments::saveItem(item)
                    end
                    if command=="stop" then
                        item = TimeCommitments::getItemByUUID(uuid)
                        item = TimeCommitments::stopItem(item)
                        TimeCommitments::saveItem(item)
                    end
                }
            }
        }
    end
end

