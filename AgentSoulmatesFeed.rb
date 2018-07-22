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

SOULMATES_FEED_BINARY_FILEPATH = "/Users/pascal/Desktop/SoulmatesFeed"

# AgentSoulmatesFeed::agentuuid()

class AgentSoulmatesFeed

    def self.agentuuid()
        "d5a41176-bd22-4432-9c00-a39ea210fd23"
    end

    def self.interface()
        
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        lastQueryUnixtime = FKVStore::getOrDefaultValue("last-open-unixtime:152182f3-f039-4d87-a79b-92c9a679b03e", "0").to_i
        if (Time.new.to_i-lastQueryUnixtime)>=3600 then


        end
        if FKVStore::getOrNull("packet:64f30b2a-0a39-4ef7-acb4-f72c295cbc37") or () then
            packet = FKVStore::getOrNull("packet:64f30b2a-0a39-4ef7-acb4-f72c295cbc37")
            packet = 
                if packet then
                    JSON.parse(packet)
                else
                    packet = JSON.parse(`/Galaxy/LucilleOS/Binaries/Soulmates-Feed api:total-review-feeder`.strip)
                    FKVStore::set("packet:64f30b2a-0a39-4ef7-acb4-f72c295cbc37", JSON.generate(packet))
                    packet
                end
            object = {
                "uuid"      => "d2cefd09",
                "agent-uid" => self.agentuuid(),
                "metric"    => 0.7*Math.exp( -(Time.new.to_i-packet[2]).to_f/3600 ) + 0.3,
                "announce"  => "#{packet[1]}",
                "commands"  => packet[0] ? ["open"] : ["done"],
                "default-expression" => packet[0] ? "open" : "done",
                "packet" => packet
            }
            TheFlock::addOrUpdateObject(object)
        end

    end

    def self.processObjectAndCommand(object, command)
        if command == "open" then
            if object["packet"][1].start_with?("http") then
                system("open '#{object["packet"][1]}'")
            end
            FKVStore::delete("packet:64f30b2a-0a39-4ef7-acb4-f72c295cbc37")
            FKVStore::set("last-open-unixtime:152182f3-f039-4d87-a79b-92c9a679b03e", Time.new.to_i)
        end
    end
end
