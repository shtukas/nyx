#!/usr/bin/ruby

# encoding: UTF-8
require 'json'
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "CatalystUILines",
        "agent-uid"       => "3d637d25-e634-47f2-b5bd-3d9105ac9da7",
        "general-upgrade" => lambda { AgentCatalystUILines::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentCatalystUILines::processObjectAndCommand(object, command) },
        "interface"       => lambda{ AgentCatalystUILines::interface() }
    }
)

class AgentCatalystUILines

    # AgentCatalystUILines::agentuuid()

    def self.agentuuid()
        "3d637d25-e634-47f2-b5bd-3d9105ac9da7"
    end

    def self.interface()
        
    end

    def self.generalFlockUpgrade()
        object = {
            "uuid"      => "8e4ead40",
            "agent-uid" => self.agentuuid(),
            "metric"    => 0.5,
            "announce"  => "-- space line ----------------------------",
            "commands"  => [],
            "default-expression" => nil
        }
        TheFlock::addOrUpdateObject(object)
        object = {
            "uuid"      => "7291fdd8",
            "agent-uid" => self.agentuuid(),
            "metric"    => 0.2,
            "announce"  => "-- water line ----------------------------",
            "commands"  => [],
            "default-expression" => nil
        }
        TheFlock::addOrUpdateObject(object)
    end

    def self.processObjectAndCommand(object, command)
        if command == "play" then
            
        end
    end
end
