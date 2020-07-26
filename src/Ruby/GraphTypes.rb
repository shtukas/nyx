
class GraphTypes

    # GraphTypes::objectIsType1(object)
    def self.objectIsType1(object)
        object["nyxNxSet"] == "c18e8093-63d6-4072-8827-14f238975d04"
    end

    # GraphTypes::objectIsType2(object)
    def self.objectIsType2(object)
        object["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f"
    end

    # GraphTypes::objectIsType3(object)
    def self.objectIsType3(object)
        object["nyxNxSet"] == "5f98770b-ee31-4c67-9d7c-509c89618ea6"
    end

    # GraphTypes::setIds()
    def self.setIds()
        [
            "c18e8093-63d6-4072-8827-14f238975d04", # Type1
            "6b240037-8f5f-4f52-841d-12106658171f", # Type2
            "5f98770b-ee31-4c67-9d7c-509c89618ea6", # Type3
        ]
    end

    # GraphTypes::objectToNicknameForToString(object)
    def self.objectToNicknameForToString(object)
        if GraphTypes::objectIsType1(object) then
            return "point"
        end
        if GraphTypes::objectIsType2(object) then
            return "concept"
        end
        if GraphTypes::objectIsType3(object) then
            return "story"
        end
        raise "[error: 8bc70a04]"
    end

    # GraphTypes::toString(object)
    def self.toString(object)
        if GraphTypes::objectIsType1(object) then
            return NSDataType1::pointToString(object)
        end
        if GraphTypes::objectIsType2(object) then
            return NSDataType2::conceptToString(object)
        end
        if GraphTypes::objectIsType3(object) then
            return NSDataType3::storyToString(object)
        end
        raise "[error: dd0dce2a]"
    end

    # GraphTypes::getObjectDescriptionOrNull(object)
    def self.getObjectDescriptionOrNull(object)
        NSDataTypeXExtended::getLastDescriptionForTargetOrNull(object)
    end

    # GraphTypes::getObjectReferenceDateTime(object)
    def self.getObjectReferenceDateTime(object)
        datetime = NSDataTypeXExtended::getLastDateTimeForTargetOrNull(object)
        return datetime if datetime
        Time.at(object["unixtime"]).utc.iso8601
    end

    # GraphTypes::landing(object)
    def self.landing(object)

        loop {

            return if NyxObjects::getOrNull(object["uuid"]).nil?
            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            # Decache the object

            Miscellaneous::horizontalRule()

            puts "[#{GraphTypes::objectToNicknameForToString(object)}]"

            description = GraphTypes::getObjectDescriptionOrNull(object)
            if description then
                puts "    description: #{description}"
            end
            puts "    uuid: #{object["uuid"]}"
            puts "    date: #{GraphTypes::getObjectReferenceDateTime(object)}"

            if GraphTypes::objectIsType1(object) then
                ns0 = NSDataType1::pointToLastFrameOrNull(object)
                if ns0 then
                    puts "    point data: #{NSDataType0s::frameToString(ns0)}"
                end
            end

            Asteroids::getAsteroidsForGraphType(object).each{|asteroid|
                puts "    parent: #{Asteroids::asteroidToString(asteroid)}"
            }

            GraphTypes::getUpstreamGraphTypes(object).each{|o|
                puts "    parent: #{GraphTypes::toString(o)}"
            }

            GraphTypes::getDownstreamGraphTypes(object).each{|o|
                puts "    child: #{GraphTypes::toString(o)}"
            }

            notetext = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(object).strip
            if notetext and notetext.size > 0 then
                Miscellaneous::horizontalRule()
                puts "Note:"
                puts notetext.lines.map{|line| "    #{line}" }.join()
            end

            Miscellaneous::horizontalRule()

            if GraphTypes::objectIsType1(object) then
                ns0 = NSDataType1::pointToLastFrameOrNull(object)
                if ns0 then
                    menuitems.item(
                        "open point data: #{NSDataType0s::frameToString(ns0)}",
                        lambda { NSDataType1::openLastPointFrame(object) }
                    )
                end
            end

            description = GraphTypes::getObjectDescriptionOrNull(object)
            if description then
                menuitems.item(
                    "edit description",
                    lambda{
                        description = Miscellaneous::editTextSynchronously(description).strip
                        return if description == ""
                        NSDataTypeXExtended::issueDescriptionForTarget(object, description)
                    }
                )
            else
                menuitems.item(
                    "set description",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        NSDataTypeXExtended::issueDescriptionForTarget(object, description)
                    }
                )
            end

            if GraphTypes::objectIsType1(object) then
                ns0 = NSDataType1::pointToLastFrameOrNull(object)
                if ns0 then
                    menuitems.item(
                        "edit point data",
                        lambda { NSDataType1::editLastPointFrame(object) }
                    )
                else
                    menuitems.item(
                        "set data",
                        lambda {
                            ns0 = NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
                            return if ns0.nil?
                            Arrows::issueOrException(object, ns0)
                        }
                    )
                end
            end

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "edit reference datetime",
                    lambda{
                        datetime = Miscellaneous::editTextSynchronously(GraphTypes::getObjectReferenceDateTime(object)).strip
                        return if !Miscellaneous::isDateTime_UTC_ISO8601(datetime)
                        NSDataTypeXExtended::issueDateTimeIso8601ForTarget(object, datetime)
                    }
                )
            end


            menuitems.item(
                "edit note",
                lambda{ 
                    text = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(object) || ""
                    text = Miscellaneous::editTextSynchronously(text).strip
                    NSDataTypeXExtended::issueNoteForTarget(object, text)
                }
            )


            menuitems.item(
                "add parent object",
                lambda {
                    concept = NSDataType2::selectExistingConceptOrMakeNewConceptInteractivelyOrNull()
                    return if concept.nil?
                    Arrows::issueOrException(concept, object)
                }
            )

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "remove parent object",
                    lambda {
                        ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", GraphTypes::getUpstreamGraphTypes(object), lambda{|o| NSDataType2::conceptToString(o) })
                        return if ns.nil?
                        Arrows::remove(ns, object)
                    }
                )
            end

            menuitems.item(
                "add child object (chosen from existing points)",
                lambda {
                    o = NSDataType1::selectExistingPointInteractivelyOrNull()
                    return if o.nil?
                    Arrows::issueOrException(object, o)
                }
            )

            menuitems.item(
                "add child object (new)",
                lambda {
                    o = NSDataType1::issueNewPointAndItsFirstFrameInteractivelyOrNull()
                    return if o.nil?
                    Arrows::issueOrException(object, o)
                }
            )

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "remove child object",
                    lambda {
                        ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", GraphTypes::getDownstreamGraphTypes(object), lambda{|o| NSDataType2::conceptToString(o) })
                        return if ns.nil?
                        Arrows::remove(ns, object)
                    }
                )
            end

            Asteroids::getAsteroidsForGraphType(object).each{|asteroid|
                ordinal = menuitems.item(
                    "access: #{Asteroids::asteroidToString(asteroid)}",
                    lambda { Asteroids::landing(asteroid) }
                )
            }

            GraphTypes::getUpstreamGraphTypes(object).each{|o|
                menuitems.item(
                    "access: #{GraphTypes::toString(o)}",
                    lambda { GraphTypes::landing(o) }
                )
            }

            if GraphTypes::objectIsType2(object) and Miscellaneous::isAlexandra() then
                menuitems.item(
                    "remove [this] as intermediary object", 
                    lambda { 
                        puts "intermediary node removal simulation"
                        GraphTypes::getUpstreamGraphTypes(object).each{|upstreamconcept|
                            puts "upstreamconcept   : #{NSDataType2::conceptToString(upstreamconcept)}"
                        }
                        GraphTypes::getDownstreamGraphTypes(object).each{|downstreampoint|
                            puts "downstreampoint: #{GraphTypes::toString(downstreampoint)}"
                        }
                        return if !LucilleCore::askQuestionAnswerAsBoolean("confirm removing as intermediary object ? ")
                        GraphTypes::getUpstreamGraphTypes(object).each{|upstreamconcept|
                            GraphTypes::getDownstreamGraphTypes(object).each{|downstreampoint|
                                Arrows::issueOrException(upstreamconcept, downstreampoint)
                            }
                        }
                        NyxObjects::destroy(object)
                    }
                )
            end

            if GraphTypes::objectIsType2(object) and Miscellaneous::isAlexandra() then
                menuitems.item(
                    "[downstream] select points ; move to a new downstream object",
                    lambda {
                        return if GraphTypes::getDownstreamGraphTypes(object).size == 0

                        # Selecting the points
                        points, _ = LucilleCore::selectZeroOrMore("object", [], GraphTypes::getDownstreamGraphTypes(object), lambda{ |o| NSDataType1::toString(o) })
                        return if points.size == 0

                        # Creating the object
                        newobject = NSDataType2::issueNewConceptInteractivelyOrNull()

                        # Setting the object as target of this one
                        Arrows::issueOrException(object, newobject)

                        # Moving the points
                        points.each{|o|
                            Arrows::issueOrException(newobject, o)
                        }
                        points.each{|o|
                            Arrows::remove(object, o)
                        }
                    }
                )
            end

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "destroy point",
                    lambda { 
                        if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this object ? ") then
                            NSDataType1::pointDestroyProcedure(object)
                        end
                    }
                )
            end

            Miscellaneous::horizontalRule()

            status = menuitems.prompt()
            break if !status

        }

    end

    # GraphTypes::landingLambda(object)
    def self.landingLambda(object)
        if GraphTypes::objectIsType1(object) then
            return lambda { GraphTypes::landing(object) }
        end
        if GraphTypes::objectIsType2(object) then
            return lambda { GraphTypes::landing(object) }
        end
        if GraphTypes::objectIsType3(object) then
            return lambda { GraphTypes::landing(object) }
        end
        raise "[error: c3c51548]"
    end

    # GraphTypes::getUpstreamGraphTypes(object)
    def self.getUpstreamGraphTypes(object)
        Arrows::getSourcesOfGivenSetsForTarget(object, GraphTypes::setIds())
    end

    # GraphTypes::getDownstreamGraphTypes(object)
    def self.getDownstreamGraphTypes(object)
        Arrows::getTargetsOfGivenSetsForSource(object, GraphTypes::setIds())
    end

    # GraphTypes::selectObjectsUsingPattern(pattern)
    def self.selectObjectsUsingPattern(pattern)
        NSDataType2::selectConceptsUsingPattern(pattern) + NSDataType3::selectStorysUsingPattern(pattern) + NSDataType1::selectPointPerPattern(pattern)
    end

    # GraphTypes::interactiveSearch()
    def self.interactiveSearch()

        Curses::init_screen
        # Initializes a standard screen. At this point the present state of our terminal is saved and the alternate screen buffer is turned on

        Curses::noecho
        # Disables characters typed by the user to be echoed by Curses.getch as they are typed.

        win1 = Curses::Window.new(1, Miscellaneous::screenWidth(), 0, 0)
        win2 = Curses::Window.new(1, Miscellaneous::screenWidth(), 1, 0)
        win3 = Curses::Window.new(Miscellaneous::screenHeight()-2, Miscellaneous::screenWidth(), 2, 0)

        win1.refresh
        win2.refresh
        win3.refresh

        search_string_558ca20d = ""
        search_queue           = []
        selected_objects         = []

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
                win2 << "search_queue: #{search_queue.join(" | ")}"
                win2.refresh
                sleep 0.1
            }
        }

        thread3 = Thread.new {
            loop {
                sleep 1
                win3.setpos(0,0)
                selected_objects.first(40).each{|object|
                    win3.deleteln()
                    win3 << "#{GraphTypes::toString(object)}\n"
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
                selected_objects = GraphTypes::selectObjectsUsingPattern(str)
            }
        }

        loop {
            char = win1.getch.to_s # Reads and returobject a character
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

        return (selected_objects || [])
    end

    # GraphTypes::interactiveSearchAndExplore()
    def self.interactiveSearchAndExplore()
        objects = GraphTypes::interactiveSearch()
        return if objects.empty?
        loop {
            system("clear")
            object = LucilleCore::selectEntityFromListOfEntitiesOrNull("object",  objects, lambda{|object| GraphTypes::toString(object) })
            break if object.nil?
            GraphTypes::landing(object)
        }
    end
end
