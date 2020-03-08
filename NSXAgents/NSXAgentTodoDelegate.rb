#!/usr/bin/ruby

# encoding: UTF-8
require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

class NSXAgentTodoDelegate

    # NSXAgentTodoDelegate::agentuid()
    def self.agentuid()
        "F074537E-2CE0-4757-987C-690AB80D759E"
    end

    # NSXAgentTodoDelegate::getObjects()
    def self.getObjects()
        NSXAgentTodoDelegate::getAllObjects()
    end

    # NSXAgentTodoDelegate::getAllObjects()
    def self.getAllObjects()
        JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Applications/Todo/catalyst-objects`)
    end

    # NSXAgentTodoDelegate::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)
        if command == "open" then
            return 
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentTodoDelegate",
            "agentuid"    => NSXAgentTodoDelegate::agentuid(),
        }
    )
rescue
end
