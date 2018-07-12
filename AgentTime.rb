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
        "agent-name"      => "AgentTime",
        "agent-uid"       => "02e64c07-28ff-4870-97fe-179cc895c094",
        "general-upgrade" => lambda { AgentTime::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentTime::processObjectAndCommand(object, command) },
        "interface"       => lambda{ AgentTime::interface() }
    }
)

class AgentTime

    def self.agentuuid()
        "02e64c07-28ff-4870-97fe-179cc895c094"
    end

    def self.interface()
        
    end

    def self.lisaToMetric(lisa)
        ageInHours = (Time.new.to_f - lisa['unixtime']).to_f/3600
        0.6 + 0.8*(1-Math.exp(-ageInHours))
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        Dir.entries("/Galaxy/DataBank/Catalyst/Agents-Data/Lisa")
            .select{|filename| filename[-5, 5]=='.json' }
            .map{|filename| "/Galaxy/DataBank/Catalyst/Agents-Data/Lisa/#{filename}" }
            .map{|filepath| [filepath, JSON.parse(IO.read(filepath))] }
            .map{|data|
                filepath, lisa = data
                # Lisa: { :uuid, :unixtime :description, :time-commitment-in-hours }
                uuid = lisa["uuid"]
                description = lisa["description"]
                timestructure = { "time-unit-in-days"=> 1, "time-commitment-in-hours" => lisa["time-commitment-in-hours"] }
                timedoneInHours, timetodoInHours, ratio = TimeStructuresOperator::doneMetricsForTimeStructure(uuid, timestructure)
                object              = {}
                object["uuid"]      = uuid
                object["agent-uid"] = self.agentuuid()
                object["metric"]    = self.lisaToMetric(lisa)
                object["announce"]  = "time: #{description} ( #{100*ratio.round(2)} % of #{lisa["time-commitment-in-hours"]} hours )"
                object["commands"]  = Chronos::isRunning(uuid) ? ["stop", "loop"] : ["start", "loop"]
                object["default-expression"] = Chronos::isRunning(uuid) ? "stop" : "start"
                object["is-running"] = Chronos::isRunning(uuid)
                object["item-data"] = {}
                object["item-data"]["filepath"] = filepath
                object["item-data"]["lisa"] = lisa
                object["item-data"]["ratio"] = ratio
                object                   
            }
            .each{|object|
                if object["item-data"]["ratio"] > 1 then
                    system("terminal-notifier -title 'Catalyst Lisa' -message '#{object["item-data"]["lisa"]["description"]} is done'")
                    sleep 2
                end
                TheFlock::addOrUpdateObject(object) 
            }
    end

    def self.processObjectAndCommand(object, command)
        uuid = object["uuid"]
        if command=='start' then
            Chronos::start(uuid)
        end
        if command=='stop' then
            timeSpanInSeconds = Chronos::stop(uuid)
            lisa     = object["item-data"]["lisa"]
            filepath = object["item-data"]["filepath"]
            puts "time: #{timeSpanInSeconds} seconds, #{(timeSpanInSeconds.to_f/3600).round(2)} hours"
            choice = LucilleCore::selectEntityFromListOfEntitiesOrNull("injection", ["no target", "project"])
            return if choice.nil?
            return if choice == "no target"
            if choice == "project" then
                projectuuid = ProjectsCore::ui_interactivelySelectProjectUUIDOrNUll()
                return if projectuuid.nil?
                ProjectsCore::addTimeInSecondsToProject(projectuuid, timeSpanInSeconds)
                lisa = object["item-data"]["lisa"]
                timestructure = { "time-unit-in-days"=> 1, "time-commitment-in-hours" => lisa["time-commitment-in-hours"] }
                timedoneInHours, timetodoInHours, ratio = TimeStructuresOperator::doneMetricsForTimeStructure(uuid, timestructure)
                if ratio > 1 then
                    FileUtils.rm(filepath)
                end
            end
        end
        if command=='loop' then
           puts "You need to implement that one"
           LucilleCore::pressEnterToContinue()
        end
    end
end
