#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require 'json'

=begin

  -- reading the string and building the object
     dataset = IO.read($dataset_location)
     JSON.parse(dataset)

  -- printing the string
     file.puts JSON.pretty_generate(dataset)

=end

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

require_relative "Agent-Wave.rb"
require_relative "Agent-Ninja.rb"
require_relative "Agent-Stream.rb"
require_relative "Agent-Today.rb"
require_relative "Agent-TimeCommitments.rb"
require_relative "Agent-GuardianTime.rb"
require_relative "Agent-Kimchee.rb"
require_relative "Agent-Vienna.rb"
require_relative "Agent-OpenProjects.rb"

# ----------------------------------------------------------------------

# TheOperator::agents()
# TheOperator::agentuuid2FlockObjectCommandProcessor(agentuuid)
# TheOperator::flockGeneralUpgrade(flock)
# TheOperator::upgradeFlockUsingObjectAndCommand(object, command)
# TheOperator::selectAgentAndRunInterface()

# TheOperator::upgradeFlockUsingObjectAndCommand(flock, object, command)

class TheOperator

    def self.agents()
        [
            {
                "agent-name"       => "GuardianTime",
                "agent-uid"        => "11fa1438-122e-4f2d-9778-64b55a11ddc2",
                "flock-general-upgrade"      => lambda { |flock| GuardianTime::flockGeneralUpgrade(flock) },
                "flock-object-command" => lambda{ |flock, object, command| GuardianTime::upgradeFlockUsingObjectAndCommand(flock, object, command) },
                "interface"        => lambda{ GuardianTime::interface() }
            },
            {
                "agent-name"       => "Kimchee",
                "agent-uid"        => "b343bc48-82db-4fa3-ac56-3b5a31ff214f",
                "flock-general-upgrade"      => lambda { |flock| Kimchee::flockGeneralUpgrade(flock) },
                "flock-object-command" => lambda{ |flock, object, command| Kimchee::upgradeFlockUsingObjectAndCommand(flock, object, command) },
                "interface"        => lambda{ Kinchee::interface() }
            },
            {
                "agent-name"       => "Ninja",
                "agent-uid"        => "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58",
                "flock-general-upgrade"      => lambda { |flock| Ninja::flockGeneralUpgrade(flock) },
                "flock-object-command" => lambda{ |flock, object, command| Ninja::upgradeFlockUsingObjectAndCommand(flock, object, command) },
                "interface"        => lambda{ Ninja::interface() }
            },
            {
                "agent-name"       => "OpenProjects",
                "agent-uid"        => "30ff0f4d-7420-432d-b75b-826a2a8bc7cf",
                "flock-general-upgrade"      => lambda { |flock| OpenProjects::flockGeneralUpgrade(flock) },
                "flock-object-command" => lambda{ |flock, object, command| OpenProjects::upgradeFlockUsingObjectAndCommand(flock, object, command) },
                "interface"        => lambda{ OpenProjects::interface() }
            },
            {
                "agent-name"       => "Stream",
                "agent-uid"        => "73290154-191f-49de-ab6a-5e5a85c6af3a",
                "flock-general-upgrade"      => lambda { |flock| Stream::flockGeneralUpgrade(flock) },
                "flock-object-command" => lambda{ |flock, object, command| Stream::upgradeFlockUsingObjectAndCommand(flock, object, command) },
                "interface"        => lambda{ Stream::interface() }
            },
            {
                "agent-name"       => "TimeCommitments",
                "agent-uid"        => "03a8bff4-a2a4-4a2b-a36f-635714070d1d",
                "flock-general-upgrade"      => lambda { |flock| TimeCommitments::flockGeneralUpgrade(flock) },
                "flock-object-command" => lambda{ |flock, object, command| TimeCommitments::upgradeFlockUsingObjectAndCommand(flock, object, command) },
                "interface"        => lambda{ TimeCommitments::interface() }
            },
            {
                "agent-name"       => "Today",
                "agent-uid"        => "f989806f-dc62-4942-b484-3216f7efbbd9",
                "flock-general-upgrade"      => lambda { |flock| Today::flockGeneralUpgrade(flock) },
                "flock-object-command" => lambda{ |flock, object, command| Today::upgradeFlockUsingObjectAndCommand(flock, object, command) },
                "interface"        => lambda{ Today::interface() }
            },
            {
                "agent-name"       => "Vienna",
                "agent-uid"        => "2ba71d5b-f674-4daf-8106-ce213be2fb0e",
                "flock-general-upgrade"      => lambda { |flock| Vienna::flockGeneralUpgrade(flock) },
                "flock-object-command" => lambda{ |flock, object, command| Vienna::upgradeFlockUsingObjectAndCommand(flock, object, command) },
                "interface"        => lambda{ Vienna::interface() }
            },
            {
                "agent-name"       => "Wave",
                "agent-uid"        => "283d34dd-c871-4a55-8610-31e7c762fb0d",
                "flock-general-upgrade"      => lambda { |flock| Wave::flockGeneralUpgrade(flock) },
                "flock-object-command" => lambda{ |flock, object, command| Wave::upgradeFlockUsingObjectAndCommand(flock, object, command) },
                "interface"        => lambda{ Wave::interface() }
            }
        ]
    end

    def self.agentuuid2FlockObjectCommandProcessor(agentuuid)
        TheOperator::agents()
            .select{|agentinterface| agentinterface["agent-uid"]==agentuuid }
            .each{|agentinterface|
                return agentinterface["flock-object-command"]
            }
        raise "looking up processor for unknown agent uuid #{agentuuid}"
    end

    def self.flockGeneralUpgrade(flock)
        TheOperator::agents().each{|agentinterface|
            flock, events = agentinterface["flock-general-upgrade"].call(flock)
            events.each{|event|
                EventsLogReadWrite::commitEventToTimeline(event)
            }
        }
        flock
    end

    def self.selectAgentAndRunInterface()
        agent = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("agent", TheOperator::agents(), lambda{ |agent| agent["agent-name"] })
        agent["interface"].call()
    end

    def self.upgradeFlockUsingObjectAndCommand(flock, object, expression)

        # no object needed

        if expression == 'help' then
            Jupiter::putshelp()
            LucilleCore::pressEnterToContinue()
            return [flock, []]
        end

        if expression == 'clear' then
            system("clear")
            return [flock, []]
        end

        if expression=="interface" then
            TheOperator::selectAgentAndRunInterface()
            return [flock, []]
        end

        if expression == 'info' then
            puts "CatalystDevOps::getArchiveSizeInMegaBytes(): #{CatalystDevOps::getArchiveSizeInMegaBytes()}".green
            puts "Todolists:".green
            puts "    Stream count : #{( count1 = Stream::getUUIDs().size )}".green
            puts "    Vienna count : #{(count3 = Vienna::getUnreadLinks().count)}".green
            puts "    Total        : #{(count1+count3)}".green
            puts "Requirements:".green
            puts "    On  : #{(RequirementsOperator::getAllRequirements() - RequirementsOperator::getCurrentlyUnsatisfiedRequirements()).join(", ")}".green
            puts "    Off : #{RequirementsOperator::getCurrentlyUnsatisfiedRequirements().join(", ")}".green
            LucilleCore::pressEnterToContinue()
            return [flock, []]
        end

        if expression == 'lib' then
            LibrarianExportedFunctions::librarianUserInterface_librarianInteractive()
            return [flock, []]
        end

        if expression.start_with?('wave:') then
            description = expression[5, expression.size].strip
            description = Jupiter::processItemDescriptionPossiblyAsTextEditorInvitation(description)
            folderpath = Wave::issueNewItemFromDescriptionInteractive(description)
            puts "created item: #{folderpath}"
            LucilleCore::pressEnterToContinue()
            return [flock, []]
        end

        if expression.start_with?('stream:') then
            description = expression[7, expression.size].strip
            description = Jupiter::processItemDescriptionPossiblyAsTextEditorInvitation(description)
            folderpath = Stream::issueNewItemFromDescription(description)
            puts "created item: #{folderpath}"
            LucilleCore::pressEnterToContinue()
            return [flock, []]
        end

        if expression.start_with?('open-project:') then
            description = expression[13, expression.size].strip
            description = Jupiter::processItemDescriptionPossiblyAsTextEditorInvitation(description)
            folderpath = OpenProjects::issueNewItemFromDescription(description)
            puts "created item: #{folderpath}"
            LucilleCore::pressEnterToContinue()
            return [flock, []]
        end

        if expression.start_with?("r:on") then
            command, requirement = expression.split(" ")
            RequirementsOperator::setSatisfifiedRequirement(requirement)
            return [flock, []]
        end

        if expression.start_with?("r:off") then
            command, requirement = expression.split(" ")
            RequirementsOperator::setUnsatisfiedRequirement(requirement)
            return [flock, []]
        end

        if expression.start_with?("r:show") then
            command, requirement = expression.split(" ")
            if requirement.size==0 then
                requirement = RequirementsOperator::selectRequirementFromExistingRequirementsOrNull()
            end
            loop {
                requirementObjects = TheOperator::flockGeneralUpgrade().select{ |object| RequirementsOperator::getObjectRequirements(object['uuid']).include?(requirement) }
                selectedobject = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("object", requirementObjects, lambda{ |object| Jupiter::object2Line_v0(object) })
                break if selectedobject.nil?
                Jupiter::interactiveDisplayObjectAndProcessCommand(selectedobject, flock)
            }
            return [flock, []]
        end

        if expression.start_with?("search") then
            pattern = expression[6,expression.size].strip
            loop {
                searchobjects = TheOperator::flockGeneralUpgrade().select{|object| Jupiter::object2Line_v0(object).downcase.include?(pattern.downcase) }
                break if searchobjects.size==0
                selectedobject = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("object", searchobjects, lambda{ |object| Jupiter::object2Line_v0(object) })
                break if selectedobject.nil?
                Jupiter::interactiveDisplayObjectAndProcessCommand(selectedobject, flock)
            }
            return [flock, []]
        end

        return [flock, []] if object.nil?

        # object needed

        if expression == '!today' then
            TodayOrNotToday::notToday(object["uuid"])
            return [flock, []]
        end

        if expression == 'expose' then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return [flock, []]
        end

        if expression.start_with?('+') then
            code = expression
            if (datetime = Jupiter::codeToDatetimeOrNull(code)) then
                DoNotShowUntil::set(object["uuid"], datetime)
            end
            return [flock, []]
        end

        if expression.start_with?("r:add") then
            command, requirement = expression.split(" ")
            RequirementsOperator::addRequirementToObject(object['uuid'],requirement)
            return [flock, []]
        end

        if expression.start_with?("r:remove") then
            command, requirement = expression.split(" ")
            RequirementsOperator::removeRequirementFromObject(object['uuid'],requirement)
            return [flock, []]
        end

        if expression.size > 0 then
            tokens = expression.split(" ").map{|t| t.strip }
            .each{|command|
                flock, events = TheOperator::agentuuid2FlockObjectCommandProcessor(object["agent-uid"]).call(flock, object, command)
                events.each{|event|
                    EventsLogReadWrite::commitEventToTimeline(event)
                }
            }
        else
            flock, events = TheOperator::agentuuid2FlockObjectCommandProcessor(object["agent-uid"]).call(flock, object, "")
            events.each{|event|
                EventsLogReadWrite::commitEventToTimeline(event)
            }
        end
    end

end
