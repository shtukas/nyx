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
        "agent-name"      => "TimeGenenis",
        "agent-uid"       => "11fa1438-122e-4f2d-9778-64b55a11ddc2",
        "general-upgrade" => lambda { AgentTimeGenesis::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentTimeGenesis::processObjectAndCommandFromCli(object, command) },
        "interface"       => lambda{ AgentTimeGenesis::interface() }
    }
)

# AgentTimeGenesis::generalFlockUpgrade()

class AgentTimeGenesis
    def self.agentuuid()
        "11fa1438-122e-4f2d-9778-64b55a11ddc2"
    end

    def self.interface()
        
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        object =
            {
                "uuid"      => "e15ca844",
                "agent-uid" => self.agentuuid(),
                "metric"    => ( FKVStore::getOrNull("26b84bf4-a032-44f7-a101-85476ca27ccf:#{Time.new.to_s[0,10]}").nil? and Time.new.hour>=6 ) ?  1 : 0,
                "announce"  => "TimeGenesis",
                "commands"  => [],
                "default-expression" => "ab8976a7-dc42-412e-b27f-f05cc769686d"
            }
        TheFlock::addOrUpdateObject(object)
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command == "ab8976a7-dc42-412e-b27f-f05cc769686d" then
            if [1, 2, 3, 4, 5].include?(Time.new.wday) then
                TimePointsCore::issueNewPoint("6596d75b-a2e0-4577-b537-a2d31b156e74", "Guardian", 5, false)
            end
            TimePointsCore::getTimePoints()
                .each{|point| 
                    if point["creation-unixtime"] < (Time.new.to_i-86400*30) then
                        TimePointsCore::destroyTimePoint(point)
                    end
                }
            ProjectsCore::projectsUUIDs()
                .select{|projectuuid| ProjectsCore::getTimePointGeneratorOrNull(projectuuid) }
                .each{|projectuuid| 
                    generator = ProjectsCore::getTimePointGeneratorOrNull(projectuuid) # [ <operationUnixtime> <periodInSeconds> <timepointDurationInSeconds> ]
                    if Time.new.to_i >= (generator[0]+generator[1]) then
                        if TimePointsCore::getTimePoints().select{|point| point["project-uuid"]==projectuuid }.size==0 then
                            TimePointsCore::issueNewPoint(
                                projectuuid, 
                                "project: #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}#{ProjectsCore::isGuardianTime?(projectuuid) ? " { guardian }" : ""}", 
                                generator[2].to_f/3600,
                                ProjectsCore::isGuardianTime?(projectuuid))
                            ProjectsCore::resetTimePointGenerator(projectuuid)
                        end
                    end
                }
            busyTimeInHours = TimePointsCore::getTimePoints()
                .map{|point|
                    point["commitment-in-hours"] - point["timespans"].inject(0, :+).to_f/3600

                }
                .inject(0, :+)
            availableTimeInHours = 12 - busyTimeInHours
            puts "availableTimeInHours: #{availableTimeInHours}"
            if availableTimeInHours > 0 then
                halvesEnum = LucilleCore::integerEnumerator().lazy.map{|n| 1.to_f/(2 ** n) }
                ProjectsCore::projectsUUIDs()
                    .select{|projectuuid| ProjectsCore::getTimePointGeneratorOrNull(projectuuid).nil? }
                    .each{|projectuuid|
                        TimePointsCore::issueNewPoint(
                            projectuuid, 
                            "project#{ProjectsCore::isGuardianTime?(projectuuid) ? " (guardian)" : ""}: #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}", 
                            availableTimeInHours * halvesEnum.next(),
                            ProjectsCore::isGuardianTime?(projectuuid))
                    }
            end
            LucilleCore::pressEnterToContinue()
            FKVStore::set("26b84bf4-a032-44f7-a101-85476ca27ccf:#{Time.new.to_s[0,10]}", "done")
        end
    end
end