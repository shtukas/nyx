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

require_relative "CatalystCommon.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require 'colorize'

# -------------------------------------------------------------------------------------

GENERIC_TIME_COMMITMENTS_PATH_TO_DATA_FILE = "/Galaxy/DataBank/Catalyst/time-commitments/data.json"

=begin
    Data
        file: Array[Item]
        Item {
            "uuid"                : String
            "description"         : String
            "commitment-in-hours" : Float
            "timespans"           : Array[Float]
            "is-running"          : Boolean
            "last-start-unixtime" : Int
            "metric"              : Float # optional, if present determines the metric.
        }
=end

# TimeCommitments::getDataFromDisk()
# TimeCommitments::writeDataToDisk(data)
# TimeCommitments::genericStart(item, uuid)
# TimeCommitments::genericDone(item, uuid)
# TimeCommitments::garbageCollectionAtomic1(item): (item, 0) or (nil, extraTimespan)
# TimeCommitments::itemToLiveTimespan(item)
# TimeCommitments::getCatalystObjects()

class TimeCommitments

    def self.getDataFromDisk()
        JSON.parse(IO.read(GENERIC_TIME_COMMITMENTS_PATH_TO_DATA_FILE))
    end

    def self.writeDataToDisk(data)
        File.open(GENERIC_TIME_COMMITMENTS_PATH_TO_DATA_FILE, "w"){|f|
            f.puts(JSON.pretty_generate(data))
        }
    end

    def self.genericStart(item, uuid)
        return item if item['uuid']!=uuid
        return item if item["is-running"]
        item["is-running"] = true
        item["last-start-unixtime"] = Time.new.to_i
        item
    end

    def self.genericDone(item, uuid)
        return item if item['uuid']!=uuid
        return item if !item["is-running"]
        item["is-running"] = false
        item["timespans"] << Time.new.to_i - item["last-start-unixtime"]
        item
    end

    def self.garbageCollectionAtomic1(item)
        return [item, 0] if item["is-running"]
        return [item, 0] if ( item["timespans"].inject(0,:+) < item["commitment-in-hours"]*3600 )
        [nil, item["timespans"].inject(0,:+) - item["commitment-in-hours"]*3600 ]
    end

    def self.itemToLiveTimespan(item) 
        item["timespans"].inject(0,:+) + ( item["is-running"] ? Time.new.to_i - item["last-start-unixtime"] : 0 )
    end

    def self.getCatalystObjects()

        gcresults = TimeCommitments::getDataFromDisk()
            .map{|item| TimeCommitments::garbageCollectionAtomic1(item) }
        data = gcresults.map{|pair| pair[0] }.compact
        extraTimespan = gcresults.map{|pair| pair[1] }.compact.inject(0, :+)
        if extraTimespan>0 and data.size>0 then
            increment = extraTimespan.to_f/data.size
            data = data.map{|item| 
                item["timespans"] << increment 
                item
            }
            TimeCommitments::writeDataToDisk(data)
        end

        TimeCommitments::getDataFromDisk()
        .map{|item|
            uuid = item['uuid']
            ratioDone = (TimeCommitments::itemToLiveTimespan(item).to_f/3600)/item["commitment-in-hours"]
            metric = item['metric'] ? item['metric'] : ( 0.810 + Math.exp(ratioDone).to_f/1000 )
            announce = "[#{uuid}] time commitment: #{item['description']} (#{ "%.2f" % (100*ratioDone) } % of #{item["commitment-in-hours"]} hours done)"
            announce = item["is-running"] ? announce.green : announce
            commands = item["is-running"] ? ["stop"] : ["start"]
            defaultcommands = item["is-running"] ? ["stop"] : ["start"]
            {
                "uuid" => uuid,
                "metric" => metric,
                "announce" => "(#{"%.3f" % metric}) #{announce}",
                "commands" => commands,
                "default-commands" => defaultcommands,
                "command-interpreter" => lambda{|object, command|
                    uuid = object['uuid']
                    if command=='start' then
                        data2 = TimeCommitments::getDataFromDisk()
                            .map{|item| TimeCommitments::genericStart(item, uuid) }
                        TimeCommitments::writeDataToDisk(data2)
                    end
                    if command=="stop" then
                        data2 = TimeCommitments::getDataFromDisk()
                            .map{|item| TimeCommitments::genericDone(item, uuid) }
                        TimeCommitments::writeDataToDisk(data2)
                    end
                }
            }
        }
    end
end

