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
        "agent-name"      => "DayBucket",
        "agent-uid"       => "e35ef81f-909c-4c36-936f-2ae6b4df00f3",
        "general-upgrade" => lambda { AgentDayBucket::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentDayBucket::processObjectAndCommand(object, command) }
    }
)

# AgentDayBucket::generalFlockUpgrade()

class AgentDayBucket
    def self.agentuuid()
        "e35ef81f-909c-4c36-936f-2ae6b4df00f3"
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        return
        TheFlock::addOrUpdateObjects(objects)
    end

    def self.processObjectAndCommand(object, command)
        if command == "done" then
            
        end
    end
end