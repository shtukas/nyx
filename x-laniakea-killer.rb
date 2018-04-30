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

require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"
=begin
    # The set of values that we support is whatever that can be json serialisable.
    FIFOQueue::size(repositorylocation or nil, queueuuid)
    FIFOQueue::values(repositorylocation or nil, queueuuid)
    FIFOQueue::push(repositorylocation or nil, queueuuid, value)
    FIFOQueue::getFirstOrNull(repositorylocation or nil, queueuuid)
    FIFOQueue::takeFirstOrNull(repositorylocation or nil, queueuuid)
=end

# -------------------------------------------------------------------------------------

# XLaniakeaKiller::getCatalystObjects()

class XLaniakeaKiller
    def self.getCurve()
        filename = Dir.entries("/Galaxy/DataBank/Catalyst/XLaniakeaKiller")
            .select{|filename| filename[0,1] != "." }
            .sort
            .last
        JSON.parse(IO.read("/Galaxy/DataBank/Catalyst/XLaniakeaKiller/#{filename}"))
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
        curve = XLaniakeaKiller::getCurve()
        idealCount = XLaniakeaKiller::computeIdealCountFromCurve(curve)
        currentCount = FIFOQueue::size(nil, "2477F469-6A18-4CAF-838A-E05703585A28")
        metric = XLaniakeaKiller::computeMetric(currentCount, idealCount)
        if metric < 0.2 then
            curveX = XLaniakeaKiller::shiftCurve(curve)
            idealCountX  = XLaniakeaKiller::computeIdealCountFromCurve(curveX)
            metricX = XLaniakeaKiller::computeMetric(currentCount, idealCountX)
            if metricX < 0.2 then
                puts "XLaniakeaKiller, shifting curve on disk (metric: #{metric} -> #{metricX})"
                puts JSON.pretty_generate(curve)
                puts JSON.pretty_generate(curveX)
                LucilleCore::pressEnterToContinue()
                File.open("/Galaxy/DataBank/Catalyst/XLaniakeaKiller/curve-#{LucilleCore::timeStringL22()}.json", "w"){|f| f.puts( JSON.pretty_generate(curveX) ) }
                curve = curveX
            end
        end
        objects = []
        objects << {
            "uuid" => "A3B08A86",
            "metric" => metric,
            "announce" => "-> x-laniakea killer (ideal: #{idealCount}, ideal-1%: #{idealCount*0.99}, current: #{currentCount})",
            "commands" => [],
            "command-interpreter" => lambda{|object, command| 
                targetuuid = FIFOQueue::getFirstOrNull(nil, "2477F469-6A18-4CAF-838A-E05703585A28")["uuid"]
                targetobjects = CatalystObjects::all()
                    .select{|object| object["uuid"]==targetuuid }
                if targetobjects.size>0 then
                    targetobject = targetobjects.first
                    Jupiter::interactiveDisplayObjectAndProcessCommand(targetobject)
                end
            }
        }
        objects
    end
end

