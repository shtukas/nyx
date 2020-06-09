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
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cubes.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Timelines.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::totalOverTimespan(uuid, timespanInSeconds)
    Ping::totalToday(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Spaceships/Spaceships.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/Asteroids.rb"

require_relative "../OpenCycles/OpenCycles.rb"

# ------------------------------------------------------------------------

class NSXCatalystUI

    # NSXCatalystUI::objectFocus(object)
    def self.objectFocus(object)
        return if object.nil?
        loop { 
            puts NSXDisplayUtils::makeDisplayStringForCatalystListing(object)
            puts NSXDisplayUtils::makeInferfaceString(object)
            print "--> "
            command = STDIN.gets().strip
            return if command == ''
            if command == '..' and object["defaultCommand"] then
                command = object["defaultCommand"]
            end
            NSXGeneralCommandHandler::processCatalystCommandManager(object, command)
        }
    end

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
                "timelines listing and selection", 
                lambda { Timelines::selectFromExistingTimelinesAndDive() }
            ]

            items << [
                "cubes listing and selection", 
                lambda { Cubes::selectFromExistingCubedAndDive() }
            ]

            items << [
                "tags listing and selection", 
                lambda { Cubes::tagsThenCubesThenCubeThenDive() }
            ]

            items << nil

            items << [
                "asteroid (with new quark)", 
                lambda {
                    target = Quark::issueNewQuarkInteractivelyOrNull()
                    return if target.nil?
                    orbitalname = Asteroids::selectTimelineNameInteractivelyOrNull()
                    orbitaluuid = nil
                    if orbitalname.nil? then
                        orbitalname = LucilleCore::askQuestionAnswerAsString("orbinal name: ")
                        orbitaluuid = SecureRandom.uuid
                    else
                        orbitaluuid = Asteroids::timelineName2timelineUuidOrNUll(orbitalname)
                        return if orbitaluuid.nil?
                    end
                    description = LucilleCore::askQuestionAnswerAsString("asteroid description: ")
                    asteroid = Asteroids::issueNew(orbitalname, orbitaluuid, description, target)
                    puts JSON.pretty_generate(asteroid)
                    LucilleCore::pressEnterToContinue()
                }
            ]

            items << [
                "spaceship (new)", 
                lambda { 
                    cargo = Spaceships::makeCargoInteractivelyOrNull()
                    next if cargo.nil?
                    engine = Spaceships::makeEngineInteractivelyOrNull()
                    next if engine.nil?
                    spaceship = Spaceships::issue(cargo, engine)
                    puts JSON.pretty_generate(spaceship)
                    LucilleCore::pressEnterToContinue()
                }
            ]

            items << nil

            items << [
                "quark (new) ; attached to new cube ; attached to timeline (existing or new)", 
                lambda {
                    quark = Quark::issueNewQuarkInteractivelyOrNull()
                    return if quark.nil?
                    description = LucilleCore::askQuestionAnswerAsString("cube description: ")
                    cube = Cubes::issueCube_v2(description, quark)
                    timeline = Timelines::selectTimelineFromExistingOrCreateOneOrNull()
                    return if timeline.nil?
                    TimelineContent::issueClaim(timeline, cube)
                }
            ]

            items << nil

            items << [
                "Spaceships", 
                lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Spaceships/spaceships") }
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
                    NSXCatalystObjectsCommon::catalystObjectsApplicationNames()
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

        # --------------------------------------------------------------------------
        # Starship Management

        # Guardian Work
        DailyTimes::putTimeToBankNoOftenThanOnceADay("5c81927e-c4fb-4f8d-adae-228c346c8c7d", -6*3600, [1, 2, 3, 4, 5]) # 6 hours, Monday to Friday

        # Spaceship bank managed
        Spaceships::spaceships()
            .select{|spaceship| ["bank-account"].include?(spaceship["engine"]["type"]) }
            .sort{|i1, i2| i1["creationUnixtime"] <=> i2["creationUnixtime"] }
            .first(3)
            .each{|spaceship|
                DailyTimes::putTimeToBankNoOftenThanOnceADay(spaceship["uuid"], -(2.to_f/3)*3600, [1, 2, 3, 4, 5, 6])
            }

        # --------------------------------------------------------------------------

        system("clear")

        executors = [] # Array([ announce, isFocus, isRunning, lambda ])

        opencycles = OpenCycles::opencycles()
            .sort{|i1, i2| i1["creationUnixtime"] <=> i2["creationUnixtime"] }
            .each{|opencycle|
                executors << [
                    OpenCycles::opencycleToString(opencycle).yellow,
                    false,
                    false,
                    lambda { 
                        entity = Nyx::getOrNull(opencycle["targetuuid"])
                        if entity.nil? then
                            puts "I could not find a target for this open cycle"
                            LucilleCore::pressEnterToContinue()
                            return
                        end
                        CubesAndTimelines::objectDive(entity)
                    }
                ]
            }

        calendarreport = `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/calendar-report`.strip
        if calendarreport.size > 0 then
            executors << [
                calendarreport,
                false,
                false,
                lambda {}
            ]
        end

        displayMatrix = {}
        displayMatrix["battlefield"] = (Time.new.min >= 15) or Spaceships::spaceships().any?{|spaceship| Runner::isRunning(spaceship["uuid"])}
        displayMatrix["standard"] = true

        # --------------------------------------------------------------------------
        # Starship Display

        if displayMatrix["battlefield"] then

            spaceships = Spaceships::spaceships()
                .sort{|s1, s2| Spaceships::metric(s1) <=> Spaceships::metric(s2) }
                .reverse

            selectSpaceShips = lambda{|selected, awaiting|
                return selected if awaiting.empty?
                if awaiting.any?{|spaceship| Runner::isRunning(spaceship["uuid"]) } then
                    selected << awaiting.shift
                    return selectSpaceShips.call(selected, awaiting)
                end
                if selected.size >= 10 then
                    return selected
                end
                selected << awaiting.shift
                selectSpaceShips.call(selected, awaiting)
            }

            selectSpaceShips.call([], spaceships)
                .each_with_index{|spaceship, indx|
                    announce = Spaceships::toString(spaceship)
                    if Runner::isRunning(spaceship["uuid"]) then
                        announce = announce.green
                    else
                        announce = announce.red
                    end
                    executors << [
                        announce,
                        Spaceships::isLate?(spaceship),
                        Runner::isRunning(spaceship["uuid"]),
                        lambda { 
                            loop {
                                puts Spaceships::toString(spaceship)
                                options = ["start", "open", "stop", "dive", "destroy"]
                                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
                                return if option.nil?
                                if option == "start" then
                                    Spaceships::startSpaceship(spaceship["uuid"])
                                    if spaceship["cargo"]["type"] == "quark"
                                        if spaceship["description"].nil? then
                                            spaceship["description"] = LucilleCore::askQuestionAnswerAsString("starship description: ")
                                            Nyx::commitToDisk(spaceship)
                                        end
                                    end
                                end
                                if option == "open" then
                                    Spaceships::openCargo(spaceship["uuid"])
                                end
                                if option == "stop" then
                                    Spaceships::stopSpaceship(spaceship)
                                end
                                if option == "dive" then
                                    Spaceships::spaceshipDive(spaceship)
                                end
                                if option == "destroy" then
                                    if spaceship["uuid"] == "5c81927e-c4fb-4f8d-adae-228c346c8c7d" then
                                        puts "You cannot destroy this one (Guardian Work)"
                                        LucilleCore::pressEnterToContinue()
                                        return
                                    end
                                    Spaceships::stopSpaceship(spaceship)
                                    Nyx::destroy(spaceship["uuid"])
                                end
                            }
                        }

                    ]
                }
        else
            executors << [
                "Battlefield in standby",
                false,
                false,
                lambda {}
            ]
        end

        # --------------------------------------------------------------------------
        # Regular Items

        if displayMatrix["standard"] then
            displayObjects.each_with_index{|object, indx|
                break if object.nil?
                executors << [
                    NSXDisplayUtils::makeDisplayStringForCatalystListing(object),
                    indx == 0,
                    object["isRunning"],
                    lambda { NSXCatalystUI::objectFocus(object) }
                ]
            }
        end

        # --------------------------------------------------------------------------
        # Print

        verticalSpaceLeft = NSXMiscUtils::screenHeight()-3
        itemsForDisplay = executors.map{|item| item.clone }
        puts ""
        position = -1
        loop {
            position = position + 1
            item = itemsForDisplay.shift
            prefix = item[1] ? "[*#{"%2d" % position}]" : "[ #{"%2d" % position}]"
            str = "#{prefix} #{item[0]}"
            puts str
            verticalSpaceLeft = verticalSpaceLeft - NSXDisplayUtils::verticalSize(str)
            next if itemsForDisplay.any?{|item| item[2] }
            break if verticalSpaceLeft < 2
        }

        # --------------------------------------------------------------------------
        # Prompt

        puts ""
        print "--> "
        command = STDIN.gets().strip
        if command=='' then
            item = executors.select{|item| item[1]}.first
            return if item.nil?
            item[3].call()
            return
        end

        if NSXMiscUtils::isInteger(command) then
            position = command.to_i
            return if executors[position].nil?
            executors[position][3].call()
            return
        end

        if command == "/" then
            NSXCatalystUI::operations()
            return
        end
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


