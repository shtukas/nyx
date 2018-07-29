#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "BabyNights",
        "agent-uid"       => "83837e64-554b-4dd0-a478-04386d8010ea",
        "general-upgrade" => lambda { AgentBabyNights::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentBabyNights::processObjectAndCommand(object, command) }
    }
)

# AgentBabyNights::generalFlockUpgrade()

class AgentBabyNights
    def self.agentuuid()
        "83837e64-554b-4dd0-a478-04386d8010ea"
    end

    def self.names()
        ["pascal", "tracy"]
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        if FKVStore::getOrNull("2b966eeb-1f2c-416c-8aec-bb711b9cc479:#{Time.new.to_s[0,10]}").nil? and Time.new.hour>=6 then
            object =
                {
                    "uuid"      => "4b9bcf0a",
                    "agent-uid" => self.agentuuid(),
                    "metric"    => 1,
                    "announce"  => "Baby Nights",
                    "commands"  => [],
                    "default-expression" => "595bc18c-48a9-4fa2-bfd3-8795f8902766"
                }
            TheFlock::addOrUpdateObject(object)
        end
    end

    def self.processObjectAndCommand(object, command)
        if command == "595bc18c-48a9-4fa2-bfd3-8795f8902766" then
            xname = nil
            loop {
                xname = LucilleCore::askQuestionAnswerAsString(IO.read("/Galaxy/DataBank/Catalyst/Agents-Data/baby-nights/question.txt"))
                next if !AgentBabyNights::names().include?(xname)
                break
            }
            data = JSON.parse(IO.read("/Galaxy/DataBank/Catalyst/Agents-Data/baby-nights/data.json"))
            data[xname] = data[xname]+1
            if data["pascal"] >= 10 and data["tracy"] >= 10 then
                data["pascal"] = data["pascal"] - 10 
                data["tracy"] = data["tracy"] - 10 
            end
            File.open("/Galaxy/DataBank/Catalyst/Agents-Data/baby-nights/data.json", "w"){|f| f.puts(JSON.pretty_generate(data)) }
            puts "👶 Nights [Pascal: #{data["pascal"]}, Tracy: #{data["tracy"]}]"
            LucilleCore::pressEnterToContinue()
            FKVStore::set("2b966eeb-1f2c-416c-8aec-bb711b9cc479:#{Time.new.to_s[0,10]}", "done")
        end 
    end
end