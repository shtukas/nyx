#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'json'
require 'date'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'find'
require 'json'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "FloatingTimeStructures",
        "agent-uid"       => "b620169b-1fb4-4362-9e84-af0e9b941dc8",
        "general-upgrade" => lambda { FloatingTimeStructures::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| FloatingTimeStructures::processObjectAndCommandFromCli(object, command) },
        "interface"       => lambda{ FloatingTimeStructures::interface() }
    }
)

class FloatingTimeStructures

    def self.agentuuid()
        "b620169b-1fb4-4362-9e84-af0e9b941dc8"
    end

    def self.interface()
        
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        Dir.entries("/Galaxy/DataBank/Catalyst/Agents-Data/floating-time-structures")
            .select{|filename| filename[-5, 5]=='.json' }
            .map{|filename| "/Galaxy/DataBank/Catalyst/Agents-Data/floating-time-structures/#{filename}" }
            .map{|filepath| [filepath, JSON.parse(IO.read(filepath))] }
            .map{|data|
                filepath, packet = data
                # object: { :uuid, :description, :timestructure }
                uuid = packet["uuid"]
                description = packet["description"]
                timestructure = packet["timestructure"]
                object              = {}
                object["uuid"]      = uuid
                object["agent-uid"] = self.agentuuid()
                object["metric"]    = MetricsOfTimeStructures::metric2(uuid, 0.5, 0.5, 0.80, timestructure) + CommonsUtils::traceToMetricShift(uuid)
                object["announce"]  = "floating: #{description} ( #{(100*TimeStructuresOperator::timeStructureRatioDoneOrNull(uuid, timestructure)).round(2)} % of #{(timestructure["time-commitment-in-hours"].to_f/timestructure["time-unit-in-days"]).round(2)} hours [today] )"
                object["commands"]  = Chronos::isRunning(uuid) ? ["stop"] : ["start"]
                object["default-expression"] = Chronos::isRunning(uuid) ? "stop" : "start"
                object["is-running"] = Chronos::isRunning(uuid)
                object["item-data"] = {}
                object["item-data"]["filepath"] = filepath
                object["item-data"]["data"] = data
                object                   
            }
            .compact
            .each{|object| TheFlock::addOrUpdateObject(object) }
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command=='start' then
            Chronos::start(object["uuid"])
        end
        if command=='stop' then
            uuid = object["uuid"]
            Chronos::stop(uuid)
            doneTimeInSeconds = Chronos::summedTimespansWithDecayInSecondsLiveValue(uuid, 1)
            hours = object["item-data"]["data"][1]["timestructure"]["time-commitment-in-hours"]
            if doneTimeInSeconds.to_f/3600 > hours then
                FileUtils.rm(object["item-data"]["filepath"])
            end
        end
    end
end
