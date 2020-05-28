# encoding: UTF-8

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/A10495.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Multiverse.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::total24hours(uuid)
    Ping::totalToday(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/TimePods/TimePods.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/Todo.rb"

require_relative "../OpenCycles/OpenCycles.rb"

# ------------------------------------------------------------------------

class NSXCatalystUI

    # NSXCatalystUI::performBackopsDisplay()
    def self.performBackopsDisplay()
        loop {
            system("clear")

            items = []

            items << [
                "starlight management",
                lambda { Multiverse::management() }
            ]

            items << [
                "starlight nodes listing", 
                lambda {
                    puts "Latest Starlight Nodes"
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("starlight node", Timelines::timelines(), lambda{|node| Timelines::timelineToString(node) })
                    return if node.nil?
                    Multiverse::visitTimeline(node)
                }
            ]

            items << [
                "starlight node (existing or new) + build around",
                lambda { NSXMiscUtils::startLightNodeExistingOrNewThenBuildAroundThenReturnNode() }
            ]

            items << [
                "cliques listing",
                lambda {
                    puts "Latest Cliques"
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("data points", Cliques::cliques(), lambda{|clique| Cliques::cliqueToString(clique) })
                    break if node.nil?
                    Multiverse::visitTimeline(node)
                }
            ]

            items << [
                "clique visit (uuid)", 
                lambda {
                    uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                    clique = Cliques::getOrNull(uuid)
                    return if clique.nil?
                    CliquesEvolved::navigateClique(clique)
                }
            ]

            items << [
                "clique (new) -> { OpenCycle, Starlight Node (existing or new) }", 
                lambda {
                    clique = Cliques::issueCliqueInteractivelyOrNull(false)
                    return if clique.nil?

                    whereTo = LucilleCore::selectEntityFromListOfEntitiesOrNull("whereTo?", ["OpenCycle", "Starlight Node"])
                    return if whereTo.nil?
                    if whereTo == "OpenCycle" then
                        claim = {
                            "uuid"              => SecureRandom.uuid,
                            "creationTimestamp" => Time.new.to_f,
                            "entityuuid"        => clique["uuid"]
                        }
                        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles/#{claim["uuid"]}.json", "w"){|f| f.puts(JSON.pretty_generate(claim)) }
                    end
                    if whereTo == "Starlight Node" then
                        node = Multiverse::selectOrNull()
                        return if node.nil?
                        TimelineOwnership::issueClaimGivenTimelineAndEntity(node, clique)
                    end
                }
            ]

            items << [
                "EvolutionsFindX::navigate()", 
                lambda {
                    EvolutionsFindX::navigate()
                }
            ]

            items << [
                "EvolutionsFindX::selectOrNull() (test)", 
                lambda {
                    selectedEntity = EvolutionsFindX::selectOrNull()
                    puts JSON.pretty_generate([selectedEntity])
                    LucilleCore::pressEnterToContinue()
                }
            ]

            items << [
                "standard target (new) -> { Todo, OpenCycle, Starlight Node (existing or new) }", 
                lambda {
                    target = A10495::issueNewTargetInteractivelyOrNull()
                    return if target.nil?
                    whereTo = LucilleCore::selectEntityFromListOfEntitiesOrNull("whereTo?", ["Todo", "OpenCycle", "Starlight Node"])
                    return if whereTo.nil?
                    if whereTo == "Todo" then
                        projectname = Items::selectProjectNameInteractivelyOrNull()
                        projectuuid = nil
                        if projectname.nil? then
                            projectname = LucilleCore::askQuestionAnswerAsString("project name: ")
                            projectuuid = SecureRandom.uuid
                        else
                            projectuuid = Items::projectname2projectuuidOrNUll(projectname)
                            return if projectuuid.nil?
                        end
                        description = LucilleCore::askQuestionAnswerAsString("todo item description: ")
                        Items::issueNewItem(projectname, projectuuid, description, target)
                    end
                    if whereTo == "OpenCycle" then
                        claim = {
                            "uuid"              => SecureRandom.uuid,
                            "creationTimestamp" => Time.new.to_f,
                            "entityuuid"        => target["uuid"]
                        }
                        OpenCycles::saveClaim(claim)
                    end
                    if whereTo == "Starlight Node" then
                        NSXMiscUtils::attachTargetToStarlightNodeExistingOrNew(target)
                    end
                }
            ]

            items << nil

            items << [
                "TimePods", 
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/TimePods/timepods") }
            ]

            items << [
                "Todo", 
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/todo") }
            ]

            items << [
                "OpenCycles", 
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/opencycles") }
            ]

            items << [
                "Calendar", 
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/calendar") }
            ]

            items << [
                "Wave", 
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/wave") }
            ]

            items << nil

            items << [
                "Applications generation speed", 
                lambda { 
                    puts "Applications generation speed report"
                    NSXCatalystObjectsOperator::applicationNames()
                        .map{|appname| "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/#{appname}/x-catalyst-objects" }
                        .map{|source|
                            t1 = Time.new.to_f
                            JSON.parse(`#{source}`)
                            t2 = Time.new.to_f
                            {
                                "source" => source,
                                "timespan" => t2-t1 
                            }
                        }
                        .sort{|o1, o2| o1["timespan"]<=>o2["timespan"] }
                        .reverse
                        .each{|object|
                            puts "    - #{object["source"]}: #{"%.3f" % object["timespan"]}"
                        }
                    LucilleCore::pressEnterToContinue()
                }
            ]

            items << [
                "UI generation speed", 
                lambda { 
                    t1 = Time.new.to_f
                    NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
                        .each{|object| NSXDisplayUtils::objectDisplayStringForCatalystListing(object, true, 1) } # All in focus at position 1
                    t2 = Time.new.to_f
                    puts "UI generation speed: #{(t2-t1).round(3)} seconds"
                    LucilleCore::pressEnterToContinue()
                }
            ]

            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # NSXCatalystUI::performDataDisplay()
    def self.performDataDisplay()
        loop {
            system("clear")

            items = []

            OpenCycles::getOpenCyclesClaims()
                .each{|claim|
                    dataentity = DataEntities::getDataEntityByUuidOrNull(claim["entityuuid"])
                    next if dataentity.nil?
                    items << [ 
                        DataEntities::dataEntityToString(dataentity).yellow,
                        lambda { OpenCycles::openClaimTarget(claim) }
                    ]
                }

            items << nil

            NSXMiscUtils::cliquesAndStarlightNodes()
                .last(20)
                .each{|item|
                    items << [
                        DataEntities::dataEntityToString(item),
                        lambda { DataEntities::visitDataEntity(item) }
                    ]
                }

            items << nil

            items << [
                "TimePods", 
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/TimePods/timepods") }
            ]

            items << [
                "Todo", 
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/todo") }
            ]

            items << [
                "OpenCycles", 
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/opencycles") }
            ]

            items << [
                "Calendar", 
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/calendar") }
            ]

            items << [
                "Wave", 
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/wave") }
            ]

            items << [
                "EvolutionsFindX::navigate()",
                lambda { EvolutionsFindX::navigate() }
            ]

            items << nil

            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # NSXCatalystUI::performStandardDisplay(displayObjects)
    def self.performStandardDisplay(displayObjects)

        displayTime = Time.new.to_f

        system("clear")

        position = 0
        verticalSpaceLeft = NSXMiscUtils::screenHeight()-3

        puts ""
        puts "Diligence (24h): #{(100*Ping::total24hours("DC9DF253-01B5-4EF8-88B1-CA0250096471").to_f/86400).round(2)}%".green
        verticalSpaceLeft = verticalSpaceLeft - 2

        executors = []

        calendarreport = `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/calendar-report`.strip
        if calendarreport.size > 0 and (calendarreport.lines.to_a.size + 2) < verticalSpaceLeft then
            puts ""
            puts calendarreport
            verticalSpaceLeft = verticalSpaceLeft - ( calendarreport.lines.to_a.size + 1 )
        end

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        displayObjects.each_with_index{|object, indx|
            break if object.nil?
            break if verticalSpaceLeft <= 0
            displayStr = NSXDisplayUtils::objectDisplayStringForCatalystListing(object, indx==0, position)
            puts displayStr
            executors[position] = lambda { NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object) }
            verticalSpaceLeft = verticalSpaceLeft - NSXDisplayUtils::verticalSize(displayStr)
            position = position + 1
            break if displayObjects[indx+1].nil?
            break if ( verticalSpaceLeft - NSXDisplayUtils::verticalSize(NSXDisplayUtils::objectDisplayStringForCatalystListing(displayObjects[indx+1], indx==0, position)) ) < 0
        }

        puts ""
        print "--> "
        command = STDIN.gets().strip
        if command=='' then
            return
        end

        if command[0,1] == "'" and  NSXMiscUtils::isInteger(command[1,999]) then
            position = command[1,999].to_i
            executors[position].call()
            return
        end

        if command == "/" then
            items = []
            items << [
                "Data", 
                lambda { NSXCatalystUI::performDataDisplay() }
            ]
            items << [
                "Backops", 
                lambda { NSXCatalystUI::performBackopsDisplay() }
            ]
            LucilleCore::menuItemsWithLambdas(items)
            return
        end

        NSXGeneralCommandHandler::processCatalystCommandManager(displayObjects[0], command)
    end

    # NSXCatalystUI::standardUILoop()
    def self.standardUILoop()
        loop {
            if STARTING_CODE_HASH != NSXEstateServices::locationHashRecursively(CATALYST_CODE_FOLDERPATH) then
                puts "Code change detected. Exiting."
                return
            end

            # Some Admin
            NSXMiscUtils::importFromLucilleInbox()
            NSXCuration::curation()

            # Displays
            objects = NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
            NSXCatalystUI::performStandardDisplay(objects)
        }
    end
end


