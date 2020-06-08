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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/MiningShips/MiningShips.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/Asteroids.rb"

require_relative "../OpenCycles/OpenCycles.rb"

# ------------------------------------------------------------------------

class NSXCatalystUI

    # NSXCatalystUI::operations()
    def self.operations()
        loop {
            system("clear")

            items = []

            items << [
                "general search", 
                lambda { NSXGeneralSearch::searchAndDive() }
            ]

            items << [
                "starlight navigation", 
                lambda { StarlightUserInterface::navigation() }
            ]

            items << [
                "orbitals listing and selection", 
                lambda { StarlightUserInterface::listingAndSelection() }
            ]

            items << [
                "cubes listing and selection", 
                lambda { CubeUserInterface::listingAndSelection() }
            ]

            items << nil

            items << [
                "QuarksCubesAndOrbitalsMakeAndOrSelectQuest::makeAndOrSelectSomethingOrNull() (test)",
                lambda {
                    selectedEntity = QuarksCubesAndOrbitalsMakeAndOrSelectQuest::makeAndOrSelectSomethingOrNull()
                    puts JSON.pretty_generate([selectedEntity])
                    LucilleCore::pressEnterToContinue()
                }
            ]

            items << nil

            items << [
                "arrow (description)", 
                lambda {
                    description = LucilleCore::askQuestionAnswerAsString("arrow description: ")
                    cargo = {
                        "type"        => "description",
                        "description" => description
                    }

                    lengthInDays = LucilleCore::askQuestionAnswerAsString("arrow length in days: ").to_f
                    engine = {
                        "type"          => "arrow",
                        "startunixtime" => Time.new.to_f,
                        "lengthInDays"  => lengthInDays
                    }

                    miningship = MiningShips::issue(cargo, engine)
                    puts JSON.pretty_generate(miningship)
                    LucilleCore::pressEnterToContinue()
                }
            ]

            items << [
                "arrow (with new quark)", 
                lambda {
                    cargo = MiningShips::makeCargoInteractivelyOrNull()
                    next if cargo.nil?

                    lengthInDays = LucilleCore::askQuestionAnswerAsString("arrow length in days: ").to_f
                    engine = {
                        "type"          => "arrow",
                        "startunixtime" => Time.new.to_f,
                        "lengthInDays"  => lengthInDays
                    }

                    miningship = MiningShips::issue(cargo, engine)
                    puts JSON.pretty_generate(miningship)
                    LucilleCore::pressEnterToContinue()
                }
            ]

            items << [
                "miningship (new)", 
                lambda { 
                    cargo = MiningShips::makeCargoInteractivelyOrNull()
                    next if cargo.nil?
                    engine = MiningShips::makeEngineInteractivelyOrNull()
                    next if engine.nil?
                    miningship = MiningShips::issue(cargo, engine)
                    puts JSON.pretty_generate(miningship)
                    LucilleCore::pressEnterToContinue()
                }
            ]

            items << [
                "asteroid (with new quark)", 
                lambda {
                    target = Quark::issueNewQuarkInteractivelyOrNull()
                    return if target.nil?
                    orbitalname = Asteroids::selectOrbitalNameInteractivelyOrNull()
                    orbitaluuid = nil
                    if orbitalname.nil? then
                        orbitalname = LucilleCore::askQuestionAnswerAsString("project name: ")
                        orbitaluuid = SecureRandom.uuid
                    else
                        orbitaluuid = Asteroids::orbitalName2orbitalUuidOrNUll(orbitalname)
                        return if orbitaluuid.nil?
                    end
                    description = LucilleCore::askQuestionAnswerAsString("asteroid description: ")
                    asteroid = Asteroids::issueNew(orbitalname, orbitaluuid, description, target)
                    puts JSON.pretty_generate(asteroid)
                    LucilleCore::pressEnterToContinue()
                }
            ]


            items << [
                "opencycle (with new quark)", 
                lambda {
                    quark = Quark::issueNewQuarkInteractivelyOrNull()
                    return if quark.nil?
                    opencycle = OpenCycles::issueFromQuark(quark)
                    puts JSON.pretty_generate(opencycle)
                    LucilleCore::pressEnterToContinue()
                }
            ]

            items << [
                "opencycle (new with existing cube)", 
                lambda {
                    cube = Cube::selectCubeFromExistingOrNull()
                    return if cube.nil?
                    opencycle = OpenCycles::issueFromCube(cube)
                    puts JSON.pretty_generate(opencycle)
                    LucilleCore::pressEnterToContinue()
                }
            ]

            items << nil

            items << [
                "new quark ; attached to new cube ; attached to starlight orbital (existing or new)", 
                lambda {
                    quark = Quark::issueNewQuarkInteractivelyOrNull()
                    return if quark.nil?
                    description = LucilleCore::askQuestionAnswerAsString("cube description: ")
                    cube = Cube::issueCube_v2(description, quark)
                    orbital = StarlightUserInterface::selectOrbitalFromExistingOrCreateOneOrNull()
                    return if orbital.nil?
                    OrbitalInventory::issueClaim(orbital, cube)
                }
            ]

            items << [
                "starlight orbital (existing or new) + build around",
                lambda { NSXMiscUtils::startLightNodeExistingOrNewThenBuildAroundThenReturnNode() }
            ]

            items << nil

            items << [
                "MiningShips", 
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/MiningShips/miningships") }
            ]
            items << [
                "Asteroids", 
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/asteroids") }
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
                        .each{|object| NSXDisplayUtils::makeDisplayStringForCatalystListing(object, true, 1) } # All in focus at position 1
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

    # NSXCatalystUI::performAllDisplay(displayObjects)
    def self.performAllDisplay(displayObjects)

        system("clear")

        position = 0
        executors = []

        puts ""

        displayObjects.each_with_index{|object, indx|
            break if object.nil?
            displayStr = NSXDisplayUtils::makeDisplayStringForCatalystListing(object, indx == 0, position)
            puts displayStr
            executors[position] = lambda { NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object) }
            position = position + 1
            break if displayObjects[indx+1].nil?
        }

        puts ""
        print "[*] --> "
        command = STDIN.gets().strip
        if command=='' then
            return
        end

        if NSXMiscUtils::isInteger(command) then
            position = command.to_i
            executors[position].call()
            return
        end

        NSXGeneralCommandHandler::processCatalystCommandManager(displayObjects[0], command)
    end

    # NSXCatalystUI::performStandardDisplay(displayObjects)
    def self.performStandardDisplay(displayObjects)

        system("clear")

        position = 0
        verticalSpaceLeft = NSXMiscUtils::screenHeight()-3
        executors = []

        opencycles = OpenCycles::opencycles()
            .sort{|i1, i2| i1["creationUnixtime"] <=> i2["creationUnixtime"] }
        if !opencycles.empty? then
            puts ""
            verticalSpaceLeft = verticalSpaceLeft - 1
            opencycles
                .each{|opencycle|
                    puts "[ #{"%2d" % position}] #{OpenCycles::opencycleToString(opencycle).yellow}"
                    executors[position] = lambda { 
                        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["visit target", "destroy open cycle"])
                        return if operation.nil?
                        if operation == "visit target" then
                            entity = QuarksCubesAndOrbitals::getObjectByUuidOrNull(opencycle["targetuuid"])
                            if entity.nil? then
                                puts "I could not find a target for this open cycle"
                                LucilleCore::pressEnterToContinue()
                                return
                            end
                            QuarksCubesAndOrbitals::objectDive(entity)
                        end
                        if operation == "destroy open cycle" then
                            Nyx::destroy(opencycle["uuid"])
                        end
                    }
                    position = position + 1
                    verticalSpaceLeft = verticalSpaceLeft - 1
                }
        end

        calendarreport = `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/calendar-report`.strip
        if calendarreport.size > 0 then
            puts ""
            puts calendarreport
            verticalSpaceLeft = verticalSpaceLeft - ( calendarreport.lines.to_a.size + 1 )
        end

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        displayObjects.each_with_index{|object, indx|
            break if object.nil?
            break if verticalSpaceLeft <= 0
            displayStr = NSXDisplayUtils::makeDisplayStringForCatalystListing(object, indx == 0, position)
            puts displayStr
            executors[position] = lambda { NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object) }
            verticalSpaceLeft = verticalSpaceLeft - NSXDisplayUtils::verticalSize(displayStr)
            position = position + 1
            break if displayObjects[indx+1].nil?
            break if ( verticalSpaceLeft - NSXDisplayUtils::verticalSize(NSXDisplayUtils::makeDisplayStringForCatalystListing(displayObjects[indx+1], indx == 0, position)) ) < 0
        }

        puts ""
        print "--> "
        command = STDIN.gets().strip
        if command=='' then
            return
        end

        if command == '*' then
            objects = NSXCatalystObjectsOperator::getAllCatalystObjectsOrdered()
            NSXCatalystUI::performAllDisplay(objects)
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


