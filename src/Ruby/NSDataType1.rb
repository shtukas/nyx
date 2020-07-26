
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

    # NSDataType1::points()
    def self.points()
        NyxObjects::getSet("c18e8093-63d6-4072-8827-14f238975d04")
    end

    # NSDataType1::getPointOrNull(uuid)
    def self.getPointOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataType1::pointToString(ns1)
    def self.pointToString(ns1)
        cacheKey = "645001e0-dec2-4e7a-b113-5c5e93ec0e68:#{Miscellaneous::today()}:#{ns1["uuid"]}"
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return str if str

        ns0s = NSDataType1::pointToFramesInTimeOrder(ns1)
        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(ns1)
        if description and ns0s.size > 0 then
            str = "[point] [#{ns1["uuid"][0, 4]}] [#{ns0s.last["type"]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description and ns0s.size == 0 then
            str = "[point] [#{ns1["uuid"][0, 4]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description.nil? and ns0s.size > 0 then
            str = "[point] [#{ns1["uuid"][0, 4]}] #{NSDataType0s::frameToString(ns0s.last)}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description.nil? and ns0s.size == 0 then
            str = "[point] [#{ns1["uuid"][0, 4]}] no description and no frame"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        "[point] [#{ns1["uuid"][0, 4]}] [error: 752a3db2 ; pathological point: #{ns1["uuid"]}]"
    end

    # NSDataType1::getPointDescriptionOrNull(point)
    def self.getPointDescriptionOrNull(point)
        NSDataTypeXExtended::getLastDescriptionForTargetOrNull(point)
    end

    # NSDataType1::getPointReferenceDateTime(ns)
    def self.getPointReferenceDateTime(ns)
        datetime = NSDataTypeXExtended::getLastDateTimeForTargetOrNull(ns)
        return datetime if datetime
        Time.at(ns["unixtime"]).utc.iso8601
    end

    # NSDataType1::getPointReferenceUnixtime(ns)
    def self.getPointReferenceUnixtime(ns)
        DateTime.parse(NSDataType1::getPointReferenceDateTime(ns)).to_time.to_f
    end

    # NSDataType1::pointToFramesInTimeOrder(ns1)
    def self.pointToFramesInTimeOrder(ns1)
        Arrows::getTargetsOfGivenSetsForSource(ns1, ["0f555c97-3843-4dfe-80c8-714d837eba69"])
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # NSDataType1::pointToLastFrameOrNull(ns1)
    def self.pointToLastFrameOrNull(ns1)
        NSDataType1::pointToFramesInTimeOrder(ns1)
            .last
    end

    # NSDataType1::getAsteroidsForPoint(ns1)
    def self.getAsteroidsForPoint(ns1)
        Arrows::getSourcesOfGivenSetsForTarget(ns1, ["b66318f4-2662-4621-a991-a6b966fb4398"])
    end

    # NSDataType1::giveDescriptionToPointInteractively(ns1)
    def self.giveDescriptionToPointInteractively(ns1)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description == ""
        NSDataTypeXExtended::issueDescriptionForTarget(ns1, description)
    end

    # NSDataType1::issueNewPointAndItsFirstFrameInteractivelyOrNull()
    def self.issueNewPointAndItsFirstFrameInteractivelyOrNull()
        ns0 = NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
        return nil if ns0.nil?
        ns1 = NSDataType1::issue()
        Arrows::issueOrException(ns1, ns0)
        NSDataType1::giveDescriptionToPointInteractively(ns1)
        ns1
    end

    # NSDataType1::openLastPointFrame(point)
    def self.openLastPointFrame(point)
        frame = NSDataType1::pointToLastFrameOrNull(point)
        if frame.nil? then
            puts "I could not find any frames for this point. Aborting"
            LucilleCore::pressEnterToContinue()
            return
        end
        NSDataType0s::openFrame(point, frame)
    end

    # NSDataType1::editLastPointFrame(point)
    def self.editLastPointFrame(point)
        frame = NSDataType1::pointToLastFrameOrNull(point)
        if frame.nil? then
            puts "I could not find any frames for this point. Aborting"
            LucilleCore::pressEnterToContinue()
            return
        end
        NSDataType0s::editFrame(point, frame)
    end

    # NSDataType1::pointMatchesPattern(point, pattern)
    def self.pointMatchesPattern(point, pattern)
        return true if point["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType1::pointToString(point).downcase.include?(pattern.downcase)
        false
    end

    # NSDataType1::selectPointPerPattern(pattern)
    def self.selectPointPerPattern(pattern)
        NSDataType1::points()
            .select{|point| NSDataType1::pointMatchesPattern(point, pattern) }
    end

    # NSDataType1::selectPointByInteractiveSearchString()
    def self.selectPointByInteractiveSearchString()

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
        selected_points         = []

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
                selected_points.first(40).each{|concept|
                    win3.deleteln()
                    win3 << "#{NSDataType1::pointToString(concept)}\n"
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
                selected_points = NSDataType1::selectPointPerPattern(str)
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

        return (selected_points || [])
    end

    # NSDataType1::selectPointByInteractiveSearchStringAndExploreThem()
    def self.selectPointByInteractiveSearchStringAndExploreThem()
        points = NSDataType1::selectPointByInteractiveSearchString()
        return if points.empty?
        loop {
            system("clear")
            point = LucilleCore::selectEntityFromListOfEntitiesOrNull("point", points, lambda{|point| NSDataType1::pointToString(point) })
            break if point.nil?
            NSDataType1::landing(point)
        }
    end

    # NSDataType1::selectExistingPointInteractivelyOrNull()
    def self.selectExistingPointInteractivelyOrNull()
        points = NSDataType1::selectPointByInteractiveSearchString()
        return nil if points.empty?
        system("clear")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("point", points, lambda{|point| NSDataType1::pointToString(point) })
    end

    # NSDataType1::pointDestroyProcedure(point)
    def self.pointDestroyProcedure(point)
        folderpath = DeskOperator::deskFolderpathForNSDataType1(point)
        if File.exists?(folderpath) then
            LucilleCore::removeFileSystemLocation(folderpath)
        end
        NyxObjects::destroy(point)
    end

    # NSDataType1::landing(ns1)
    def self.landing(ns1)
        loop {
            return if NyxObjects::getOrNull(ns1["uuid"]).nil?
            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete("645001e0-dec2-4e7a-b113-5c5e93ec0e68:#{Miscellaneous::today()}:#{ns1["uuid"]}") # decaching the toString

            puts "point uuid: #{ns1["uuid"]}"

            notetext = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(ns1).strip
            if notetext and notetext.size > 0 then
                puts "------------------------------------------------------"
                puts "Note:"
                puts notetext.lines.map{|line| "    #{line}" }.join()
                puts "------------------------------------------------------"
                puts ""
            end

            description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(ns1)
            if description then
                ordinal = menuitems.ordinal(
                    lambda{
                        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(ns1)
                        if description.nil? then
                            description = LucilleCore::askQuestionAnswerAsString("description: ")
                        else
                            description = Miscellaneous::editTextSynchronously(description).strip
                        end
                        return if description == ""
                        NSDataTypeXExtended::issueDescriptionForTarget(ns1, description)
                    }
                )
                puts "[#{ordinal}:edit] #{description}"
            else
                menuitems.item(
                    "set description",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        NSDataTypeXExtended::issueDescriptionForTarget(ns1, description)
                    }
                )
            end

            ns0 = NSDataType1::pointToLastFrameOrNull(ns1)
            if ns0 then
                ordinalopen = menuitems.ordinal( lambda { NSDataType1::openLastPointFrame(ns1) } )
                ordinaledit = menuitems.ordinal( lambda { NSDataType1::editLastPointFrame(ns1) } )
                puts "[#{ordinalopen}:open] [#{ordinaledit}:edit] #{NSDataType0s::frameToString(ns0)}"
            else
                menuitems.itemNoPadding(
                    "set data",
                    lambda {
                        ns0 = NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
                        return if ns0.nil?
                        Arrows::issueOrException(ns1, ns0)
                    }
                )
            end



            puts ""

            NSDataType1::getAsteroidsForPoint(ns1).each{|asteroid|
                ordinal = menuitems.ordinal( lambda { Asteroids::landing(asteroid) } )
                puts "[#{ordinal}:access] #{Asteroids::asteroidToString(asteroid)}"
            }

            Type1Type2CommonInterface::getUpstreamConcepts(ns1).each{|ns|
                ordinal = menuitems.ordinal( lambda { NSDataType2::landing(ns) } )
                puts "[#{ordinal}:access] #{NSDataType2::conceptToString(ns)}"
            }

            puts ""



            if Miscellaneous::isAlexandra() then
                ordinal = menuitems.ordinal(
                    lambda{
                        datetime = Miscellaneous::editTextSynchronously(NSDataType1::getPointReferenceDateTime(ns1)).strip
                        return if !Miscellaneous::isDateTime_UTC_ISO8601(datetime)
                        NSDataTypeXExtended::issueDateTimeIso8601ForTarget(ns1, datetime)
                    }
                )
                puts "[#{ordinal}:edit] #{NSDataType1::getPointReferenceDateTime(ns1)}"
            else
                puts "date: #{NSDataType1::getPointReferenceDateTime(ns1)}"
            end

            menuitems.itemNoPadding(
                "edit note", 
                lambda{ 
                    text = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(ns1) || ""
                    text = Miscellaneous::editTextSynchronously(text).strip
                    NSDataTypeXExtended::issueNoteForTarget(ns1, text)
                }
            )

            menuitems.itemNoPadding(
                "add upstream concept",
                lambda {
                    concept = NSDataType2::selectExistingConceptOrMakeNewConceptInteractivelyOrNull()
                    return if concept.nil?
                    Arrows::issueOrException(concept, ns1)
                }
            )

            if Miscellaneous::isAlexandra() then
                menuitems.itemNoPadding(
                    "remove upstream concept",
                    lambda {
                        ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns", Type1Type2CommonInterface::getUpstreamConcepts(ns1), lambda{|ns| NSDataType2::conceptToString(ns) })
                        return if ns.nil?
                        Arrows::remove(ns, ns1)
                    }
                )
            end

            if Miscellaneous::isAlexandra() then
                menuitems.itemNoPadding(
                    "destroy",
                    lambda { 
                        if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this ns1 ? ") then
                            NSDataType1::pointDestroyProcedure(ns1)
                        end
                    }
                )
            end

            puts ""

            status = menuitems.prompt()
            break if !status
        }
    end

    # ---------------------------------------------

    # NSDataType1::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataType1::selectPointPerPattern(pattern)
            .map{|point|
                {
                    "description"   => NSDataType1::pointToString(point),
                    "referencetime" => NSDataType1::getPointReferenceUnixtime(point),
                    "dive"          => lambda{ NSDataType1::landing(point) }
                }
            }
    end
end
