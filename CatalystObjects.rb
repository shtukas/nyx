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

require_relative "Wave.rb"
require_relative "Ninja.rb"
require_relative "Stream.rb"
require_relative "Today.rb"
require_relative "TimeCommitments.rb"
require_relative "SecondaryDisplayTeaser.rb"

# ----------------------------------------------------------------------

class CatalystCore
    # CatalystCore::objects()
    def self.objects()

        timings = {}

        start = Time.new.to_f
        o1 = WaveInterface::getCatalystObjects()
        timings["Wave"] = {
            "time" => Time.new.to_f - start,
            "count" => o1.count
        }

        start = Time.new.to_f
        o4 = Ninja::getCatalystObjects()
        timings["Ninja"] = {
            "time" => Time.new.to_f - start,
            "count" => o4.count
        }

        start = Time.new.to_f
        o5 = Stream::getCatalystObjects()
        timings["Stream"] = {
            "time" => Time.new.to_f - start,
            "count" => o5.count
        }

        start = Time.new.to_f
        o6 = Today::getCatalystObjects()
        timings["Today"] = {
            "time" => Time.new.to_f - start,
            "count" => o6.count
        }

        start = Time.new.to_f
        o7 = TimeCommitments::getCatalystObjects()
        timings["TimeCommitments"] = {
            "time" => Time.new.to_f - start,
            "count" => o7.count
        }        

        start = Time.new.to_f
        o8 = SecondaryDisplayTeaser::getCatalystObjects()
        timings["SecondaryDisplayTeaser"] = {
            "time" => Time.new.to_f - start,
            "count" => o8.count
        } 

        objects = o1+o4+o5+o6+o7+o8

        objects << {
            "uuid"                => "d341644d",
            "metric"              => 0.2,
            "announce"            => "-- sleep time ---------------------------------------------------",
            "commands"            => [],
            "command-interpreter" => lambda{ |command, object| }
        }

        if timings.map{|key, value| value["time"] }.inject(0,:+) > 1 then
            objects << {
                "uuid"                => "5E2B7E8",
                "metric"              => 1,
                "announce"            => "Catalyst generation is taking too long\n#{JSON.pretty_generate(timings)}",
                "commands"            => [],
                "command-interpreter" => lambda{ |command, object| }
            }
        end

        (objects)
            .sort{|o1,o2| o1['metric']<=>o2['metric'] }
            .reverse
    end
end

