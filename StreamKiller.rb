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

class StreamKiller
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

        targetuuid = Stream::getUUIDs().sample
        objects = []
        objects << {
            "uuid" => "2662371C-44C0-422B-83FF-FAB12B76FDED",
            "metric" => metric,
            "announce" => "(#{"%.3f" % metric}) -> stream killer (ideal: #{idealCount}, ideal-1%: #{idealCount*0.99}, current: #{currentCount}) target uuid: #{targetuuid}",
            "commands" => [],
            "command-interpreter" => lambda{|object, command| 
                targetuuid = object["target-uuid"]
                searchobjects = CatalystObjects::all()
                    .select{|object| object['announce'].downcase.include?(targetuuid) }
                if searchobjects.size>0 then
                    searchobject = searchobjects.first
                    Jupiter::putsObjectWithShellDisplay(searchobject, [])
                end
                [nil, false]

            },
            "target-uuid" => targetuuid
        }
        objects
    end
end

