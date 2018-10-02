#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"  => "Ordinals",
        "agent-uid"   => "9bafca47-5084-45e6-bdc3-a53194e6fe62",
        "get-objects" => lambda { AgentOrdinals::getObjects() },
        "object-command-processor" => lambda{ |object, command| AgentOrdinals::processObjectAndCommand(object, command) }
    }
)

# AgentOrdinals::getObjects()

class AgentOrdinals

    # AgentOrdinals::agentuuid()
    def self.agentuuid()
        "9bafca47-5084-45e6-bdc3-a53194e6fe62"
    end

    def self.getObjects()
        Ordinals::getCatalystObjects()
    end

    def self.processObjectAndCommand(object, command)
        if command == "done" then
            Ordinals::doDone(object["uuid"])
            return ["remove", object["uuid"]]
        end
        if command == "ordinal:" then
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            Ordinals::setNewOrdinal(object["uuid"], ordinal)
            return ["reload-agent-objects", AgentOrdinals::agentuuid()]
        end
        ["nothing"]
    end
end

