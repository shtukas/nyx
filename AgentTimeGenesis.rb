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

    def self.isWeekDay()
        [1, 2, 3, 4, 5].include?(Time.new.wday)
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        object3 =
            {
                "uuid"      => "5a95258e",
                "agent-uid" => self.agentuuid(),
                "metric"    => ( FKVStore::getOrNull("d9093dbb-61cb-49ae-ae98-e7b586619e53:#{Time.new.to_s[0,10]}").nil? ) ?  0.87 : 0,
                "announce"  => "TimeGenesis for #{Time.new.to_s[0,10]}",
                "commands"  => [],
                "default-expression" => "bb735b73-4b4a-47c8-8172-32fa5b1b0314"
            }
        TheFlock::addOrUpdateObject(object3)
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command == "bb735b73-4b4a-47c8-8172-32fa5b1b0314" then
            # TimeGenesis: Projects
            # We now have all the projects, work and personal under one roof. 
            # The problem now is to attribute times to them

            # We start by adding time to the ones which have a time generator against them
            projectsUUIDs = ProjectsCore::projectsUUIDs()
                .select{|projectuuid| ProjectsCore::getTimePointGeneratorOrNull(projectuuid) }

            projectsUUIDs.each{|projectuuid| 
                    generator = ProjectsCore::getTimePointGeneratorOrNull(projectuuid) # [ <operationUnixtime> <periodInSeconds> <timepointDurationInSeconds> ]
                    if Time.new.to_i >= (generator[0]+generator[1]) then
                        if TimePointsCore::getTimePoints().select{|point| point["project-uuid"]==projectuuid }.size==0 then
                            xname = "#{ProjectsCore::projectUUID2NameOrNull(projectuuid)}"
                            print "TimeGenesis: #{(generator[2].to_f/3600)} hours for project: #{xname} "
                            STIN.gets()
                            TimePointsCore::issueNewPoint(projectuuid, "project: #{xname}", (generator[2].to_f/3600))
                            ProjectsCore::resetTimePointGenerator(projectuuid)
                        end
                    end
                }

            alreadyTakenTimeInHours = TimePointsCore::getTimePoints().map{|timepoint| TimePointsCore::timepointToDueTimeinHoursUpToDate(timepoint) }.inject(0, :+)
            print "TimeGenesis: already taken time: #{alreadyTakenTimeInHours} hours "
            STDIN.gets()

            # Then we manually add time to the others
            projectsUUIDs = ProjectsCore::projectsUUIDs()
                .select{|projectuuid| !ProjectsCore::getTimePointGeneratorOrNull(projectuuid) }
            timeAttributions = {} # projectuuid => time in hour
            loop {
                projectuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("project", ProjectsCore::projectsUUIDs(), lambda{|projectuuid| ProjectsCore::projectUUID2NameOrNull(projectuuid) })
                break if projectuuid.nil?
                hours = LucilleCore::askQuestionAnswerAsString("Hours for #{ProjectsCore::projectUUID2NameOrNull(projectuuid)} : ").to_f
                timeAttributions[projectuuid] = hours
                timeAttributions.each{|projectuuid, hours|
                    puts "    - project: #{ProjectsCore::projectUUID2NameOrNull(projectuuid)} : #{hours} hours"
                }
                print "        TOTAL: #{alreadyTakenTimeInHours + timeAttributions.values.inject(0, :+)} hours "
                STDIN.gets()
            }

            timeAttributions.each{|projectuuid, hours|
                print "TimeGenesis: #{hours} hours for project: #{ProjectsCore::projectUUID2NameOrNull(projectuuid)} "
                STDIN.gets()
                TimePointsCore::issueNewPoint(projectuuid, "project: #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}", hours)
            }

            totalHoursForToday = TimePointsCore::getTimePoints().map{|timepoint| TimePointsCore::timepointToDueTimeinHoursUpToDate(timepoint) }.inject(0, :+)
            puts "TimeGenesis: total hours for today: #{totalHoursForToday} hours"
            LucilleCore::pressEnterToContinue()

            FKVStore::set("d9093dbb-61cb-49ae-ae98-e7b586619e53:#{Time.new.to_s[0,10]}", "done")
        end
    end
end