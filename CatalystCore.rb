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

# ----------------------------------------------------------------------

class CatalystCore

    # CatalystCore::objects()
    def self.objects()

        #start = Time.new.to_f

        o1 = WaveInterface::getCatalystObjects()
        #puts "Wave   : #{Time.new.to_f - start} , #{o1.count}"

        o4 = Ninja::getCatalystObjects()
        #puts "Ninja  : #{Time.new.to_f - start} , #{o4.count}"

        o5 = Stream::getCatalystObjects()
        #puts "Stream : #{Time.new.to_f - start} , #{o5.count}"

        o6 = Today::getCatalystObjects()
        #puts "Today  : #{Time.new.to_f - start} , #{o6.count}"

        objects = o1+o4+o5+o6

        objects << {
            "uuid"                => "d341644d",
            "metric"              => 0.2,
            "announce"            => "-- sleep time ---------------------------------------------------",
            "commands"            => [],
            "default-commands"    => [],
            "command-interpreter" => lambda{ |command, object| }
        }

        (objects)
            .sort{|o1,o2| o1['metric']<=>o2['metric'] }
            .reverse
    end
end

