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

require_relative "Stream.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    # The set of values that we support is whatever that can be json serialisable.
    FIFOQueue::size(repositorylocation or nil, queueuuid)
    FIFOQueue::values(repositorylocation or nil, queueuuid)
    FIFOQueue::push(repositorylocation or nil, queueuuid, value)
    FIFOQueue::getFirstOrNull(repositorylocation or nil, queueuuid)
    FIFOQueue::takeFirstOrNull(repositorylocation or nil, queueuuid)
=end

# -------------------------------------------------------------------------------------

# metric = f(idealCount*0.9) = 0
#          f(idealCount)     = 1
#          slope = 1.to_f/(0.1*idealCount)
#          f(x) = x.to_f/(0.1*idealCount) + something
#          something = f(x) - x.to_f/(0.1*idealCount)
#          something = - (idealCount*0.9).to_f/(0.1*idealCount)
#          f(x) = x.to_f/(0.1*idealCount) - (idealCount*0.9).to_f/(0.1*idealCount)
#          check: f(idealCount*0.9) = (idealCount*0.9).to_f/(0.1*idealCount) - (idealCount*0.9).to_f/(0.1*idealCount) = 0
#          check: f(idealCount)     = idealCount.to_f/(0.1*idealCount) - (idealCount*0.9).to_f/(0.1*idealCount)
#                                   = (idealCount*0.9 + idealCount*0.1).to_f/(0.1*idealCount) - (idealCount*0.9).to_f/(0.1*idealCount)
#                                   = 1

# StreamKiller::getCatalystObjects()
# StreamKiller::getTargetUUIDOrNull()
# StreamKiller::getObjectForTargetUUIDOrNull(targetuuid)

class StreamKiller
    def self.getTargetUUIDOrNull()
        targetuuid = FIFOQueue::getFirstOrNull(nil, "6e724d6b-8273-49cb-8115-c7de81125613")
        if targetuuid.nil? then
            Stream::getUUIDs().shuffle.each{|uuid|
                FIFOQueue::push(nil, "6e724d6b-8273-49cb-8115-c7de81125613", uuid)
            }
        end
        FIFOQueue::getFirstOrNull(nil, "6e724d6b-8273-49cb-8115-c7de81125613")
    end

    def self.getObjectForTargetUUIDOrNull(targetuuid)
        Stream::getCatalystObjects()
            .select{|object| object["uuid"]==targetuuid }
            .first
    end

    def self.getCurve()
        filename = Dir.entries("/Galaxy/DataBank/Catalyst/StreamKiller")
            .select{|filename| filename[0,1] != "." }
            .sort
            .last
        JSON.parse(IO.read("/Galaxy/DataBank/Catalyst/StreamKiller/#{filename}"))
    end

    def self.shiftCurve(curve)
        curve = curve.clone
        curve["starting-count"] = curve["starting-count"]-10
        curve["ending-unixtime"] = curve["ending-unixtime"]-86400
        curve
    end

    def self.computeIdealCountFromCurve(curve)
        curve["starting-count"] - curve["starting-count"]*(Time.new.to_i - curve["starting-unixtime"]).to_f/(curve["ending-unixtime"] - curve["starting-unixtime"])
    end

    def self.computeMetric(currentCount, idealCount)
        currentCount.to_f/(0.01*idealCount) - (idealCount*0.99).to_f/(0.01*idealCount)
    end

    def self.getCatalystObjects()
        curve = StreamKiller::getCurve()
        idealCount = StreamKiller::computeIdealCountFromCurve(curve)
        currentCount = Dir.entries("/Galaxy/DataBank/Catalyst/Stream/strm1").size
        metric = StreamKiller::computeMetric(currentCount, idealCount)
        if metric < 0.2 then
            curveX = StreamKiller::shiftCurve(curve)
            idealCountX  = StreamKiller::computeIdealCountFromCurve(curveX)
            metricX = StreamKiller::computeMetric(currentCount, idealCountX)
            if metricX < 0.2 then
                puts "StreamKiller, shifting curve on disk (metric: #{metric} -> #{metricX})"
                puts JSON.pretty_generate(curve)
                puts JSON.pretty_generate(curveX)
                LucilleCore::pressEnterToContinue()
                File.open("/Galaxy/DataBank/Catalyst/StreamKiller/curve-#{LucilleCore::timeStringL22()}.json", "w"){|f| f.puts( JSON.pretty_generate(curveX) ) }
                curve = curveX
            end
        end
        objects = []
        if (targetuuid = StreamKiller::getTargetUUIDOrNull()) then
            if (targetobject = StreamKiller::getObjectForTargetUUIDOrNull(targetuuid)) then
                objects << {
                    "uuid" => "2662371C",
                    "metric" => metric,
                    "announce" => "-> stream killer (ideal: #{idealCount}, ideal-1%: #{idealCount*0.99}, current: #{currentCount}) target uuid: #{targetuuid}",
                    "commands" => ["->object", "rotate"],
                    "default-expression" => "->object",
                    "command-interpreter" => lambda{|object, command| 
                        if command=="->object" then
                            targetuuid = object["target-uuid"]
                            if (targetobject = StreamKiller::getObjectForTargetUUIDOrNull(targetuuid)) then
                                Jupiter::interactiveDisplayObjectAndProcessCommand(targetobject)
                            else
                                puts "StreamKiller: weird case bd4e5c71-4469-425f-8c12-294ce9c75693"
                                LucilleCore::pressEnterToContinue() 
                            end
                        end
                        if command=="rotate" then
                            FIFOQueue::takeFirstOrNull(nil, "6e724d6b-8273-49cb-8115-c7de81125613")
                        end
                    },
                    "target-uuid" => targetuuid
                }
            else
                FIFOQueue::takeFirstOrNull(nil, "6e724d6b-8273-49cb-8115-c7de81125613") # discarding the targetuuid for which an object could not be found
                objects << {
                    "uuid" => "2662371C",
                    "metric" => metric,
                    "announce" => "-> stream killer could not retrieve a target object for targetuuid: #{targetuuid}",
                    "commands" => [],
                    "command-interpreter" => lambda{|object, command| }
                }
            end
        else
            objects << {
                "uuid" => "2662371C",
                "metric" => metric,
                "announce" => "-> stream killer could not retrieve a targetuuid",
                "commands" => [],
                "command-interpreter" => lambda{|object, command| }
            }
        end
        objects
    end
end

