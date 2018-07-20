#!/usr/bin/ruby

# encoding: UTF-8
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "Projects",
        "agent-uid"       => "10f0ad1e-ff0e-4a8a-8c90-fe09de2342ab",
        "general-upgrade" => lambda { AgentProjects::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentProjects::processObjectAndCommand(object, command) },
        "interface"       => lambda{ AgentProjects::interface() }
    }
)

# AgentProjects::metric

class AgentProjects

    def self.agentuuid()
        "10f0ad1e-ff0e-4a8a-8c90-fe09de2342ab"
    end

    def self.interface()
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        ProjectsCore::updateLocalTimeStructures()
        ProjectsCore::localTimeStructuresDataFiles().each{|data|
            projectuuid = data["projectuuid"]
            referenceTimeStructure = data["reference-time-structure"]
            data["local-commitments"]
                .map{|item|
                    timestructure = {}
                    timestructure["time-unit-in-days"] = referenceTimeStructure["time-unit-in-days"]
                    timestructure["time-commitment-in-hours"] = referenceTimeStructure["time-commitment-in-hours"] * item["timeshare"]
                    timeFragment = 
                        if timestructure["time-commitment-in-hours"] > 0 then
                            timedoneInHours, timetodoInHours, ratio = TimeStructuresOperator::doneMetricsForTimeStructure(item["uuid"], timestructure)
                            "( #{(100*ratio).round(2)} % of #{timetodoInHours.round(2)} hours [today] )"
                        else
                            timedoneInHours, timetodoInHours, ratio = TimeStructuresOperator::doneMetricsForTimeStructure(item["uuid"], timestructure)
                            "( done: #{ timedoneInHours.round(2)} hours )"
                        end
                    objectuuids = ProjectsCore::confirmedAliveCatalystObjectsUUIDsForProjectItem(item["uuid"])
                    catalystObjectsFragment = objectuuids.size > 0 ? "{ attached Catalyst Objects: #{objectuuids.size} }" : ""
                    announce = "project: #{ProjectsCore::projectUUID2NameOrNull(projectuuid)} / #{item["description"]} #{timeFragment} #{catalystObjectsFragment}"
                    metric = MetricsOfTimeStructures::metric2(item["uuid"], 0.1, 0.5, 0.6, timestructure) + CommonsUtils::traceToMetricShift(item["uuid"])
                    if announce.include?("(main)") then
                        metric = metric*0.9
                    end
                    if Chronos::isRunning(item["uuid"]) then
                        metric = 2 + CommonsUtils::traceToMetricShift(item["uuid"])
                    end
                    object              = {}
                    object["uuid"]      = item["uuid"]
                    object["agent-uid"] = self.agentuuid()
                    object["metric"]    = metric
                    object["announce"]  = announce
                    object["commands"]  = Chronos::isRunning(item["uuid"]) ? ["stop"] : ["start"]
                    object["default-expression"] = Chronos::isRunning(item["uuid"]) ? "stop" : ( objectuuids.size > 0 ? "catalyst-objects" : "start" )
                    object["is-running"] = Chronos::isRunning(item["uuid"])
                    object["item-data"] = {}
                    object["item-data"]["projectuuid"] = projectuuid
                    object["item-data"]["item"] = item
                    object
                }
                .each{|object| TheFlock::addOrUpdateObject(object) }
        }
    end

    def self.processObjectAndCommand(object, command)
        if command=="catalyst-objects" then
            # We show the catalyst objects against that local items and propose to start one of them
            # We should also make it so that the item uuid is somehow recorded so that we know where to send the time when we are done.
            item = object["item-data"]["item"]
            objectuuids = ProjectsCore::confirmedAliveCatalystObjectsUUIDsForProjectItem(item["uuid"])
            if objectuuids.size==0 then
                puts "No Catalyst Objects attached to this local item"
                LucilleCore::pressEnterToContinue()
                return
            end
            objectuuid = LucilleCore::selectEntityFromListOfEntitiesOrNull("catalyst object", objectuuids, lambda{ |objectuuid| TheFlock::getObjectByUUIDOrNull(objectuuid)["announce"] })
            return if objectuuid.nil?
            object = TheFlock::getObjectByUUIDOrNull(objectuuid)
            # We know the object is not null
            CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
        end
        if command=="start" then
            itemuuid = object["item-data"]["item"]["uuid"]
            Chronos::start(itemuuid)
        end
        if command=="stop" then
            itemuuid = object["item-data"]["item"]["uuid"]
            timespanInSeconds = Chronos::stop(itemuuid)
            projectuuid = object["item-data"]["projectuuid"]
            ProjectsCore::addTimeInSecondsToProject(projectuuid, timespanInSeconds)
        end
    end
end
