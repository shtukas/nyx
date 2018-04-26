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
require_relative "StreamKiller.rb"
require_relative "GuardianTime.rb"
require_relative "x-laniakea.rb"

# ----------------------------------------------------------------------

class CatalystCore
    # CatalystCore::objects(size = nil)
    def self.objects(size = nil)

        sources = [
            ["Wave", lambda { WaveInterface::getCatalystObjects(size) }],
            ["Ninja", lambda { Ninja::getCatalystObjects(size) }],
            ["Stream", lambda { Stream::getCatalystObjects(size) }],
            ["Today", lambda { Today::getCatalystObjects(size) }],
            ["TimeCommitments", lambda { TimeCommitments::getCatalystObjects(size) }],
            ["StreamKiller", lambda { StreamKiller::getCatalystObjects(size) }],
            ["GuardianTime", lambda { GuardianTime::getCatalystObjects(size) }],
            ["x-laniakea", lambda { XLaniakea::getCatalystObjects(size) }]
        ]

        struct1 = sources.map{|pair|
            startTime = Time.new.to_f
            xobjects  = pair[1].call() 
            queryTime = Time.new.to_f - startTime
            {
                "domain"  => pair[0],
                "objects" => xobjects,
                "time"    => queryTime
            }
        }

        objects = struct1.map{|s| s["objects"] }.flatten

        if struct1.map{|s| s["time"] }.inject(0, :+) > 1 then
            offender = struct1.sort{|s1,s2| s1["time"]<=>s2["time"] }.last
            objects << {
                "uuid"                => SecureRandom.hex(4),
                "metric"              => 0.3,
                "announce"            => "-> Catalyst generation is taking too long for #{offender["domain"]} (#{offender["time"]} seconds)",
                "commands"            => [],
                "command-interpreter" => lambda{ |command, object| }
            }
        end

        objects << {
            "uuid"                => "d341644d",
            "metric"              => 0.2,
            "announce"            => "-- sleep time ---------------------------------------------------",
            "commands"            => [],
            "command-interpreter" => lambda{ |command, object| }
        }

        objects = DoNotShowUntil::transform(objects)

        (objects)
            .sort{|o1,o2| o1['metric']<=>o2['metric'] }
            .reverse
    end
end

