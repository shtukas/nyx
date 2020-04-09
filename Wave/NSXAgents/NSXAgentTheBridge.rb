#!/usr/bin/ruby

# encoding: UTF-8


require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "time"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

# -------------------------------------------------------------------------------------

class NSXAgentTheBridge

    # NSXAgentTheBridge::agentuid()
    def self.agentuid()
        "a64c458b-e6a1-4d02-a35c-dd4e4a78f139"
    end

    # NSXAgentTheBridge::getObjects()
    def self.getObjects()
        NSXAgentTheBridge::getAllObjects()
    end

    # NSXAgentTheBridge::sources()
    def self.sources()
        JSON.parse(IO.read("#{CATALYST_FOLDERPATH}/Wave/TheBridge/sources.json"))
    end

    # NSXAgentTheBridge::getAllObjects()
    def self.getAllObjects()
        NSXAgentTheBridge::sources()
            .map{|source|
                begin
                    JSON.parse(`#{source}`)
                rescue
                    [
                        {
                            "uuid"            => SecureRandom.hex,
                            "agentuid"        => nil,
                            "contentItem"     => {
                                "type" => "line",
                                "line" => "Problems extracting catalyst objects at '#{source}'"
                            },
                            "metric"          => 1,
                            "commands"        => []
                        }
                    ]
                end
            }
            .flatten
    end

    # NSXAgentTheBridge::getGenerationSpeeds()
    def self.getGenerationSpeeds()
        NSXAgentTheBridge::sources()
            .map{|source|
                t1 = Time.new.to_f
                JSON.parse(`#{source}`)
                t2 = Time.new.to_f
                {
                    "source" => source,
                    "timespan" => t2-t1 
                }
            }

    end

    # NSXAgentTheBridge::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)

    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentTheBridge",
            "agentuid"    => NSXAgentTheBridge::agentuid(),
        }
    )
rescue
end
