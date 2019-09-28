#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

class NSXAgentTemplate

    # NSXAgentTemplate::agentuid()
    def self.agentuid()
        "4b0f5665-9480-4583-8554-592e9b076c76"
    end

    # NSXAgentTemplate::getObjects()
    def self.getObjects()
        []
    end

    # NSXAgentTemplate::getAllObjects()
    def self.getAllObjects()
        []
    end

    # NSXAgentTemplate::processObjectAndCommand(objectuuid, command, isLocalCommand)
    def self.processObjectAndCommand(objectuuid, command, isLocalCommand)
        if command == "open" then
            return 
        end
    end
end

