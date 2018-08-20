#!/usr/bin/ruby

# encoding: UTF-8
require 'json'
require_relative "Bob.rb"
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "CatalystUILines",
        "agent-uid"       => "3d637d25-e634-47f2-b5bd-3d9105ac9da7",
        "general-upgrade" => lambda { AgentCatalystUILines::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentCatalystUILines::processObjectAndCommand(object, command) }
    }
)

class AgentCatalystUILines

    # AgentCatalystUILines::agentuuid()

    def self.agentuuid()
        "3d637d25-e634-47f2-b5bd-3d9105ac9da7"
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
    end

    def self.processObjectAndCommand(object, command)
        if command == "enter-atmosphere" then
            CommonsUtils::moveToAtmosphere()
        end
    end
end
