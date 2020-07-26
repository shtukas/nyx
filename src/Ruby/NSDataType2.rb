
# encoding: UTF-8

class NSDataType2

    # NSDataType2::issueNewConceptWithDescription(description)
    def self.issueNewConceptWithDescription(description)
        concept = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(concept)
        NyxObjects::put(concept)
        NSDataTypeXExtended::issueDescriptionForTarget(concept, description)
        concept
    end

    # NSDataType2::issueNewConceptInteractivelyOrNull()
    def self.issueNewConceptInteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("concept description: ")
        return nil if description.size == 0

        concept = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(concept)
        NyxObjects::put(concept)

        NSDataTypeXExtended::issueDescriptionForTarget(concept, description)

        concept
    end

    # NSDataType2::concepts()
    def self.concepts()
        NyxObjects::getSet("6b240037-8f5f-4f52-841d-12106658171f")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # NSDataType2::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataType2::getConceptDescriptionOrNull(concept)
    def self.getConceptDescriptionOrNull(concept)
        NSDataTypeXExtended::getLastDescriptionForTargetOrNull(concept)
    end

    # NSDataType2::conceptToString(concept)
    def self.conceptToString(concept)
        cacheKey = "9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{Miscellaneous::today()}:#{concept["uuid"]}"
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return str if str

        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(concept)
        if description then
            str = "[concept] [#{concept["uuid"][0, 4]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end

        GraphTypes::getDownstreamGraphTypes(concept).each{|ns1|
            str = "[concept] [#{concept["uuid"][0, 4]}] #{NSDataType1::pointToString(ns1)}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        }

        str = "[concept] [#{concept["uuid"][0, 4]}] [no description]"
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
        str
    end

    # NSDataType2::conceptMatchesPattern(concept, pattern)
    def self.conceptMatchesPattern(concept, pattern)
        return true if concept["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType2::conceptToString(concept).downcase.include?(pattern.downcase)
        false
    end

    # NSDataType2::selectConceptsUsingPattern(pattern)
    def self.selectConceptsUsingPattern(pattern)
        NSDataType2::concepts()
            .select{|concept| NSDataType2::conceptMatchesPattern(concept, pattern) }
    end

    # NSDataType2::selectConceptsUsingGraphTypesString()
    def self.selectConceptsUsingGraphTypesString()

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
        selected_concepts         = []

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
                selected_concepts.first(40).each{|concept|
                    win3.deleteln()
                    win3 << "#{NSDataType2::conceptToString(concept)}\n"
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
                selected_concepts = NSDataType2::selectConceptsUsingPattern(str)
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

        return (selected_concepts || [])
    end

    # NSDataType2::selectConceptInteractivelyOrNull()
    def self.selectConceptInteractivelyOrNull()
        concepts = NSDataType2::selectConceptsUsingGraphTypesString()
        return nil if concepts.empty?
        system("clear")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("concept", concepts, lambda{|concept| NSDataType2::conceptToString(concept) })
    end

    # NSDataType2::selectExistingConceptOrMakeNewConceptInteractivelyOrNull()
    def self.selectExistingConceptOrMakeNewConceptInteractivelyOrNull()
        concept = NSDataType2::selectConceptInteractivelyOrNull()
        return concept if concept
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("You did not select a concept, would you like to make one ? : ")
        NSDataType2::issueNewConceptInteractivelyOrNull()
    end

    # ---------------------------------------------

    # NSDataType2::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataType2::selectConceptsUsingPattern(pattern)
            .map{|concept|
                {
                    "description"   => NSDataType2::conceptToString(concept),
                    "referencetime" => concept["unixtime"],
                    "dive"          => lambda{ GraphTypes::landing(concept) }
                }
            }
    end
end
