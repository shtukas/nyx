#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

# NSXAgentBabyNights::getObjects()

class NSXAgentBabyNights

    # NSXAgentBabyNights::agentuuid()
    def self.agentuuid()
        "83837e64-554b-4dd0-a478-04386d8010ea"
    end

    def self.names()
        ["pascal", "tracy", "holidays"]
    end

    def self.getObjects()
        objects = []
        if NSXAgentsDataKeyValueStore::getOrNull(NSXAgentBabyNights::agentuuid(), "2b966eeb-1f2c-416c-8aec-bb711b9cc479:#{Time.now.utc.iso8601[0,10]}").nil? and Time.new.hour>=6 then
            object =
                {
                    "uuid"      => "4b9bcf0a",
                    "agent-uid" => self.agentuuid(),
                    "metric"    => 0.97,
                    "announce"  => "Baby Nights",
                    "commands"  => [],
                    "default-expression" => "print"
                }
            objects << object
        end
        objects
    end

    def self.processObjectAndCommand(object, command)
        if command == "print" then
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["Pascal", "Tracy", "Exception:"])
            if operation == "Exception:" then
                exception = LucilleCore::askQuestionAnswerAsString("Exception: ")
                puts "👶 Nights Exception: #{exception}"
                LucilleCore::pressEnterToContinue()
                NSXAgentsDataKeyValueStore::set(NSXAgentBabyNights::agentuuid(), "2b966eeb-1f2c-416c-8aec-bb711b9cc479:#{Time.now.utc.iso8601[0,10]}", "done")
                return ["remove", object["uuid"]]
            end
            xname = operation.downcase
            data = JSON.parse(IO.read("/Galaxy/DataBank/Catalyst/Agents-Data/baby-nights/data.json"))
            data[xname] = data[xname]+1
            puts "👶 Nights [Pascal: #{data["pascal"]}, Tracy: #{data["tracy"]}]"
            if data["pascal"] >= 10 and data["tracy"] >= 10 then
                data["pascal"] = data["pascal"] - 10 
                data["tracy"] = data["tracy"] - 10 
                puts "👶 Nights [Pascal: #{data["pascal"]}, Tracy: #{data["tracy"]}]"
            end
            File.open("/Galaxy/DataBank/Catalyst/Agents-Data/baby-nights/data.json", "w"){|f| f.puts(JSON.pretty_generate(data)) }
            LucilleCore::pressEnterToContinue()
            NSXAgentsDataKeyValueStore::set(NSXAgentBabyNights::agentuuid(), "2b966eeb-1f2c-416c-8aec-bb711b9cc479:#{Time.now.utc.iso8601[0,10]}", "done")
            return ["remove", object["uuid"]]
        end
        ["nothing"]
    end

    def self.interface()
        puts "Welcome to BabyNights interface"
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation:", ["Bonus: Pascal -> Tracy"])
        if operation == "Bonus: Pascal -> Tracy" then
            amount = LucilleCore::askQuestionAnswerAsString("Amount?: ").to_f
            data = JSON.parse(IO.read("/Galaxy/DataBank/Catalyst/Agents-Data/baby-nights/data.json"))
            data["pascal"] = data["pascal"] - amount
            data["tracy"] = data["tracy"] + amount 
            puts "👶 Nights [Pascal: #{data["pascal"]}, Tracy: #{data["tracy"]}]"
            File.open("/Galaxy/DataBank/Catalyst/Agents-Data/baby-nights/data.json", "w"){|f| f.puts(JSON.pretty_generate(data)) }
            LucilleCore::pressEnterToContinue()
        end
    end

end