
class NavigationTypes

    # NavigationTypes::objectIsType1(object)
    def self.objectIsType1(object)
        object["nyxNxSet"] == "c18e8093-63d6-4072-8827-14f238975d04"
    end

    # NavigationTypes::objectIsType2(object)
    def self.objectIsType2(object)
        object["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f"
    end

    # NavigationTypes::setIds()
    def self.setIds()
        [
            "c18e8093-63d6-4072-8827-14f238975d04", # Type1
            "6b240037-8f5f-4f52-841d-12106658171f", # Type2
        ]
    end

    # NavigationTypes::objectToNicknameForToString(object)
    def self.objectToNicknameForToString(object)
        if NavigationTypes::objectIsType1(object) then
            return "point"
        end
        if NavigationTypes::objectIsType2(object) then
            return "node"
        end
        raise "[error: 8bc70a04]"
    end

    # NavigationTypes::toString(object)
    def self.toString(object)
        if NavigationTypes::objectIsType1(object) then
            return NSDataType1::pointToString(object)
        end
        if NavigationTypes::objectIsType2(object) then
            return NSDataType2::nodeToString(object)
        end
        raise "[error: dd0dce2a]"
    end

    # NavigationTypes::getObjectDescriptionOrNull(object)
    def self.getObjectDescriptionOrNull(object)
        NSDataTypeXExtended::getLastDescriptionForTargetOrNull(object)
    end

    # NavigationTypes::getObjectReferenceDateTime(object)
    def self.getObjectReferenceDateTime(object)
        datetime = NSDataTypeXExtended::getLastDateTimeForTargetOrNull(object)
        return datetime if datetime
        Time.at(object["unixtime"]).utc.iso8601
    end

    # NavigationTypes::landing(object)
    def self.landing(object)

        loop {

            return if NyxObjects::getOrNull(object["uuid"]).nil?
            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            # Decache the object

            Miscellaneous::horizontalRule()

            if Miscellaneous::isAlexandra() then
                Asteroids::getAsteroidsForGraphType(object).each{|asteroid|
                    menuitems.item(
                        "parent: #{Asteroids::asteroidToString(asteroid)}",
                        lambda { Asteroids::landing(asteroid) }
                    )
                }
            end

            upstream = NavigationTypes::getUpstreamNavigationTypes(object)
            upstream = NavigationTypes::applyDateTimeOrderToNavigationObjects(upstream)
            upstream.each{|o|
                menuitems.item(
                    "parent: #{NavigationTypes::toString(o)}",
                    lambda { NavigationTypes::landing(o) }
                )
            }

            Miscellaneous::horizontalRule()

            puts "[#{NavigationTypes::objectToNicknameForToString(object)}]"

            description = NavigationTypes::getObjectDescriptionOrNull(object)
            if description then
                puts "    description: #{description}"
            end
            puts "    uuid: #{object["uuid"]}"
            puts "    date: #{NavigationTypes::getObjectReferenceDateTime(object)}"

            if NavigationTypes::objectIsType1(object) then
                ns0 = NSDataType1::pointToLastFrameOrNull(object)
                if ns0 then
                    puts "    point data: #{NSDataType0s::frameToString(ns0)}"
                end
            end

            notetext = NSDataTypeXExtended::getLastNoteTextForTargetOrNull(object)
            if notetext and notetext.strip.size > 0 then
                Miscellaneous::horizontalRule()
                puts "Note:"
                puts notetext.strip.lines.map{|line| "    #{line}" }.join()
            end

            Miscellaneous::horizontalRule()

            if NavigationTypes::objectIsType1(object) then
                ns0 = NSDataType1::pointToLastFrameOrNull(object)
                if ns0 then
                    menuitems.item(
                        NSDataType0s::frameToString(ns0),
                        lambda { NSDataType1::openLastPointFrame(object) }
                    )
                end
            end

            downstream = NavigationTypes::getDownstreamNavigationTypes(object)
            downstream = NavigationTypes::applyDateTimeOrderToNavigationObjects(downstream)
            downstream.each{|o|
                menuitems.item(
                    NavigationTypes::toString(o),
                    lambda { NavigationTypes::landing(o) }
                )
            }

            Miscellaneous::horizontalRule()

            description = NavigationTypes::getObjectDescriptionOrNull(object)
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

            if NavigationTypes::objectIsType1(object) then
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
                        datetime = Miscellaneous::editTextSynchronously(NavigationTypes::getObjectReferenceDateTime(object)).strip
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
                    node = NavigationTypes::selectExistingOrNewGraphTypeObject()
                    return if node.nil?
                    Arrows::issueOrException(node, object)
                }
            )

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "remove parent object",
                    lambda {
                        ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", NavigationTypes::getUpstreamNavigationTypes(object), lambda{|o| NavigationTypes::toString(o) })
                        return if ns.nil?
                        Arrows::remove(ns, object)
                    }
                )
            end

            menuitems.item(
                "add child object (chosen from existing points)",
                lambda {
                    o = NavigationTypes::selectExistingObjectInteractivelyOrNull()
                    return if o.nil?
                    Arrows::issueOrException(object, o)
                }
            )

            menuitems.item(
                "add child object (new)",
                lambda {
                    o = NavigationTypes::issueNewGraphTypeObjectInteractivelyOrNull()
                    return if o.nil?
                    Arrows::issueOrException(object, o)
                }
            )

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "remove child object",
                    lambda {
                        ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", NavigationTypes::getDownstreamNavigationTypes(object), lambda{|o| NavigationTypes::toString(o) })
                        return if ns.nil?
                        Arrows::remove(ns, object)
                    }
                )
            end

            if NavigationTypes::objectIsType2(object) and Miscellaneous::isAlexandra() then
                menuitems.item(
                    "remove [this] as intermediary object", 
                    lambda { 
                        puts "intermediary node removal simulation"
                        NavigationTypes::getUpstreamNavigationTypes(object).each{|upstreamnode|
                            puts "upstreamnode   : #{NavigationTypes::toString(upstreamnode)}"
                        }
                        NavigationTypes::getDownstreamNavigationTypes(object).each{|downstreampoint|
                            puts "downstreampoint: #{NavigationTypes::toString(downstreampoint)}"
                        }
                        return if !LucilleCore::askQuestionAnswerAsBoolean("confirm removing as intermediary object ? ")
                        NavigationTypes::getUpstreamNavigationTypes(object).each{|upstreamnode|
                            NavigationTypes::getDownstreamNavigationTypes(object).each{|downstreampoint|
                                Arrows::issueOrException(upstreamnode, downstreampoint)
                            }
                        }
                        NyxObjects::destroy(object)
                    }
                )
            end

            if NavigationTypes::objectIsType2(object) and Miscellaneous::isAlexandra() then
                menuitems.item(
                    "[downstream] select points ; move to a new downstream object",
                    lambda {
                        return if NavigationTypes::getDownstreamNavigationTypes(object).size == 0

                        # Selecting the points
                        points, _ = LucilleCore::selectZeroOrMore("object", [], NavigationTypes::getDownstreamNavigationTypes(object), lambda{ |o| NavigationTypes::toString(o) })
                        return if points.size == 0

                        # Creating the object
                        newobject = NavigationTypes::issueNewGraphTypeObjectInteractivelyOrNull()

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
                            if NavigationTypes::objectIsType1(object) then
                                NSDataType1::pointDestroyProcedure(object)
                                return
                            end
                            NyxObjects::destroy(point)
                        end
                    }
                )
            end

            Miscellaneous::horizontalRule()

            status = menuitems.prompt()
            break if !status

        }
    end

    # NavigationTypes::landingLambda(object)
    def self.landingLambda(object)
        if NavigationTypes::objectIsType1(object) then
            return lambda { NavigationTypes::landing(object) }
        end
        if NavigationTypes::objectIsType2(object) then
            return lambda { NavigationTypes::landing(object) }
        end
        raise "[error: c3c51548]"
    end

    # NavigationTypes::getUpstreamNavigationTypes(object)
    def self.getUpstreamNavigationTypes(object)
        Arrows::getSourcesOfGivenSetsForTarget(object, NavigationTypes::setIds())
    end

    # NavigationTypes::getDownstreamNavigationTypes(object)
    def self.getDownstreamNavigationTypes(object)
        Arrows::getTargetsOfGivenSetsForSource(object, NavigationTypes::setIds())
    end

    # NavigationTypes::selectObjectsUsingPattern(pattern)
    def self.selectObjectsUsingPattern(pattern)
        NSDataType1::selectPointPerPattern(pattern) + NSDataType2::selectNodesUsingPattern(pattern)
    end

    # NavigationTypes::applyDateTimeOrderToNavigationObjects(objects)
    def self.applyDateTimeOrderToNavigationObjects(objects)
        objects
            .map{|object|
                {
                    "object"   => object,
                    "datetime" => NavigationTypes::getObjectReferenceDateTime(object)
                }
            }
            .sort{|i1, i2|
                i1["datetime"] <=> i2["datetime"]
            }
            .map{|i| i["object"] }
    end

    # NavigationTypes::interactiveSearch()
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

        win1_display_string = ""
        search_string       = nil # string or nil
        search_string_last_time_update = nil

        selected_objects    = []

        display_search_string = lambda {
            win1.setpos(0,0)
            win1.deleteln()
            win1 << ("-> " + (win1_display_string || ""))
            win1.refresh
        }

        display_searching_on = lambda {
            win2.setpos(0,0)
            win2.deleteln()
            win2 << "searching..."
            win2.refresh
        }
        display_searching_off = lambda {
            win2.setpos(0,0)
            win2.deleteln()
            win2.refresh
        }

        thread4 = Thread.new {
            loop {

                sleep 0.01

                next if search_string.nil?
                next if search_string_last_time_update.nil?
                next if (Time.new.to_f - search_string_last_time_update) < 1

                pattern = search_string
                search_string = nil

                display_searching_on.call()
                selected_objects = NavigationTypes::applyDateTimeOrderToNavigationObjects(NavigationTypes::selectObjectsUsingPattern(pattern))

                win3.setpos(0,0)
                selected_objects.first(Miscellaneous::screenHeight()-3).each{|object|
                    win3.deleteln()
                    win3 << "#{NavigationTypes::toString(object)}\n"
                }
                (win3.maxy - win3.cury).times {win3.deleteln()}
                win3.refresh

                display_searching_off.call()
                display_search_string.call()
            }
        }

        display_search_string.call()

        loop {

            char = win1.getch.to_s # Reads and return a character non blocking

            next if char.size == 0

            if char == '127' then
                # delete
                next if win1_display_string.length == 0
                win1_display_string = win1_display_string[0, win1_display_string.length-1]
                search_string = win1_display_string
                search_string_last_time_update = Time.new.to_f
                display_search_string.call()
                next
            end

            if char == '10' then
                # enter
                break
            end

            win1_display_string << char
            search_string = win1_display_string
            search_string_last_time_update = Time.new.to_f
            display_search_string.call()
        }

        Thread.kill(thread4)

        win1.close
        win2.close
        win3.close

        Curses::close_screen # this method restore our terminal's settings

        return (selected_objects || [])
    end

    # NavigationTypes::selectExistingObjectInteractivelyOrNull()
    def self.selectExistingObjectInteractivelyOrNull()
        points = NavigationTypes::interactiveSearch()
        return nil if points.empty?
        system("clear")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("point", points, lambda{|point| NavigationTypes::toString(point) })
    end

    # NavigationTypes::issueNewGraphTypeObjectInteractivelyOrNull()
    def self.issueNewGraphTypeObjectInteractivelyOrNull()
        types = ["point", "node"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return nil if type.nil?
        if type == "point" then
            return NSDataType1::issueNewPointAndItsFirstFrameInteractivelyOrNull()
        end
        if type == "node" then
            return NSDataType2::issueNewNodeInteractivelyOrNull()
        end
    end

    # NavigationTypes::selectExistingOrNewGraphTypeObject()
    def self.selectExistingOrNewGraphTypeObject()
        object = NavigationTypes::selectExistingObjectInteractivelyOrNull()
        return object if object
        return if !LucilleCore::askQuestionAnswerAsBoolean("You did not select an existing object. Would you like to make a new one ? : ")
        NavigationTypes::issueNewGraphTypeObjectInteractivelyOrNull()
    end

    # NavigationTypes::interactiveSearchAndExplore()
    def self.interactiveSearchAndExplore()
        objects = NavigationTypes::interactiveSearch()
        return if objects.empty?
        loop {
            system("clear")
            object = LucilleCore::selectEntityFromListOfEntitiesOrNull("object",  objects, lambda{|object| NavigationTypes::toString(object) })
            break if object.nil?
            NavigationTypes::landing(object)
        }
    end
end
