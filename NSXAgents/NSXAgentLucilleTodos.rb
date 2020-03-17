#!/usr/bin/ruby

# encoding: UTF-8

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "time"

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

# -------------------------------------------------------------------------------------

class LucilleMetric
    def initialize()
        @counter = 0
    end
    def metric()
        @counter = @counter + 1
        0.70 - @counter.to_f/1000
    end
end

class NSXAgentLucilleTodos

    # NSXAgentLucilleTodos::agentuid()
    def self.agentuid()
        "853908e3-fe0e-47ac-bb8f-4421a6e7da96"
    end

    # NSXAgentLucilleTodos::getObjects()
    def self.getObjects()
        NSXAgentLucilleTodos::getAllObjects()
    end

    # NSXAgentLucilleTodos::getAllObjects()
    def self.getAllObjects()
        metric = LucilleMetric.new()
        pair = NSXLucilleCalendarFileUtils::getUniqueStruct3FilepathPair()
        $LUCILLE_CALENDAR_FILEPATH_44AF92E9 = pair["filepath"]
        struct3 = pair["struct3"]
        todos = struct3["todo"]
        todos.map{|section|
            {
                "uuid"           => Digest::SHA1.hexdigest(section),
                "agentuid"       => NSXAgentLucilleTodos::agentuid(),
                "contentItem"    => {
                    "type" => "line-and-body",
                    "line" => section.lines.to_a.first.strip,
                    "body" => section.strip
                },
                "metric"         => metric.metric(),
                "commands"       => [],
                "defaultCommand" => nil,
                "isDone"         => nil
            }
        }
    end

    # NSXAgentLucilleTodos::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)
        if command == "open" then
            return 
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentLucilleTodos",
            "agentuid"    => NSXAgentLucilleTodos::agentuid(),
        }
    )
rescue
end
