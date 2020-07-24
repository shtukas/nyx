
# encoding: UTF-8

class NSDataType1

    # NSDataType1::issue()
    def self.issue()
        object = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "c18e8093-63d6-4072-8827-14f238975d04",
            "unixtime" => Time.new.to_f
        }
        NyxObjects::put(object)
        object
    end

    # NSDataType1::cubes()
    def self.cubes()
        NyxObjects::getSet("c18e8093-63d6-4072-8827-14f238975d04")
    end

    # NSDataType1::getCubeOrNull(uuid)
    def self.getCubeOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataType1::cubeToString(ns1)
    def self.cubeToString(ns1)
        cacheKey = "645001e0-dec2-4e7a-b113-5c5e93ec0e68:#{Miscellaneous::today()}:#{ns1["uuid"]}"
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return str if str

        ns0s = NSDataType1::cubeToFramesInTimeOrder(ns1)
        description = DescriptionZ::getLastDescriptionForSourceOrNull(ns1)
        if description and ns0s.size > 0 then
            str = "[cube] [#{ns1["uuid"][0, 4]}] [#{ns0s.last["type"]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description and ns0s.size == 0 then
            str = "[cube] [#{ns1["uuid"][0, 4]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description.nil? and ns0s.size > 0 then
            str = "[cube] [#{ns1["uuid"][0, 4]}] #{NSDataType0s::frameToString(ns0s.last)}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description.nil? and ns0s.size == 0 then
            str = "[cube] [#{ns1["uuid"][0, 4]}] no description and no frame"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        "[cube] [#{ns1["uuid"][0, 4]}] [error: 752a3db2 ; pathological cube: #{ns1["uuid"]}]"
    end

    # NSDataType1::cubeToFramesInTimeOrder(ns1)
    def self.cubeToFramesInTimeOrder(ns1)
        Arrows::getTargetsOfGivenSetsForSource(ns1, ["0f555c97-3843-4dfe-80c8-714d837eba69"])
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # NSDataType1::cubeToLastFrameOrNull(ns1)
    def self.cubeToLastFrameOrNull(ns1)
        NSDataType1::cubeToFramesInTimeOrder(ns1)
            .last
    end

    # NSDataType1::getAsteroidsForCube(ns1)
    def self.getAsteroidsForCube(ns1)
        Arrows::getSourcesOfGivenSetsForTarget(ns1, ["b66318f4-2662-4621-a991-a6b966fb4398"])
    end

    # NSDataType1::giveDescriptionToCubeInteractively(ns1)
    def self.giveDescriptionToCubeInteractively(ns1)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description == ""
        descriptionz = DescriptionZ::issue(description)
        Arrows::issueOrException(ns1, descriptionz)
    end

    # NSDataType1::issueNewCubeAndItsFirstFrameInteractivelyOrNull()
    def self.issueNewCubeAndItsFirstFrameInteractivelyOrNull()
        puts "Making a new NSDataType1..."
        ns0 = NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
        return nil if ns0.nil?
        ns1 = NSDataType1::issue()
        Arrows::issueOrException(ns1, ns0)
        NSDataType1::giveDescriptionToCubeInteractively(ns1)
        ns1
    end

    # NSDataType1::openLastCubeFrame(cube)
    def self.openLastCubeFrame(cube)
        frame = NSDataType1::cubeToLastFrameOrNull(cube)
        if frame.nil? then
            puts "I could not find any frames for this cube. Aborting"
            LucilleCore::pressEnterToContinue()
            return
        end
        NSDataType0s::openFrame(cube, frame)
    end

    # NSDataType1::editLastCubeFrame(cube)
    def self.editLastCubeFrame(cube)
        frame = NSDataType1::cubeToLastFrameOrNull(cube)
        if frame.nil? then
            puts "I could not find any frames for this cube. Aborting"
            LucilleCore::pressEnterToContinue()
            return
        end
        NSDataType0s::editFrame(cube, frame)
    end

    # NSDataType1::cubeMatchesPattern(cube, pattern)
    def self.cubeMatchesPattern(cube, pattern)
        return true if cube["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType1::cubeToString(cube).downcase.include?(pattern.downcase)
        false
    end

    # NSDataType1::selectCubesPerPattern(pattern)
    def self.selectCubesPerPattern(pattern)
        NSDataType1::cubes()
            .select{|cube| NSDataType1::cubeMatchesPattern(cube, pattern) }
    end

    # NSDataType1::selectCubeByInteractiveSearchString()
    def self.selectCubeByInteractiveSearchString()

        Curses::init_screen
        # Initializes a standard screen. At this point the present state of our terminal is saved and the alternate screen buffer is turned on

        Curses::noecho
        # Disables characters typed by the user to be echoed by Curses.getch as they are typed.

        win1 = Curses::Window.new(1, Miscellaneous::screenWidth(), 0, 0)
        win2 = Curses::Window.new(1, Miscellaneous::screenWidth(), 1, 0)
        win3 = Curses::Window.new(Miscellaneous::screenHeight()-1, Miscellaneous::screenWidth(), 2, 0)

        win1.refresh
        win2.refresh
        win3.refresh

        search_string_558ca20d = ""
        search_queue           = []
        selected_cubes         = []

        thread1 = Thread.new {
            loop {
                win1.setpos(0,0) # we set the cursor on the starting position
                win1.deleteln()
                win1 << "search: #{search_string_558ca20d}"
                win1.refresh
                sleep 0.01
            }
        }

        thread2 = Thread.new {
            loop {
                win2.setpos(0,0)
                win2.deleteln()
                win2 << "search queue: #{search_queue.join(" | ")}"
                win2.refresh
                sleep 0.1
            }
        }

        thread3 = Thread.new {
            loop {
                sleep 1
                win3.setpos(0,0)
                selected_cubes.first(40).each{|concept|
                    win3.deleteln()
                    win3 << "#{NSDataType1::cubeToString(concept)}\n"
                }
                (win3.maxy - win3.cury).times {win3.deleteln()}
                win3.refresh
            }
        }

        thread4 = Thread.new {
            loop {
                sleep 0.1
                next if search_queue.empty?
                str = search_queue.shift
                next if str == 0
                selected_cubes = NSDataType1::selectCubesPerPattern(str)
            }
        }

        loop {
            char = win1.getch.to_s # Reads and returns a character
            if char == '127' then
                # delete
                next if search_string_558ca20d.length == 0
                search_string_558ca20d = search_string_558ca20d[0, search_string_558ca20d.length-1]
                search_queue << search_string_558ca20d
                next
            end
            if char == '10' then
                # enter
                break
            end
            search_string_558ca20d << char
            search_queue << search_string_558ca20d
        }

        Thread.kill(thread1)
        Thread.kill(thread2)
        Thread.kill(thread3)
        Thread.kill(thread4)

        win1.close
        win2.close
        win3.close

        Curses::close_screen # this method restore our terminal's settings

        return (selected_cubes || [])
    end

    # NSDataType1::selectCubesByInteractiveSearchStringAndExploreThem()
    def self.selectCubesByInteractiveSearchStringAndExploreThem()
        cubes = NSDataType1::selectCubeByInteractiveSearchString()
        return if cubes.empty?
        loop {
            system("clear")
            cube = LucilleCore::selectEntityFromListOfEntitiesOrNull("cube", cubes, lambda{|cube| NSDataType1::cubeToString(cube) })
            break if cube.nil?
            NSDataType1::landing(cube)
        }
    end

    # NSDataType1::selectExistingCubeInteractivelyOrNull()
    def self.selectExistingCubeInteractivelyOrNull()
        cubes = NSDataType1::selectCubeByInteractiveSearchString()
        return nil if cubes.empty?
        system("clear")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("cube", cubes, lambda{|cube| NSDataType1::cubeToString(cube) })
    end

    # NSDataType1::cubeDestroyProcedure(cube)
    def self.cubeDestroyProcedure(cube)
        folderpath = DeskOperator::deskFolderpathForNSDataType1(cube)
        if File.exists?(folderpath) then
            LucilleCore::removeFileSystemLocation(folderpath)
        end
        NyxObjects::destroy(cube)
    end

    # NSDataType1::landing(ns1)
    def self.landing(ns1)
        loop {
            return if NyxObjects::getOrNull(ns1["uuid"]).nil?
            system("clear")

            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete("645001e0-dec2-4e7a-b113-5c5e93ec0e68:#{Miscellaneous::today()}:#{ns1["uuid"]}") # decaching the toString

            Miscellaneous::horizontalRule()

            puts NSDataType1::cubeToString(ns1)

            puts "    uuid: #{ns1["uuid"]}"
            description = DescriptionZ::getLastDescriptionForSourceOrNull(ns1)
            if description then
                puts "    description: #{description}"
            end
            puts "    date: #{Type1Type2CommonInterface::getReferenceDateTime(ns1)}"
            notetext = Notes::getMostRecentTextForSourceOrNull(ns1)
            if notetext then
                puts ""
                puts "    Note:"
                puts notetext.lines.map{|line| "        #{line}" }.join()
            end

            menuitems = LCoreMenuItemsNX1.new()

            puts ""
            puts "Parents:"

            asteroids = NSDataType1::getAsteroidsForCube(ns1)
            if asteroids.size > 0 then
                asteroids.each{|asteroid|
                    print "    "
                    menuitems.raw(
                        Asteroids::asteroidToString(asteroid),
                        lambda { Asteroids::landing(asteroid) }
                    )
                    puts ""
                }
            end

            Type1Type2CommonInterface::getUpstreamPages(ns1).each{|ns|
                print "    "
                menuitems.raw(
                    NSDataType2::conceptToString(ns),
                    lambda { NSDataType2::landing(ns) }
                )
                puts ""
            }

            puts ""
            puts "Frame:"

            ns0 = NSDataType1::cubeToLastFrameOrNull(ns1)
            if ns0 then
                print "    "
                menuitems.raw(
                    "open",
                    lambda { NSDataType1::openLastCubeFrame(ns1) }
                )
                print " "
                print NSDataType0s::frameToString(ns0)
                puts ""
                print "    "
                menuitems.raw(
                    "edit",
                    lambda { NSDataType1::editLastCubeFrame(ns1) }
                )
                puts ""
            else
                puts "No ns0|frame found"
                menuitems.item(
                    "create ns0|frame",
                    lambda {
                        ns0 = NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
                        return if ns0.nil?
                        Arrows::issueOrException(ns1, ns0)
                    }
                )
            end

            Miscellaneous::horizontalRule()

            description = DescriptionZ::getLastDescriptionForSourceOrNull(ns1)
            if description then
                menuitems.item(
                    "[this cube] description update",
                    lambda{
                        description = DescriptionZ::getLastDescriptionForSourceOrNull(ns1)
                        if description.nil? then
                            description = LucilleCore::askQuestionAnswerAsString("description: ")
                        else
                            description = Miscellaneous::editTextUsingTextmate(description).strip
                        end
                        return if description == ""
                        descriptionz = DescriptionZ::issue(description)
                        Arrows::issueOrException(ns1, descriptionz)
                    }
                )
            else
                menuitems.item(
                    "[this cube] description set",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        descriptionz = DescriptionZ::issue(description)
                        Arrows::issueOrException(ns1, descriptionz)
                    }
                )
            end
            menuitems.item(
                "[this cube] datetime update",
                lambda{
                    datetime = Miscellaneous::editTextUsingTextmate(Type1Type2CommonInterface::getReferenceDateTime(ns1)).strip
                    return if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
                    datetimez = DateTimeZ::issue(datetime)
                    Arrows::issueOrException(ns1, datetimez)
                }
            )
            menuitems.item(
                "[this cube] top note edit", 
                lambda{ 
                    text = Notes::getMostRecentTextForSourceOrNull(ns1) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    note = Notes::issue(text)
                    Arrows::issueOrException(ns1, note)
                }
            )
            menuitems.item(
                "[this cube] destroy",
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this ns1 ? ") then
                        NSDataType1::cubeDestroyProcedure(ns1)
                    end
                }
            )

            menuitems.item(
                "[parent concept] add",
                lambda {
                    concept = NSDataType2::selectExistingConceptOrMakeNewConceptInteractivelyOrNull()
                    return if concept.nil?
                    Arrows::issueOrException(concept, ns1)
                }
            )
            menuitems.item(
                "[parent concept] remove",
                lambda {
                    ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns", Type1Type2CommonInterface::getUpstreamPages(ns1), lambda{|ns| NSDataType2::conceptToString(ns) })
                    return if ns.nil?
                    Arrows::remove(ns, ns1)
                }
            )

            Miscellaneous::horizontalRule()

            status = menuitems.prompt()
            break if !status
        }
    end

    # ---------------------------------------------

    # NSDataType1::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataType1::selectCubesPerPattern(pattern)
            .map{|cube|
                {
                    "description"   => NSDataType1::cubeToString(cube),
                    "referencetime" => Type1Type2CommonInterface::getReferenceUnixtime(cube),
                    "dive"          => lambda{ NSDataType1::landing(cube) }
                }
            }
    end
end
