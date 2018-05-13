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

require_relative "Agent-Wave.rb"
require_relative "Agent-Ninja.rb"
require_relative "Agent-Stream.rb"
require_relative "Agent-Today.rb"
require_relative "Agent-TimeCommitments.rb"
require_relative "Agent-StreamKiller.rb"
require_relative "Agent-GuardianTime.rb"
require_relative "Agent-Kimchee.rb"
require_relative "Agent-Vienna.rb"
require_relative "Agent-ViennaKiller.rb"
require_relative "Agent-OpenProjects.rb"

# ----------------------------------------------------------------------

# CatalystDataOperator::dataSources()
# CatalystDataOperator::catalystObjects()
# CatalystDataOperator::catalystObjectsFromStructureAlpha()
# CatalystDataOperator::processObject(object, command)
# CatalystDataOperator::agentuuid2objectProcessor(agentuuid)

class CatalystDataOperator

    @@structureAlpha = nil # {"agent-uid" => Array[Agent Object]}

    def self.init()
        structureAlpha = {}
        CatalystDataOperator::dataSources().each{|tuple|
            structureAlpha[tuple[0]] = tuple[1].call()
        }
        @@structureAlpha = structureAlpha
    end

    def self.dataSources()
        [
            ["11fa1438-122e-4f2d-9778-64b55a11ddc2", lambda { GuardianTime::getCatalystObjects() },    lambda{|object, command| GuardianTime::processObject(object, command) }],
            ["b343bc48-82db-4fa3-ac56-3b5a31ff214f", lambda { Kimchee::getCatalystObjects() } ,        lambda{|object, command| Kimchee::processObject(object, command) }],
            ["d3d1d26e-68b5-4a99-a372-db8eb6c5ba58", lambda { Ninja::getCatalystObjects() },           lambda{|object, command| Ninja::processObject(object, command) }],
            ["30ff0f4d-7420-432d-b75b-826a2a8bc7cf", lambda { OpenProjects::getCatalystObjects() },    lambda{|object, command| OpenProjects::processObject(object, command) }],
            ["73290154-191f-49de-ab6a-5e5a85c6af3a", lambda { Stream::getCatalystObjects() },          lambda{|object, command| Stream::processObject(object, command) }],
            ["e16a03ac-ac2c-441a-912e-e18086addba1", lambda { StreamKiller::getCatalystObjects() },    lambda{|object, command| StreamKiller::processObject(object, command) }],
            ["03a8bff4-a2a4-4a2b-a36f-635714070d1d", lambda { TimeCommitments::getCatalystObjects() }, lambda{|object, command| TimeCommitments::processObject(object, command) }],
            ["f989806f-dc62-4942-b484-3216f7efbbd9", lambda { Today::getCatalystObjects() },           lambda{|object, command| Today::processObject(object, command) }],
            ["2ba71d5b-f674-4daf-8106-ce213be2fb0e", lambda { Vienna::getCatalystObjects() },          lambda{|object, command| Vienna::processObject(object, command) }],
            ["7cbbde0d-e5d6-4be9-b00d-8b8011f7173f", lambda { ViennaKiller::getCatalystObjects() },    lambda{|object, command| ViennaKiller::processObject(object, command) }],
            ["283d34dd-c871-4a55-8610-31e7c762fb0d", lambda { Wave::getCatalystObjects() },            lambda{|object, command| Wave::processObject(object, command) }],
        ]
    end

    def self.catalystObjects()
        objects = CatalystDataOperator::catalystObjectsFromStructureAlpha()
        objects = DoNotShowUntil::transform(objects)
        objects
    end

    def self.catalystObjectsFromStructureAlpha()
        @@structureAlpha.values.flatten
    end

    def self.processObject(object, command)
        processor = CatalystDataOperator::agentuuid2objectProcessor(object["agent-uid"])
        processor.call(object, command)
        if LucilleCore::trueNoMoreOftenThanNEverySeconds("2704d558-139d-453d-aa4f-056d863d5aa9", 3600) then
            CatalystDataOperator::dataSources().each{|tuple|
                @@structureAlpha[tuple[0]] = tuple[1].call()
            }
        else
            CatalystDataOperator::dataSources().each{|tuple|
                next if object["agent-uid"] != tuple[0]
                @@structureAlpha[tuple[0]] = tuple[1].call()
            }
        end
    end

    def self.agentuuid2objectProcessor(agentuuid)
        CatalystDataOperator::dataSources()
            .select{|tuple| tuple[0]==agentuuid }
            .each{|tuple|
                return tuple[2]
            }
        raise "looking up processor for unknown agent uuid #{agentuuid}"
    end

end
