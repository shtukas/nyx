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
        "agent-uid"       => "9695eb76-42e7-4b60-8f9e-0108da760362",
        "general-upgrade" => lambda { AgentMorningTimeGeneration::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentMorningTimeGeneration::processObjectAndCommand(object, command) },
        "interface"       => lambda{ AgentMorningTimeGeneration::interface() }
    }
)

# AgentMorningTimeGeneration::generalFlockUpgrade()

class AgentMorningTimeGeneration
    def self.agentuuid()
        "9695eb76-42e7-4b60-8f9e-0108da760362"
    end

    def self.interface()
        
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        if FKVStore::getOrNull("C4C1DB60-2EF4-4CEA-B767-D26BA5A11C53:#{Time.new.to_s[0,10]}").nil? and Time.new.hour>=6 then
            object =
                {
                    "uuid"      => "DAF977FE",
                    "agent-uid" => self.agentuuid(),
                    "metric"    => 1,
                    "announce"  => "Morning time generation",
                    "commands"  => [],
                    "default-expression" => "D3E4E6DE-81B1-42E9-A9DE-A1F1DAF977FE"
                }
            TheFlock::addOrUpdateObject(object)
        end
    end

    def self.processObjectAndCommand(object, command)
        if command == "D3E4E6DE-81B1-42E9-A9DE-A1F1DAF977FE" then
            puts "Review the file, and"
            LucilleCore::pressEnterToContinue()
            IO.read("/Users/pascal/Desktop/MorningTimeGeneration.txt")
                .lines
                .each{|line|
                    line = line.strip
                    next if line.size == 0
                    next if line[0,1] == "#"
                    token, rest = StringParser::decompose(line)
                    timeCommitmentInHours = token.to_f
                    description = rest
                    TimePointsOperator::issueTimePoint(timeCommitmentInHours, description)                    
                }
            FKVStore::set("C4C1DB60-2EF4-4CEA-B767-D26BA5A11C53:#{Time.new.to_s[0,10]}", "done")
        end 
    end
end