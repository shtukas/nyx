#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "TimeProtons",
        "agent-uid"       => "ed85a047-2ea1-42a8-a9c7-ab724cc66aef",
        "general-upgrade" => lambda { AgentTimeProtons::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentTimeProtons::processObjectAndCommand(object, command) }
    }
)

# /Galaxy/DataBank/Catalyst/Agents-Data/Time-Protons

=begin

TimeProton {
    "uuid"                      : String, length 8 (so that we can use it as catalyst object uuid)
    "description"               : String   # For the announce
    "time-commitment-in-hours"  : Float    # Essentially the daily time commitment of the lisa
    "lisa-uuid"                 : String   # uuid of the target lisa, for time attribution
}

The json file have name <uuid>.json

=end

class AgentTimeProtons

    def self.agentuuid()
        "ed85a047-2ea1-42a8-a9c7-ab724cc66aef"
    end

    def self.taskToCatalystObject(task)
        {
            "uuid"               => Digest::SHA1.hexdigest(task)[0,8],
            "agent-uid"          => self.agentuuid(),
            "metric"             => 1,
            "announce"           => "TimeProtons: #{task}",
            "commands"           => ["done"],
            "default-expression" => "done",
            "is-running"         => false,
            ":task:"             => task
        }
    end

    def self.protonFilepaths()
        Dir.entries("/Galaxy/DataBank/Catalyst/Agents-Data/Time-Protons")
            .select{|filename| filename[0,1] != "." }
            .map{|filename| "/Galaxy/DataBank/Catalyst/Agents-Data/Time-Protons/#{filename}" }
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        catalystobjects = AgentTimeProtons::protonFilepaths()
            .map{|filepath|
                object = JSON.parse(IO.read(filepath))
                object["agent-uid"] = self.agentuuid()
                object["metric"] = 0.95 + CommonsUtils::traceToMetricShift(Digest::SHA1.hexdigest(object["uuid"]))
                object["announce"] = "TimeProton: #{object["time-commitment-in-hours"]} hours ; #{object["description"]}"
                object["commands"] = ["done"]
                object
            }
        TheFlock::addOrUpdateObjects(catalystobjects)
    end

    def self.processObjectAndCommand(object, command)
        if command == "done" then
            Chronos::addTimeInSeconds(object["lisa-uuid"], object["time-commitment-in-hours"]*3600)
            FileUtils.rm("/Galaxy/DataBank/Catalyst/Agents-Data/Time-Protons/#{object["uuid"]}.json")
        end 
    end

end