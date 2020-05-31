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
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/GlobalNavigationNetwork.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::totalOverTimespan(uuid, timespanInSeconds)
    Ping::totalToday(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/TimePods/TimePods.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/Todo.rb"

require_relative "../OpenCycles/OpenCycles.rb"

# ------------------------------------------------------------------------

class NSXCatalystUI

    # NSXCatalystUI::performGeneralNavigationDisplay()
    def self.performGeneralNavigationDisplay()
        loop {
            system("clear")

            items = []

            items << [
                "navigate nodes", 
                lambda { GlobalNavigationNetworkUserInterface::mainNavigation() }
            ]

            items << [
                "navigate cliques", 
                lambda { CliquesNavigation::mainNavigation() }
            ]

            items << nil

            items << [
                "nodes listing", 
                lambda {
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", GlobalNavigationNetworkNodes::nodes(), lambda{|node| GlobalNavigationNetworkNodes::nodeToString(node) })
                    return if node.nil?
                    GlobalNavigationNetworkUserInterface::nodeDive(node)
                }
            ]
            items << [
                "cliques search and visit", 
                lambda { CliquesNavigation::mainNavigation() }
            ]

            items << [
                "cliques listing",
                lambda {
                    clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("cliques", Cliques::cliques(), lambda{|clique| Cliques::cliqueToString(clique) })
                    break if clique.nil?
                    Cliques::cliqueDive(clique)
                }
            ]

            items << [
                "clique visit (uuid)", 
                lambda {
                    uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                    clique = Cliques::getOrNull(uuid)
                    return if clique.nil?
                    Cliques::cliqueDive(clique)
                }
            ]

            items << [
                "PrimaryNetworkMakeAndOrSelectQuest::makeAndOrSelectSomethingOrNull() (test)",
                lambda {
                    selectedEntity = PrimaryNetworkMakeAndOrSelectQuest::makeAndOrSelectSomethingOrNull()
                    puts JSON.pretty_generate([selectedEntity])
                    LucilleCore::pressEnterToContinue()
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

            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # NSXCatalystUI::performOpenCyclesDisplay()
    def self.performOpenCyclesDisplay()
        system("clear")
        loop {
            items = []
            OpenCycles::getOpenCyclesClaims()
                .each{|claim|
                    something = PrimaryNetwork::getSomethingByUuidOrNull(claim["entityuuid"])
                    next if something.nil?
                    items << [
                        PrimaryNetwork::somethingToString(something).yellow, 
                        lambda { PrimaryNetwork::visitSomething(something) }
                    ]
                }
            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # NSXCatalystUI::performAppsDisplay()
    def self.performAppsDisplay()
        loop {
            system("clear")

            items = []

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

            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # NSXCatalystUI::performManagementDisplay()
    def self.performManagementDisplay()
        loop {
            system("clear")

            items = []

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
                "nodes management",
                lambda { GlobalNavigationNetworkUserInterface::management() }
            ]

            items << [
                "nodes listing", 
                lambda {
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", GlobalNavigationNetworkNodes::nodes(), lambda{|node| GlobalNavigationNetworkNodes::nodeToString(node) })
                    return if node.nil?
                    GlobalNavigationNetworkUserInterface::nodeDive(node)
                }
            ]

            items << [
                "cliques management", 
                lambda { Cliques::main() }
            ]

            items << [
                "cliques search and visit", 
                lambda { CliquesNavigation::mainNavigation() }
            ]

            items << [
                "cliques listing",
                lambda {
                    clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("cliques", Cliques::cliques(), lambda{|clique| Cliques::cliqueToString(clique) })
                    break if clique.nil?
                    Cliques::cliqueDive(clique)
                }
            ]

            items << [
                "clique visit (uuid)", 
                lambda {
                    uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                    clique = Cliques::getOrNull(uuid)
                    return if clique.nil?
                    Cliques::cliqueDive(clique)
                }
            ]

            items << [
                "PrimaryNetworkMakeAndOrSelectQuest::makeAndOrSelectSomethingOrNull() (test)",
                lambda {
                    selectedEntity = PrimaryNetworkMakeAndOrSelectQuest::makeAndOrSelectSomethingOrNull()
                    puts JSON.pretty_generate([selectedEntity])
                    LucilleCore::pressEnterToContinue()
                }
            ]

            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # NSXCatalystUI::performLastestCliquesDisplay()
    def self.performLastestCliquesDisplay()
        loop {
            system("clear")
            items = []
            Cliques::cliques()
                .sort{|i1, i2| i1["creationTimestamp"] <=> i2["creationTimestamp"] }
                .last(NSXMiscUtils::screenHeight()-3)
                .each{|item|
                    items << [
                        PrimaryNetwork::somethingToString(item),
                        lambda { PrimaryNetwork::openSomething(item) }
                    ]
                }
            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # NSXCatalystUI::performLatestGlobalNavigationNetworkNodesDisplay()
    def self.performLatestGlobalNavigationNetworkNodesDisplay()
        loop {
            system("clear")
            items = []
            GlobalNavigationNetworkNodes::nodes()
                .sort{|i1, i2| i1["creationTimestamp"] <=> i2["creationTimestamp"] }
                .last(NSXMiscUtils::screenHeight()-3)
                .each{|item|
                    items << [
                        PrimaryNetwork::somethingToString(item),
                        lambda { PrimaryNetwork::openSomething(item) }
                    ]
                }
            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # NSXCatalystUI::operations()
    def self.operations()
        loop {
            system("clear")
            items = []

            items << [
                "General Navigation", 
                lambda { NSXCatalystUI::performGeneralNavigationDisplay() }
            ]
            items << [
                "Latest Global Navigation Network Nodes", 
                lambda { NSXCatalystUI::performLatestGlobalNavigationNetworkNodesDisplay() }
            ]
            items << [
                "Latest Cliques", 
                lambda { NSXCatalystUI::performLastestCliquesDisplay() }
            ]
            items << nil

            items << [
                "A10495 (new) -> { Todo, OpenCycle, Global Navigation Network Node (existing or new) }", 
                lambda {
                    target = A10495::issueNewTargetInteractivelyOrNull()
                    return if target.nil?
                    whereTo = LucilleCore::selectEntityFromListOfEntitiesOrNull("whereTo?", ["Todo", "OpenCycle", "Global Navigation Network Node"])
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
                    if whereTo == "Global Navigation Network Node" then
                        NSXMiscUtils::attachTargetToStarlightNodeExistingOrNew(target)
                    end
                }
            ]

            items << [
                "clique (new) -> { OpenCycle, Global Navigation Network Node (existing or new) }", 
                lambda {
                    clique = Cliques::issueCliqueInteractivelyOrNull(false)
                    return if clique.nil?

                    whereTo = LucilleCore::selectEntityFromListOfEntitiesOrNull("whereTo?", ["OpenCycle", "Global Navigation Network Node"])
                    return if whereTo.nil?
                    if whereTo == "OpenCycle" then
                        claim = {
                            "uuid"              => SecureRandom.uuid,
                            "creationTimestamp" => Time.new.to_f,
                            "entityuuid"        => clique["uuid"]
                        }
                        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles/#{claim["uuid"]}.json", "w"){|f| f.puts(JSON.pretty_generate(claim)) }
                    end
                    if whereTo == "Global Navigation Network Node" then
                        node = GlobalNavigationNetworkMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                        return if node.nil?
                        GlobalNavigationNetworkContents::issueClaimGivenNodeAndEntity(node, clique)
                    end
                }
            ]

            items << [
                "node (existing or new) + build around",
                lambda { NSXMiscUtils::startLightNodeExistingOrNewThenBuildAroundThenReturnNode() }
            ]

            items << [
                "timepod (new)", 
                lambda { 
                    passenger = TimePods::makePassengerInteractivelyOrNull()
                    next if passenger.nil?
                    engine = TimePods::makeEngineInteractivelyOrNull()
                    next if engine.nil?
                    timepod = {
                        "uuid"             => SecureRandom.uuid,
                        "creationUnixtime" => Time.new.to_f,
                        "passenger"        => passenger,
                        "engine"           => engine
                    }
                    puts JSON.pretty_generate(timepod)
                    TimePods::save(timepod)
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
                "Management", 
                lambda { NSXCatalystUI::performManagementDisplay() }
            ]
            items << [
                "Applications", 
                lambda { NSXCatalystUI::performAppsDisplay() }
            ]

            items << nil

            items << [
                "Applications generation speed", 
                lambda { 
                    puts "Applications generation speed report"
                    NSXCatalystObjectsCommon::applicationNames()
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

    # NSXCatalystUI::performStandardDisplay(displayObjects)
    def self.performStandardDisplay(displayObjects)

        displayTime = Time.new.to_f

        system("clear")

        position = 0
        verticalSpaceLeft = NSXMiscUtils::screenHeight()-3
        executors = []

        puts ""
        puts "Diligence (24h): #{(100*Ping::totalOverTimespan("DC9DF253-01B5-4EF8-88B1-CA0250096471", 86400).to_f/86400).round(2)}%".green
        verticalSpaceLeft = verticalSpaceLeft - 2

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

        if NSXMiscUtils::isInteger(command) then
            position = command.to_i
            executors[position].call()
            return
        end

        if command == "/" then
            NSXCatalystUI::operations()
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
            DataIntegrityOfficer::interfaceLoopOperations()

            # Displays
            objects = NSXCatalystObjectsOperator::getCatalystListingObjectsOrderedFast()
            NSXCatalystUI::performStandardDisplay(objects)
        }
    end
end


