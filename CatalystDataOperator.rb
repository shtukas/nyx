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
        CatalystDataOperator::dataSources().each{|agentinterface|
            structureAlpha[agentinterface["agent-uid"]] = agentinterface["objects-maker"].call()
        }
        @@structureAlpha = structureAlpha
    end

    def self.dataSources()
        [
            {
                "agent-uid"        => "11fa1438-122e-4f2d-9778-64b55a11ddc2",
                "objects-maker"    => lambda { GuardianTime::getCatalystObjects() },
                "object-processor" => lambda{|object, command| GuardianTime::processObject(object, command) }
            },
            {
                "agent-uid"        => "b343bc48-82db-4fa3-ac56-3b5a31ff214f",
                "objects-maker"    => lambda { Kimchee::getCatalystObjects() },
                "object-processor" => lambda{|object, command| Kimchee::processObject(object, command) }
            },
            {
                "agent-uid"        => "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58",
                "objects-maker"    => lambda { Ninja::getCatalystObjects() },
                "object-processor" => lambda{|object, command| Ninja::processObject(object, command) }
            },
            {
                "agent-uid"        => "30ff0f4d-7420-432d-b75b-826a2a8bc7cf",
                "objects-maker"    => lambda { OpenProjects::getCatalystObjects() },
                "object-processor" => lambda{|object, command| OpenProjects::processObject(object, command) }
            },
            {
                "agent-uid"        => "73290154-191f-49de-ab6a-5e5a85c6af3a",
                "objects-maker"    => lambda { Stream::getCatalystObjects() },
                "object-processor" => lambda{|object, command| Stream::processObject(object, command) }
            },
            {
                "agent-uid"        => "e16a03ac-ac2c-441a-912e-e18086addba1",
                "objects-maker"    => lambda { StreamKiller::getCatalystObjects() },
                "object-processor" => lambda{|object, command| StreamKiller::processObject(object, command) }
            },
            {
                "agent-uid"        => "03a8bff4-a2a4-4a2b-a36f-635714070d1d",
                "objects-maker"    => lambda { TimeCommitments::getCatalystObjects() },
                "object-processor" => lambda{|object, command| TimeCommitments::processObject(object, command) }
            },
            {
                "agent-uid"        => "f989806f-dc62-4942-b484-3216f7efbbd9",
                "objects-maker"    => lambda { Today::getCatalystObjects() },
                "object-processor" => lambda{|object, command| Today::processObject(object, command) }
            },
            {
                "agent-uid"        => "2ba71d5b-f674-4daf-8106-ce213be2fb0e",
                "objects-maker"    => lambda { Vienna::getCatalystObjects() },
                "object-processor" => lambda{|object, command| Vienna::processObject(object, command) }
            },
            {
                "agent-uid"        => "7cbbde0d-e5d6-4be9-b00d-8b8011f7173f",
                "objects-maker"    => lambda { ViennaKiller::getCatalystObjects() },
                "object-processor" => lambda{|object, command| ViennaKiller::processObject(object, command) }
            },
            {
                "agent-uid"        => "283d34dd-c871-4a55-8610-31e7c762fb0d",
                "objects-maker"    => lambda { Wave::getCatalystObjects() },
                "object-processor" => lambda{|object, command| Wave::processObject(object, command) }
            }
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
            CatalystDataOperator::dataSources().each{|agentinterface|
                @@structureAlpha[agentinterface["agent-uid"]] = agentinterface["objects-maker"].call()
            }
        else
            CatalystDataOperator::dataSources().each{|agentinterface|
                next if object["agent-uid"] != agentinterface["agent-uid"]
                @@structureAlpha[agentinterface["agent-uid"]] = agentinterface["objects-maker"].call()
            }
        end
    end

    def self.agentuuid2objectProcessor(agentuuid)
        CatalystDataOperator::dataSources()
            .select{|agentinterface| agentinterface["agent-uid"]==agentuuid }
            .each{|agentinterface|
                return agentinterface["object-processor"]
            }
        raise "looking up processor for unknown agent uuid #{agentuuid}"
    end

end
