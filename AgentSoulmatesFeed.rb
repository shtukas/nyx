#!/usr/bin/ruby

# encoding: UTF-8
require 'json'
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "SoulmatesFeed",
        "agent-uid"       => "d5a41176-bd22-4432-9c00-a39ea210fd23",
        "general-upgrade" => lambda { AgentSoulmatesFeed::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentSoulmatesFeed::processObjectAndCommand(object, command) },
        "interface"       => lambda{ AgentSoulmatesFeed::interface() }
    }
)

EVEONLINE_BINARY_FILEPATH = "/Users/pascal/Desktop/SoulmatesFeed"

# AgentSoulmatesFeed::agentuuid()

class AgentSoulmatesFeed

    def self.agentuuid()
        "d5a41176-bd22-4432-9c00-a39ea210fd23"
    end

    def self.interface()
        
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        message = FKVStore::getOrNull("ae4fcccc-e390-408e-af92-a53a5f3b708b")
        if message.nil? then
            if CommonsUtils::trueNoMoreOftenThanNEverySeconds("/x-space/x-cache", "4ed58d61-9c83-4e31-9444-9d663e908376", 3600*2) then
                message = `/Galaxy/LucilleOS/Binaries/Soulmates-Feed`.strip  
            end
        end
        return if message.nil?        
        object = {
            "uuid"      => "5d5490bb",
            "agent-uid" => self.agentuuid(),
            "metric"    => 1,
            "announce"  => "#{message}",
            "commands"  => message.start_with?("http") ? ["open"] : ["done"],
            "default-expression" => message.start_with?("http") ? "open" : "done",
            "message" => message
        }
        TheFlock::addOrUpdateObject(object)
    end

    def self.processObjectAndCommand(object, command)
        if command == "open" then
            system("open '#{object["message"]}'")
            FKVStore::delete("ae4fcccc-e390-408e-af92-a53a5f3b708b")
        end
        if command == "done" then
            FKVStore::delete("ae4fcccc-e390-408e-af92-a53a5f3b708b")
        end
    end
end
