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

# -------------------------------------------------------------------------------------

# AgentOrdinals::getObjects()

class AgentOrdinals

    # AgentOrdinals::agentuuid()
    def self.agentuuid()
        "9bafca47-5084-45e6-bdc3-a53194e6fe62"
    end

    def self.getObjects()
        OrdinalsFile::getCatalystObjects()
    end

    def self.processObjectAndCommand(object, command)
        if command == "done" then
            OrdinalsFile::doDone(object["uuid"])
            return ["remove", object["uuid"]]
        end
        
        if command == 'ordinal:' then
            ordinal = ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            OrdinalsFile::setNewOrdinal(object["data:description"], ordinal)
            return ["reload-agent-objects", AgentOrdinals::agentuuid()]
        end
        ["nothing"]
    end
end

