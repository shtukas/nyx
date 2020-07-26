
class GraphTypes

    # GraphTypes::objectIsType1(ns)
    def self.objectIsType1(ns)
        ns["nyxNxSet"] == "c18e8093-63d6-4072-8827-14f238975d04"
    end

    # GraphTypes::objectIsType2(ns)
    def self.objectIsType2(ns)
        ns["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f"
    end

    # GraphTypes::objectIsType3(ns)
    def self.objectIsType3(ns)
        ns["nyxNxSet"] == "5f98770b-ee31-4c67-9d7c-509c89618ea6"
    end

    # GraphTypes::toString(ns)
    def self.toString(ns)
        if GraphTypes::objectIsType1(ns) then
            return NSDataType1::pointToString(ns)
        end
        if GraphTypes::objectIsType2(ns) then
            return NSDataType2::conceptToString(ns)
        end
        if GraphTypes::objectIsType3(ns) then
            return NSDataType3::storyToString(ns)
        end
        raise "[error: dd0dce2a]"
    end

    # GraphTypes::navigationLambda(ns)
    def self.navigationLambda(ns)
        if GraphTypes::objectIsType1(ns) then
            return lambda { NSDataType1::landing(ns) }
        end
        if GraphTypes::objectIsType2(ns) then
            return lambda { NSDataType2::landing(ns) }
        end
        if GraphTypes::objectIsType3(ns) then
            return lambda { NSDataType3::landing(ns) }
        end
        raise "[error: c3c51548]"
    end

    # GraphTypes::landing(ns)
    def self.landing(ns)
        if GraphTypes::objectIsType1(ns) then
            NSDataType1::landing(ns)
        end
        if GraphTypes::objectIsType2(ns) then
            NSDataType2::landing(ns)
        end
        if GraphTypes::objectIsType3(ns) then
            NSDataType3::landing(ns)
        end
        raise "[error: fd3c6cff]"
    end

    # GraphTypes::getUpstreamConcepts(ns)
    def self.getUpstreamConcepts(ns)
        Arrows::getSourcesOfGivenSetsForTarget(ns, ["6b240037-8f5f-4f52-841d-12106658171f"])
    end

    # GraphTypes::getDownstreamObjects(ns)
    def self.getDownstreamObjects(ns)
        Arrows::getTargetsOfGivenSetsForSource(ns, ["c18e8093-63d6-4072-8827-14f238975d04", "6b240037-8f5f-4f52-841d-12106658171f", "5f98770b-ee31-4c67-9d7c-509c89618ea6"])
    end

    # GraphTypes::getDownstreamObjectsType1(ns)
    def self.getDownstreamObjectsType1(ns)
        Arrows::getTargetsOfGivenSetsForSource(ns, ["c18e8093-63d6-4072-8827-14f238975d04"])
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
