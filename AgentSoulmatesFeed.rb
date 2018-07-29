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
        "object-command-processor" => lambda{ |object, command| AgentSoulmatesFeed::processObjectAndCommand(object, command) }
    }
)

SOULMATES_FEED_BINARY_FILEPATH = "/Users/pascal/Desktop/SoulmatesFeed"

# AgentSoulmatesFeed::agentuuid()

class AgentSoulmatesFeed

    def self.agentuuid()
        "d5a41176-bd22-4432-9c00-a39ea210fd23"
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        return if !CommonsUtils::isLucille18()
        packet = FKVStore::getOrNull("packet:64f30b2a-0a39-4ef7-acb4-f72c295cbc38")
        packet = 
            if packet then
                JSON.parse(packet)
            else
                packet = JSON.parse(`/Galaxy/LucilleOS/Binaries/Soulmates-Feed api:total-review-feeder`.strip)
                FKVStore::set("packet:64f30b2a-0a39-4ef7-acb4-f72c295cbc38", JSON.generate(packet))
                packet
            end
        object = {
            "uuid"      => "d2cefd09",
            "agent-uid" => self.agentuuid(),
            "metric"    => BulletsStream::metric("00391F0D-1579-4BA3-88FB-16BECA05E677", 1, 3),
            "announce"  => "#{packet[1]}",
            "commands"  => [],
            "default-expression" => "eab0bdd6-c6f4-4c6a-bb6b-30ef77936fdc",
            "packet" => packet
        }
        TheFlock::addOrUpdateObject(object)
    end

    def self.processObjectAndCommand(object, command)
        if command == "eab0bdd6-c6f4-4c6a-bb6b-30ef77936fdc" then
            if object["packet"][0] then
                system("open '#{object["packet"][1]}'")
            end
            FKVStore::delete("packet:64f30b2a-0a39-4ef7-acb4-f72c295cbc38")
            BulletsStream::register("00391F0D-1579-4BA3-88FB-16BECA05E677")
        end
    end
end
