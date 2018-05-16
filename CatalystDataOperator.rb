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
require_relative "Agent-GuardianTime.rb"
require_relative "Agent-Kimchee.rb"
require_relative "Agent-Vienna.rb"
require_relative "Agent-OpenProjects.rb"

# ----------------------------------------------------------------------

# CatalystDataOperator::agents()
# CatalystDataOperator::agentuuid2objectProcessor(agentuuid)
# CatalystDataOperator::catalystObjects()
# CatalystDataOperator::processObject(object, command)
# CatalystDataOperator::selectAgentAndRunInterface()

class CatalystDataOperator

    def self.agents()
        [
            {
                "agent-name"       => "GuardianTime",
                "agent-uid"        => "11fa1438-122e-4f2d-9778-64b55a11ddc2",
                "objects-get"      => lambda { GuardianTime::getCatalystObjects() },
                "object-processor" => lambda{|object, command| GuardianTime::processObject(object, command) },
                "interface"        => lambda{ GuardianTime::interface() }
            },
            {
                "agent-name"       => "Kimchee",
                "agent-uid"        => "b343bc48-82db-4fa3-ac56-3b5a31ff214f",
                "objects-get"      => lambda { Kimchee::getCatalystObjects() },
                "object-processor" => lambda{|object, command| Kimchee::processObject(object, command) },
                "interface"        => lambda{ Kinchee::interface() }
            },
            {
                "agent-name"       => "Ninja",
                "agent-uid"        => "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58",
                "objects-get"      => lambda { Ninja::getCatalystObjects() },
                "object-processor" => lambda{|object, command| Ninja::processObject(object, command) },
                "interface"        => lambda{ Ninja::interface() }
            },
            {
                "agent-name"       => "OpenProjects",
                "agent-uid"        => "30ff0f4d-7420-432d-b75b-826a2a8bc7cf",
                "objects-get"      => lambda { OpenProjects::getCatalystObjects() },
                "object-processor" => lambda{|object, command| OpenProjects::processObject(object, command) },
                "interface"        => lambda{ OpenProjects::interface() }
            },
            {
                "agent-name"       => "Stream",
                "agent-uid"        => "73290154-191f-49de-ab6a-5e5a85c6af3a",
                "objects-get"      => lambda { Stream::getCatalystObjects() },
                "object-processor" => lambda{|object, command| Stream::processObject(object, command) },
                "interface"        => lambda{ Stream::interface() }
            },
            {
                "agent-name"       => "TimeCommitments",
                "agent-uid"        => "03a8bff4-a2a4-4a2b-a36f-635714070d1d",
                "objects-get"      => lambda { TimeCommitments::getCatalystObjects() },
                "object-processor" => lambda{|object, command| TimeCommitments::processObject(object, command) },
                "interface"        => lambda{ TimeCommitments::interface() }
            },
            {
                "agent-name"       => "Today",
                "agent-uid"        => "f989806f-dc62-4942-b484-3216f7efbbd9",
                "objects-get"      => lambda { Today::getCatalystObjects() },
                "object-processor" => lambda{|object, command| Today::processObject(object, command) },
                "interface"        => lambda{ Today::interface() }
            },
            {
                "agent-name"       => "Vienna",
                "agent-uid"        => "2ba71d5b-f674-4daf-8106-ce213be2fb0e",
                "objects-get"      => lambda { Vienna::getCatalystObjects() },
                "object-processor" => lambda{|object, command| Vienna::processObject(object, command) },
                "interface"        => lambda{ Vienna::interface() }
            },
            {
                "agent-name"       => "Wave",
                "agent-uid"        => "283d34dd-c871-4a55-8610-31e7c762fb0d",
                "objects-get"      => lambda { Wave::getCatalystObjects() },
                "object-processor" => lambda{|object, command| Wave::processObject(object, command) },
                "interface"        => lambda{ Wave::interface() }
            }
        ]
    end

    def self.agentuuid2objectProcessor(agentuuid)
        CatalystDataOperator::agents()
            .select{|agentinterface| agentinterface["agent-uid"]==agentuuid }
            .each{|agentinterface|
                return agentinterface["object-processor"]
            }
        raise "looking up processor for unknown agent uuid #{agentuuid}"
    end

    def self.catalystObjects()
        objects = CatalystDataOperator::agents().map{|agentinterface| agentinterface["objects-get"].call() }.flatten
        objects = DoNotShowUntil::transform(objects)
        objects
    end

    def self.processObject(object, command)
        CatalystDataOperator::agentuuid2objectProcessor(object["agent-uid"]).call(object, command)
    end

    def self.selectAgentAndRunInterface()
        agent = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("agent", CatalystDataOperator::agents(), lambda{ |agent| agent["agent-name"] })
        agent["interface"].call()
    end

end
