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
        object2 =
            {
                "uuid"      => "73dc9e2d",
                "agent-uid" => self.agentuuid(),
                "metric"    => ( FKVStore::getOrNull("6a91abf4-7a8d-42e8-9090-3d0e1708ffeb:#{Time.new.to_s[0,10]}").nil? and Time.new.hour>=6 ) ?  0.90 : 0,
                "announce"  => "TimePoints Garbage Collection",
                "commands"  => [],
                "default-expression" => "e565d398-5de9-4dd8-9e19-7673390863c6"
            }
        object1 =
            {
                "uuid"      => "e15ca844",
                "agent-uid" => self.agentuuid(),
                "metric"    => ( FKVStore::getOrNull("551a13ca-271d-4ca7-be56-225787534fc9:#{Time.new.to_s[0,10]}").nil? and Time.new.hour>=6 ) ?  0.89 : 0,
                "announce"  => "TimeGenesis: Guardian",
                "commands"  => [],
                "default-expression" => "d0d34980-b873-4af6-9904-1169dc5cf5fc"
            }
        object5 =
            {
                "uuid"      => "2175b6f1",
                "agent-uid" => self.agentuuid(),
                "metric"    => ( FKVStore::getOrNull("fb072066-29a5-42ba-924c-6c87981f4325:#{Time.new.to_s[0,10]}").nil? and Time.new.hour>=6 ) ?  0.88 : 0,
                "announce"  => "TimeGenesis: Guardian Current Mini Projects",
                "commands"  => [],
                "default-expression" => "050cd5ec-d8a1-4388-bace-bcdbf6c33b65"
            }
        object3 =
            {
                "uuid"      => "5a95258e",
                "agent-uid" => self.agentuuid(),
                "metric"    => ( FKVStore::getOrNull("d9093dbb-61cb-49ae-ae98-e7b586619e52:#{Time.new.to_s[0,10]}").nil? and Time.new.hour>=6 ) ?  0.87 : 0,
                "announce"  => "TimeGenesis: Projects",
                "commands"  => [],
                "default-expression" => "bb735b73-4b4a-47c8-8172-32fa5b1b0314"
            }
        TheFlock::addOrUpdateObjects([object1, object2, object3, object5])
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command == "e565d398-5de9-4dd8-9e19-7673390863c6" then
            # TimePoints Garbage Collection
            TimePointsCore::getTimePoints()
                .each{|point| 
                    if point["creation-unixtime"] < (Time.new.to_i-86400*30) then
                        TimePointsCore::destroyTimePoint(point)
                    end
                }            
            FKVStore::set("6a91abf4-7a8d-42e8-9090-3d0e1708ffeb:#{Time.new.to_s[0,10]}", "done")
        end
        if command == "d0d34980-b873-4af6-9904-1169dc5cf5fc" then
             # TimeGenesis: Guardian
            if self.isWeekDay() then
                puts "TimeGenesis: #{5*CommonsUtils::getLightSpeed()} hours for Guardian"
                LucilleCore::pressEnterToContinue()
                TimePointsCore::issueNewPoint("6596d75b-a2e0-4577-b537-a2d31b156e74", "Guardian", 5*CommonsUtils::getLightSpeed(), false, 0.710)
            end
            FKVStore::set("551a13ca-271d-4ca7-be56-225787534fc9:#{Time.new.to_s[0,10]}", "done")
        end
        if command == "050cd5ec-d8a1-4388-bace-bcdbf6c33b65" then
            # TimeGenesis: Guardian Current Mini Projects
            if self.isWeekDay() then
                folderpath = "/Galaxy/Works/theguardian/Galaxy/05-Pascal Work/03-Current Mini Projects"
                if !File.exists?(folderpath) then
                    puts "The target folder '#{folderpath}' does not exists"
                    LucilleCore::pressEnterToContinue()
                    return
                end
                filenames = Dir.entries(folderpath)
                    .select{|filename| filename[0,1]!="." }
                return if filenames.size==0
                # We give 4 hours equaly spread between tasks, this against a 5 hours Guardian time
                timespanInHours = 4.to_f/filenames.size
                filenames.each{|filename|
                    puts "TimeGenesis: #{timespanInHours*CommonsUtils::getLightSpeed()} hours for Guardian Current Mini Project: #{filename}"
                    LucilleCore::pressEnterToContinue()
                    TimePointsCore::issueNewPoint("031fe929-8dce-4209-ac1f-2ac15555cb78:#{filename}", "Guardian Current Mini Project: #{filename}", timespanInHours*CommonsUtils::getLightSpeed(), true, 0.72)
                }
            end
            FKVStore::set("fb072066-29a5-42ba-924c-6c87981f4325:#{Time.new.to_s[0,10]}", "done")
        end
        if command == "bb735b73-4b4a-47c8-8172-32fa5b1b0314" then
            # TimeGenesis: Projects
            ProjectsCore::projectsUUIDs()
                .select{|projectuuid| ProjectsCore::getTimePointGeneratorOrNull(projectuuid) }
                .each{|projectuuid| 
                    generator = ProjectsCore::getTimePointGeneratorOrNull(projectuuid) # [ <operationUnixtime> <periodInSeconds> <timepointDurationInSeconds> ]
                    if Time.new.to_i >= (generator[0]+generator[1]) then
                        if TimePointsCore::getTimePoints().select{|point| point["project-uuid"]==projectuuid }.size==0 then
                            xname = "#{ProjectsCore::projectUUID2NameOrNull(projectuuid)}#{ProjectsCore::isGuardianTime?(projectuuid) ? " { guardian }" : ""}"
                            puts "TimeGenesis: #{(generator[2].to_f/3600)*CommonsUtils::getLightSpeed()} hours for project: #{xname}"
                            LucilleCore::pressEnterToContinue()
                            TimePointsCore::issueNewPoint(
                                projectuuid, 
                                "project: #{xname}", 
                                (generator[2].to_f/3600)*CommonsUtils::getLightSpeed(),
                                ProjectsCore::isGuardianTime?(projectuuid),
                                ProjectsCore::isGuardianTime?(projectuuid) ? 0.715 : nil)
                            ProjectsCore::resetTimePointGenerator(projectuuid)
                        end
                    end
                }
            timepoints = TimePointsCore::getTimePoints()
                .select{|timepoint| timepoint["domain"]!="6596d75b-a2e0-4577-b537-a2d31b156e74" } # removing the guardian point
                .select{|timepoint| !timepoint["domain"].start_with?("031fe929-8dce-4209-ac1f-2ac15555cb78") } # removing the guardian mini projects
                .select{|timepoint| !(ProjectsCore::projectsUUIDs().select{|projectuuid| ProjectsCore::isGuardianTime?(projectuuid) }.include?(timepoint["domain"])) } # removing the projects that are guardian time
            availableTimeInHours = ( self.isWeekDay() ? 2 : 6 ) - TimePointsCore::liveDueTimeInHoursForTimePoints(timepoints)
            if availableTimeInHours > 0 then
                halvesEnum = LucilleCore::integerEnumerator().lazy.map{|n| 1.to_f/(2 ** n) }
                ProjectsCore::projectsUUIDs()
                    .select{|projectuuid| ProjectsCore::getTimePointGeneratorOrNull(projectuuid).nil? }
                    .each{|projectuuid|
                        timespan = availableTimeInHours * halvesEnum.next() * CommonsUtils::getLightSpeed()
                        xname = "#{ProjectsCore::projectUUID2NameOrNull(projectuuid)}#{ProjectsCore::isGuardianTime?(projectuuid) ? " { guardian }" : ""}"
                        puts "TimeGenesis: #{timespan} hours for project: #{xname}"
                        LucilleCore::pressEnterToContinue()
                        TimePointsCore::issueNewPoint(
                            projectuuid, 
                            "project: #{xname}", 
                            timespan,
                            ProjectsCore::isGuardianTime?(projectuuid),
                            0.550)
                    }
            end
            FKVStore::set("d9093dbb-61cb-49ae-ae98-e7b586619e52:#{Time.new.to_s[0,10]}", "done")
        end
    end
end