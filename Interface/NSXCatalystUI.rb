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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Quark.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cube.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

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

    # NSXCatalystUI::operations()
    def self.operations()
        loop {
            system("clear")

            items = []

            items << [
                "nodes listing", 
                lambda {
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", StarlightNodes::nodes(), lambda{|node| StarlightNodes::nodeToString(node) })
                    return if node.nil?
                    StarlightUserInterface::nodeDive(node)
                }
            ]

            items << [
                "cubes listing",
                lambda {
                    cube = LucilleCore::selectEntityFromListOfEntitiesOrNull("cubes", Cube::cubes(), lambda{|cube| Cube::cubeToString(cube) })
                    break if cube.nil?
                    Cube::cubeDive(cube)
                }
            ]

            items << nil

            items << [
                "navigate nodes", 
                lambda { StarlightUserInterface::navigation() }
            ]

            items << [
                "navigate cubes", 
                lambda { CubesNavigation::navigation() }
            ]

            items << nil

            items << [
                "cube visit (uuid)", 
                lambda {
                    uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                    cube = Nyx::getOrNull(uuid)
                    return if cube.nil?
                    Cube::cubeDive(cube)
                }
            ]

            items << nil

            items << [
                "QuarksCubesAndStarlightNodesMakeAndOrSelectQuest::makeAndOrSelectSomethingOrNull() (test)",
                lambda {
                    selectedEntity = QuarksCubesAndStarlightNodesMakeAndOrSelectQuest::makeAndOrSelectSomethingOrNull()
                    puts JSON.pretty_generate([selectedEntity])
                    LucilleCore::pressEnterToContinue()
                }
            ]

            items << nil

            items << [
                "arrow (description only)", 
                lambda {
                    arrow = {
                        "uuid"          => SecureRandom.uuid,
                        "description"   => LucilleCore::askQuestionAnswerAsString("description: "),
                        "startunixtime" => Time.new.to_i,
                        "lengthInDays"  => LucilleCore::askQuestionAnswerAsString("length in days: ").to_f,
                        "quarkuuid"     => nil
                    }
                    puts JSON.pretty_generate(arrow)
                    BTreeSets::set("/Users/pascal/Galaxy/DataBank/Catalyst/Arrows", "", arrow["uuid"], arrow)
                }
            ]

            items << [
                "arrow (with new quark)", 
                lambda {
                    quark = Quark::issueNewQuarkInteractivelyOrNull()
                    return if quark.nil?
                    arrow = {
                        "uuid"          => SecureRandom.uuid,
                        "description"   => LucilleCore::askQuestionAnswerAsString("description: "),
                        "startunixtime" => Time.new.to_i,
                        "lengthInDays"  => LucilleCore::askQuestionAnswerAsString("length in days: ").to_f,
                        "quarkuuid"     => quark["uuid"]
                    }
                    puts JSON.pretty_generate(arrow)
                    BTreeSets::set("/Users/pascal/Galaxy/DataBank/Catalyst/Arrows", "", arrow["uuid"], arrow)
                }
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
                        "nyxType"          => "timepod-99a06996-dcad-49f5-a0ce-02365629e4fc",
                        "creationUnixtime" => Time.new.to_f,
                        "passenger"        => passenger,
                        "engine"           => engine
                    }
                    puts JSON.pretty_generate(timepod)
                    Nyx::commitToDisk(timepod)
                }
            ]

            items << [
                "todo item (with new quark)", 
                lambda {
                    target = Quark::issueNewQuarkInteractivelyOrNull()
                    return if target.nil?
                    projectname = Todo::selectProjectNameInteractivelyOrNull()
                    projectuuid = nil
                    if projectname.nil? then
                        projectname = LucilleCore::askQuestionAnswerAsString("project name: ")
                        projectuuid = SecureRandom.uuid
                    else
                        projectuuid = Todo::projectname2projectuuidOrNUll(projectname)
                        return if projectuuid.nil?
                    end
                    description = LucilleCore::askQuestionAnswerAsString("todo item description: ")
                    Todo::issueNewItem(projectname, projectuuid, description, target)
                }
            ]


            items << [
                "opencycle (with new quark)", 
                lambda {
                    quark = Quark::issueNewQuarkInteractivelyOrNull()
                    return if quark.nil?
                    opencycle = {
                        "uuid"             => SecureRandom.uuid,
                        "nyxType"          => "open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f",
                        "creationUnixtime" => Time.new.to_f,
                        "targetuuid"       => quark["uuid"]
                    }
                    Nyx::commitToDisk(opencycle)
                }
            ]

            items << [
                "opencycle (new with existing cube)", 
                lambda {
                    cube = Cube::selectCubeFromExistingOrNull()
                    return if cube.nil?
                    opencycle = {
                        "uuid"             => SecureRandom.uuid,
                        "nyxType"          => "open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f",
                        "creationUnixtime" => Time.new.to_f,
                        "targetuuid"       => cube["uuid"]
                    }
                    Nyx::commitToDisk(opencycle)
                }
            ]

            items << nil

            items << [
                "new quark ; attached to starlight node (existing or new)", 
                lambda {
                    quark = Quark::issueNewQuarkInteractivelyOrNull()
                    return if quark.nil?
                    NSXMiscUtils::attachTargetToStarlightNodeExistingOrNew(quark)
                }
            ]

            items << [
                "new quark ; attached to new cube ; attached to starlight node (existing or new)", 
                lambda {
                    quark = Quark::issueNewQuarkInteractivelyOrNull()
                    return if quark.nil?
                    description = LucilleCore::askQuestionAnswerAsString("cube description: ")
                    cube = Cube::issueCube_v2(description, quark)
                    starlightnode = StarlightUserInterface::selectNodeFromExistingOrCreateOneOrNull()
                    return if starlightnode.nil?
                    StarlightContents::issueClaimGivenNodeAndEntity(starlightnode, cube)
                }
            ]

            items << [
                "starlight node (existing or new) + build around",
                lambda { NSXMiscUtils::startLightNodeExistingOrNewThenBuildAroundThenReturnNode() }
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
            items << [
                "Run Data Integrity Check", 
                lambda { 
                    CatalystFsck::run()
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

        opencycles = OpenCycles::opencycles()
            .sort{|i1, i2| i1["creationUnixtime"] <=> i2["creationUnixtime"] }
        verticalSpaceLeft = verticalSpaceLeft - (opencycles.size + 1) # space and opencycles

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
            displayStr = NSXDisplayUtils::objectDisplayStringForCatalystListing(object, indx == 0, position)
            puts displayStr
            executors[position] = lambda { NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object) }
            verticalSpaceLeft = verticalSpaceLeft - NSXDisplayUtils::verticalSize(displayStr)
            position = position + 1
            break if displayObjects[indx+1].nil?
            break if ( verticalSpaceLeft - NSXDisplayUtils::verticalSize(NSXDisplayUtils::objectDisplayStringForCatalystListing(displayObjects[indx+1], indx == 0, position)) ) < 0
        }


        puts ""
        opencycles
            .each{|opencycle|
                puts "[ #{"%2d" % position}] #{OpenCycles::opencycleToString(opencycle).yellow}"
                executors[position] = lambda { 
                    operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["visit target", "destroy open cycle"])
                    return if operation.nil?
                    if operation == "visit target" then
                        entity = QuarksCubesAndStarlightNodes::getObjectByUuidOrNull(opencycle["targetuuid"])
                        if entity.nil? then
                            puts "I could not find a target for this open cycle"
                            LucilleCore::pressEnterToContinue()
                            return
                        end
                        QuarksCubesAndStarlightNodes::objectDive(entity)
                    end
                    if operation == "destroy open cycle" then
                        Nyx::destroy(opencycle["uuid"])
                    end
                }
                position = position + 1
            }

        cubes = Cube::cubes()
            .sort{|i1, i2| i1["creationUnixtime"] <=> i2["creationUnixtime"] }

        if verticalSpaceLeft > 0 then
            puts ""
            verticalSpaceLeft = verticalSpaceLeft - 1
            cubes
                .last( [cubes.size, verticalSpaceLeft].min )
                .each{|item|
                    puts "[ #{"%2d" % position}] #{QuarksCubesAndStarlightNodes::objectToString(item).yellow}"
                    executors[position] = lambda { 
                        QuarksCubesAndStarlightNodes::openObject(item)
                    }
                    position = position + 1
                    verticalSpaceLeft = verticalSpaceLeft - 1
                }
        end

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

            # Displays
            objects = NSXCatalystObjectsOperator::getCatalystListingObjectsOrderedFast()
            NSXCatalystUI::performStandardDisplay(objects)
        }
    end
end


