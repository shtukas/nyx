
class NSDT1Extended

    # NSDT1Extended::interactiveSearch()
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
                selected_objects = NSDataType1::applyDateTimeOrderToType1s(NSDataType1::selectType1sPerPattern(pattern))

                win3.setpos(0,0)
                selected_objects.first(Miscellaneous::screenHeight()-3).each{|object|
                    win3.deleteln()
                    win3 << "#{NSDataType1::toString(object)}\n"
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

    # NSDT1Extended::selectExistingType1InteractivelyOrNull()
    def self.selectExistingType1InteractivelyOrNull()
        nodes = NSDT1Extended::interactiveSearch()
        nodes.each{|node| NSDataType1::decacheObjectMetadata(node) }
        return nil if nodes.empty?
        system("clear")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| NSDataType1::toString(node) })
    end

    # NSDT1Extended::selectExistingOrMakeNewType1()
    def self.selectExistingOrMakeNewType1()
        node = NSDT1Extended::selectExistingType1InteractivelyOrNull()
        return node if node
        return if !LucilleCore::askQuestionAnswerAsBoolean("You did not select an existing node. Would you like to make a new one ? : ")
        NSDataType1::issueNewNodeInteractivelyOrNull()
    end

    # NSDT1Extended::interactiveSearchAndExplore()
    def self.interactiveSearchAndExplore()
        nodes = NSDT1Extended::interactiveSearch()
        nodes.each{|node| NSDataType1::decacheObjectMetadata(node) }
        return if nodes.empty?
        loop {
            nodes = nodes.select{|o| NSDataType1::getOrNull(o["uuid"]) } # In case a node has been deleted in the previous loop
            system("clear")
            node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node",  nodes, lambda{|node| NSDataType1::toString(node) })
            break if node.nil?
            NSDataType1::landing(node)
        }
    end
end
