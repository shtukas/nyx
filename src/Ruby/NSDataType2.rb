
# encoding: UTF-8

class NSDataType2

    # NSDataType2::issueNewConceptWithDescription(description)
    def self.issueNewConceptWithDescription(description)
        ns2 = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(ns2)
        NyxObjects::put(ns2)
        NSDataTypeXExtended::issueDescriptionForTarget(ns2, description)
        ns2
    end

    # NSDataType2::issueNewConceptInteractivelyOrNull()
    def self.issueNewConceptInteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("ns2 description: ")
        return nil if description.size == 0

        ns2 = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(ns2)
        NyxObjects::put(ns2)

        NSDataTypeXExtended::issueDescriptionForTarget(ns2, description)

        ns2
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

    # NSDataType2::conceptToString(ns2)
    def self.conceptToString(ns2)
        cacheKey = "9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{Miscellaneous::today()}:#{ns2["uuid"]}"
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return str if str

        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(ns2)
        if description then
            str = "[concept] [#{ns2["uuid"][0, 4]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end

        Type1Type2CommonInterface::getDownstreamObjectsType1(ns2).each{|ns1|
            str = "[concept] [#{ns2["uuid"][0, 4]}] #{NSDataType1::cubeToString(ns1)}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        }

        str = "[concept] [#{ns2["uuid"][0, 4]}] [no description]"
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
        str
    end

    # NSDataType2::conceptMatchesPattern(ns2, pattern)
    def self.conceptMatchesPattern(ns2, pattern)
        return true if ns2["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType2::conceptToString(ns2).downcase.include?(pattern.downcase)
        false
    end

    # NSDataType2::selectConceptsUsingPattern(pattern)
    def self.selectConceptsUsingPattern(pattern)
        NSDataType2::concepts()
            .select{|concept| NSDataType2::conceptMatchesPattern(concept, pattern) }
    end

    # NSDataType2::selectConceptsUsingInteractiveSearchString()
    def self.selectConceptsUsingInteractiveSearchString()

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

    # NSDataType2::selectConceptsUsingInteractiveSearchStringAndExploreThem()
    def self.selectConceptsUsingInteractiveSearchStringAndExploreThem()
        concepts = NSDataType2::selectConceptsUsingInteractiveSearchString()
        return if concepts.empty?
        loop {
            system("clear")
            concept = LucilleCore::selectEntityFromListOfEntitiesOrNull("concept", concepts, lambda{|concept| NSDataType2::conceptToString(concept) })
            break if concept.nil?
            NSDataType2::landing(concept)
        }
    end

    # NSDataType2::selectConceptInteractivelyOrNull()
    def self.selectConceptInteractivelyOrNull()
        concepts = NSDataType2::selectConceptsUsingInteractiveSearchString()
        return nil if concepts.empty?
        system("clear")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("concept", concepts, lambda{|concept| NSDataType2::conceptToString(concept) })
    end

    # NSDataType2::selectExistingConceptOrMakeNewConceptInteractivelyOrNull()
    def self.selectExistingConceptOrMakeNewConceptInteractivelyOrNull()
        ns2 = NSDataType2::selectConceptInteractivelyOrNull()
        return ns2 if ns2
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("You did not select a ns2, would you like to make one ? : ")
        NSDataType2::issueNewConceptInteractivelyOrNull()
    end

    # NSDataType2::landing(ns2)
    def self.landing(ns2)
        loop {

            ns2 = NSDataType2::getOrNull(ns2["uuid"])

            return if ns2.nil? # Could have been destroyed in the previous loop

            system("clear")

            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{Miscellaneous::today()}:#{ns2["uuid"]}") # decaching the toString

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule()

            puts NSDataType2::conceptToString(ns2)

            puts "    uuid: #{ns2["uuid"]}"
            description = NSDataType2::getConceptDescriptionOrNull(ns2)
            if description then
                puts "    description: #{description}"
            end

            puts ""
            puts "Parents:"

            Type1Type2CommonInterface::getUpstreamConcepts(ns2).each{|ns|
                print "    "
                menuitems.raw(
                    NSDataType2::conceptToString(ns),
                    lambda { NSDataType2::landing(ns) }
                )
                puts ""
            }

            puts ""
            puts "Contents:"

            Type1Type2CommonInterface::getDownstreamObjects(ns2).each{|ns|
                print "    "
                menuitems.raw(
                    Type1Type2CommonInterface::toString(ns),
                    Type1Type2CommonInterface::navigationLambda(ns)
                )
                puts ""
            }

            Miscellaneous::horizontalRule()

            description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(ns2)
            if description then
                menuitems.item(
                    "[this] description update",
                    lambda{
                        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(ns2)
                        if description.nil? then
                            description = LucilleCore::askQuestionAnswerAsString("description: ")
                        else
                            description = Miscellaneous::editTextUsingTextmate(description).strip
                        end
                        return if description == ""
                        NSDataTypeXExtended::issueDescriptionForTarget(ns2, description)
                    }
                )
            else
                menuitems.item(
                    "[this] description set",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        NSDataTypeXExtended::issueDescriptionForTarget(ns2, description)
                    }
                )
            end

            menuitems.item(
                "[this] remove as intermediary concept", 
                lambda { 
                    puts "intermediary node removal simulation"
                    Type1Type2CommonInterface::getUpstreamConcepts(ns2).each{|upstreamconcept|
                        puts "upstreamconcept   : #{NSDataType2::conceptToString(upstreamconcept)}"
                    }
                    Type1Type2CommonInterface::getDownstreamObjects(ns2).each{|downstreampoint|
                        puts "downstreampoint: #{Type1Type2CommonInterface::toString(downstreampoint)}"
                    }
                    return if !LucilleCore::askQuestionAnswerAsBoolean("confirm removing as intermediary concept ? ")
                    Type1Type2CommonInterface::getUpstreamConcepts(ns2).each{|upstreamconcept|
                        Type1Type2CommonInterface::getDownstreamObjects(ns2).each{|downstreampoint|
                            Arrows::issueOrException(upstreamconcept, downstreampoint)
                        }
                    }
                    NyxObjects::destroy(ns2)
                }
            )

            menuitems.item(
                "[this] destroy", 
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this ns2 ? ") then
                        NyxObjects::destroy(ns2)
                    end
                }
            )

            menuitems.item(
                "[upstream] add concept",
                lambda {
                    x = NSDataType2::selectExistingConceptOrMakeNewConceptInteractivelyOrNull()
                    return if x.nil?
                    return if x["uuid"] == ns2["uuid"]
                    Arrows::issueOrException(x, ns2)
                }
            )
            menuitems.item(
                "[upstream] remove concept",
                lambda {
                    x = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns", Type1Type2CommonInterface::getUpstreamConcepts(ns2), lambda{|ns| NSDataType2::conceptToString(ns) })
                    return if x.nil?
                    Arrows::remove(x, ns2)
                }
            )

            menuitems.item(
                "[downstream] add cube (chosen from existing cubes)",
                lambda {
                    x1 = NSDataType1::selectExistingCubeInteractivelyOrNull()
                    return if x1.nil?
                    Arrows::issueOrException(ns2, x1)
                }
            )
            menuitems.item(
                "[downstream] add new cube",
                lambda {
                    x1 = NSDataType1::issueNewCubeAndItsFirstFrameInteractivelyOrNull()
                    return if x1.nil?
                    Arrows::issueOrException(ns2, x1)
                }
            )

            menuitems.item(
                "[downstream] select cubes ; move to a new downstream concept",
                lambda {
                    return if Type1Type2CommonInterface::getDownstreamObjectsType1(ns2).size == 0

                    # Selecting the cubes
                    cubes, _ = LucilleCore::selectZeroOrMore("cube", [], Type1Type2CommonInterface::getDownstreamObjectsType1(ns2), lambda{ |ns| NSDataType1::toString(ns) })
                    return if cubes.size == 0

                    # Creating the concept
                    newconcept = NSDataType2::issueNewConceptInteractivelyOrNull()

                    # Setting the concept as target of this one
                    Arrows::issueOrException(ns, newconcept)

                    # Moving the cubes
                    cubes.each{|cube|
                        Arrows::issueOrException(newconcept, cube)
                    }
                    cubes.each{|cube|
                        Arrows::remove(ns, cube)
                    }
                }
            )

            menuitems.item(
                "[downstream] add concept",
                lambda {
                    x = NSDataType2::selectExistingConceptOrMakeNewConceptInteractivelyOrNull()
                    return if x.nil?
                    return if x["uuid"] == ns2["uuid"]
                    Arrows::issueOrException(ns2, x)
                }
            )
            menuitems.item(
                "[downstream] remove concept",
                lambda {
                    x = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns", Type1Type2CommonInterface::getDownstreamObjects(ns2), lambda{|ns| Type1Type2CommonInterface::toString(ns) })
                    return if x.nil?
                    Arrows::remove(ns2, x)
                }
            )

            menuitems.item(
                "[network] select cubes ; move to an unconnected concept ; and land on that concept",
                lambda {
                    return if Type1Type2CommonInterface::getDownstreamObjectsType1(ns2).size == 0

                    # Selecting the cubes
                    cubes, _ = LucilleCore::selectZeroOrMore("cube", [], Type1Type2CommonInterface::getDownstreamObjectsType1(ns2), lambda{ |ns| NSDataType1::toString(ns) })
                    return if cubes.size == 0

                    # Creating the concept
                    newconcept = NSDataType2::issueNewConceptInteractivelyOrNull()

                    # Moving the cubes
                    cubes.each{|cube|
                        Arrows::issueOrException(newconcept, cube)
                    }
                    cubes.each{|cube|
                        Arrows::remove(ns, cube)
                    }
                    
                    NSDataType2::landing(newconcept)
                }
            )

            Miscellaneous::horizontalRule()

            status = menuitems.prompt()
            break if !status
        }
    end

    # ---------------------------------------------

    # NSDataType2::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataType2::selectConceptsUsingPattern(pattern)
            .map{|ns2|
                {
                    "description"   => NSDataType2::conceptToString(ns2),
                    "referencetime" => NSDataType1::getReferenceUnixtime(ns2),
                    "dive"          => lambda{ NSDataType2::landing(ns2) }
                }
            }
    end
end
