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
require_relative "RequirementsReviewReminder.rb"
require_relative "Kimchee.rb"
require_relative "x-laniakea-killer.rb"

# ----------------------------------------------------------------------

class CatalystObjects
    # CatalystObjects::all()
    def self.all()

        sources = [
            ["Wave", lambda { WaveInterface::getCatalystObjects() }],
            ["Ninja", lambda { Ninja::getCatalystObjects() }],
            ["Stream", lambda { Stream::getCatalystObjects() }],
            ["Today", lambda { Today::getCatalystObjects() }],
            ["TimeCommitments", lambda { TimeCommitments::getCatalystObjects() }],
            ["StreamKiller", lambda { StreamKiller::getCatalystObjects() }],
            ["GuardianTime", lambda { GuardianTime::getCatalystObjects() }],
            ["XLaniakea", lambda { XLaniakea::getCatalystObjects() }],
            ["RequirementsReviewReminder", lambda{ RequirementsReviewReminder::getCatalystObjects() }],
            ["Kimchee", lambda{ Kimchee::getCatalystObjects() }],
            ["XLaniakeaKiller", lambda{ XLaniakeaKiller::getCatalystObjects() }]
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
                "command-interpreter" => lambda{ |object, command| }
            }
        end

        objects << {
            "uuid"                => "d341644d",
            "metric"              => 0.2,
            "announce"            => "-- sleep time ---------------------------------------------------",
            "commands"            => [],
            "command-interpreter" => lambda{ |object, command| }
        }

        objects = DoNotShowUntil::transform(objects)

        objects
    end
end

