
# encoding: UTF-8

class NSDataType2

    # NSDataType2::issueNewPageWithDescription(description)
    def self.issueNewPageWithDescription(description)
        ns2 = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(ns2)
        NyxObjects::put(ns2)

        descriptionz = DescriptionZ::issue(description)
        puts JSON.pretty_generate(descriptionz)
        Arrows::issueOrException(ns2, descriptionz)
        ns2
    end

    # NSDataType2::issueNewPageInteractivelyOrNull()
    def self.issueNewPageInteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("ns2 description: ")
        return nil if description.size == 0

        ns2 = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(ns2)
        NyxObjects::put(ns2)

        descriptionz = DescriptionZ::issue(description)
        puts JSON.pretty_generate(descriptionz)
        Arrows::issueOrException(ns2, descriptionz)

        ns2
    end

    # NSDataType2::pages()
    def self.pages()
        NyxObjects::getSet("6b240037-8f5f-4f52-841d-12106658171f")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # NSDataType2::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataType2::toStringCacheKey(ns2)
    def self.toStringCacheKey(ns2)
        "9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{Miscellaneous::today()}:#{ns2["uuid"]}"
    end

    # NSDataType2::pageToString(ns2)
    def self.pageToString(ns2)
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(NSDataType2::toStringCacheKey(ns2))
        return str if str

        description = DescriptionZ::getLastDescriptionForSourceOrNull(ns2)
        if description then
            str = "[#{NavigationPoint::userFriendlyName(ns2)}] [#{ns2["uuid"][0, 4]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(NSDataType2::toStringCacheKey(ns2), str)
            return str
        end

        NavigationPoint::getDownstreamNavigationPointsType1(ns2).each{|ns1|
            str = "[#{NavigationPoint::userFriendlyName(ns2)}] [#{ns2["uuid"][0, 4]}] #{NSDataType1::cubeToString(ns1)}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(NSDataType2::toStringCacheKey(ns2), str)
            return str
        }

        str = "[#{NavigationPoint::userFriendlyName(ns2)}] [#{ns2["uuid"][0, 4]}] [no description]"
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(NSDataType2::toStringCacheKey(ns2), str)
        str
    end

    # NSDataType2::pageMatchesPattern(ns2, pattern)
    def self.pageMatchesPattern(ns2, pattern)
        return true if ns2["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType2::pageToString(ns2).downcase.include?(pattern.downcase)
        false
    end

    # NSDataType2::selectPagesPerPattern(pattern)
    def self.selectPagesPerPattern(pattern)
        NSDataType2::pages()
            .select{|page| NSDataType2::pageMatchesPattern(page, pattern) }
    end

    # NSDataType2::selectPagesBySearchStringInteractively()
    def self.selectPagesBySearchStringInteractively()

        Curses::init_screen
        # Initializes a standard screen. At this point the present state of our terminal is saved and the alternate screen buffer is turned on

        Curses::noecho
        # Disables characters typed by the user to be echoed by Curses.getch as they are typed.

        win1 = Curses::Window.new(1, 80, 0, 0)
        win2 = Curses::Window.new(1, 80, 1, 0)
        win3 = Curses::Window.new(40, 80, 2, 0)

        ns_search_string       = ""
        last_searched_string   = ""
        searching              = false
        selected_pages         = []
        has_new_selected_pages = false

        thread1 = Thread.new {
            loop {
                win1.setpos(0,0) # we set the cursor on the starting position
                win1.deleteln()
                win1 << "search: #{ns_search_string}"
                win1.refresh
                sleep 0.01
            }
        }

        thread2 = Thread.new {
            loop {
                win2.setpos(0,0)
                win2.deleteln()
                if searching then
                    win2 << "searching..."
                end
                win2.refresh
                sleep 0.1
            }
        }

        thread3 = Thread.new {
            loop {
                sleep 1
                next if !has_new_selected_pages
                has_new_selected_pages = false
                next if selected_pages.size == 0
                win3.setpos(0,0)
                selected_pages.first(40).each{|page|
                    win3.deleteln()
                    win3 << "#{NSDataType2::pageToString(page)}\n"
                }
                (win3.maxy - win3.cury).times {win3.deleteln()}
                win3.refresh
            }
        }

        thread4 = Thread.new {
            loop {
                sleep 0.1
                next if ns_search_string.length < 3
                next if ns_search_string == last_searched_string
                searching = true
                last_searched_string = ns_search_string
                selected_pages = NSDataType2::selectPagesPerPattern(ns_search_string)
                has_new_selected_pages = true
                searching = false
            }
        }

        loop {
            char = win1.getch.to_s # Reads and returns a character
            if char == '127' then
                # delete
                ns_search_string = ns_search_string[0, ns_search_string.length-1].strip
                next
            end
            if char == '10' then
                # enter
                break
            end
            ns_search_string << char.strip
        }

        Thread.kill(thread1)
        Thread.kill(thread2)
        Thread.kill(thread3)
        Thread.kill(thread4)

        Curses::close_screen # this method restore our terminal's settings

        return (selected_pages || [])
    end

     # NSDataType2::selectPageInteractivelyOrNull()
    def self.selectPageInteractivelyOrNull()
        pages = NSDataType2::selectPagesBySearchStringInteractively()
        return nil if pages.empty?
        system("clear")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("page", pages, lambda{|page| NSDataType2::pageToString(page) })
    end

    # NSDataType2::selectExistingPageOrMakeNewPageOrNull()
    def self.selectExistingPageOrMakeNewPageOrNull()
        ns2 = NSDataType2::selectPageInteractivelyOrNull()
        return ns2 if ns2
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("You did not select a ns2, would you like to make one ? : ")
        NSDataType2::issueNewPageInteractivelyOrNull()
    end

    # NSDataType2::landing(ns2)
    def self.landing(ns2)
        loop {

            ns2 = NSDataType2::getOrNull(ns2["uuid"])

            return if ns2.nil? # Could have been destroyed in the previous loop

            system("clear")

            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete(NSDataType2::toStringCacheKey(ns2)) # decaching the toString

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule()

            puts NSDataType2::pageToString(ns2)

            puts "    uuid: #{ns2["uuid"]}"
            description = DescriptionZ::getLastDescriptionForSourceOrNull(ns2)
            if description then
                puts "    description: #{description}"
            end
            puts "    date: #{NavigationPoint::getReferenceDateTime(ns2)}"
            notetext = Notes::getMostRecentTextForSourceOrNull(ns2)
            if notetext then
                puts ""
                puts "    Note:"
                puts notetext.lines.map{|line| "        #{line}" }.join()
            end

            puts ""
            puts "Parents:"


            # We are only expecting Type2 here because Type1 don't link down to Type2
            NavigationPoint::getUpstreamNavigationPoints(ns2).each{|ns|
                print "    "
                menuitems.raw(
                    "#{NavigationPoint::toString(ns)}",
                    NavigationPoint::navigationLambda(ns)
                )
                puts ""
            }

            puts ""
            puts "Contents:"

            # Type2 can down stream to Type2 and Type1, we display them separately

            NavigationPoint::getDownstreamNavigationPoints(ns2).each{|ns|
                print "    "
                menuitems.raw(
                    NavigationPoint::toString(ns),
                    NavigationPoint::navigationLambda(ns)
                )
                puts ""
            }

            Miscellaneous::horizontalRule()

            description = DescriptionZ::getLastDescriptionForSourceOrNull(ns2)
            if description then
                menuitems.item(
                    "[this page] description update",
                    lambda{
                        description = DescriptionZ::getLastDescriptionForSourceOrNull(ns2)
                        if description.nil? then
                            description = LucilleCore::askQuestionAnswerAsString("description: ")
                        else
                            description = Miscellaneous::editTextUsingTextmate(description).strip
                        end
                        return if description == ""
                        descriptionz = DescriptionZ::issue(description)
                        Arrows::issueOrException(ns2, descriptionz)
                    }
                )
            else
                menuitems.item(
                    "[this page] description set",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        descriptionz = DescriptionZ::issue(description)
                        Arrows::issueOrException(ns2, descriptionz)
                    }
                )
            end

            menuitems.item(
                "[this page] datetime update",
                lambda{
                    datetime = Miscellaneous::editTextUsingTextmate(NavigationPoint::getReferenceDateTime(ns2)).strip
                    return if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
                    datetimez = DateTimeZ::issue(datetime)
                    Arrows::issueOrException(ns2, datetimez)
                }
            )

            menuitems.item(
                "[this page] top note edit", 
                lambda{ 
                    text = Notes::getMostRecentTextForSourceOrNull(ns2) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    note = Notes::issue(text)
                    Arrows::issueOrException(ns2, note)
                }
            )

            menuitems.item(
                "[this page] remove as intermediary page", 
                lambda { 
                    puts "intermediary node removal simulation"
                    NavigationPoint::getUpstreamNavigationPoints(ns2).each{|upstreampage|
                        puts "upstreampage   : #{NavigationPoint::toString(upstreampage)}"
                    }
                    NavigationPoint::getDownstreamNavigationPoints(ns2).each{|downstreampoint|
                        puts "downstreampoint: #{NavigationPoint::toString(downstreampoint)}"
                    }
                    return if !LucilleCore::askQuestionAnswerAsBoolean("confirm removing as intermediary page ? ")
                    NavigationPoint::getUpstreamNavigationPoints(ns2).each{|upstreampage|
                        NavigationPoint::getDownstreamNavigationPoints(ns2).each{|downstreampoint|
                            Arrows::issueOrException(upstreampage, downstreampoint)
                        }
                    }
                    NyxObjects::destroy(ns2)
                }
            )

            menuitems.item(
                "[this page] destroy", 
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this ns2 ? ") then
                        NyxObjects::destroy(ns2)
                    end
                }
            )

            menuitems.item(
                "[upstream] add #{NavigationPoint::ufn("Type2")}",
                lambda {
                    x = NSDataType2::selectExistingPageOrMakeNewPageOrNull()
                    return if x.nil?
                    return if x["uuid"] == ns2["uuid"]
                    Arrows::issueOrException(x, ns2)
                }
            )
            menuitems.item(
                "[upstream] remove #{NavigationPoint::ufn("Type2")}",
                lambda {
                    x = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns", NavigationPoint::getUpstreamNavigationPoints(ns2), lambda{|ns| NavigationPoint::toString(ns) })
                    return if x.nil?
                    Arrows::remove(x, ns2)
                }
            )

            menuitems.item(
                "[#{NavigationPoint::ufn("Type1")}] add existing",
                lambda {
                    x1 = NSDataType1::selectExistingCubeInteractivelyOrNull()
                    return if x1.nil?
                    Arrows::issueOrException(ns2, x1)
                }
            )
            menuitems.item(
                "[#{NavigationPoint::ufn("Type1")}] add new",
                lambda {
                    x1 = NSDataType1::issueNewCubeAndItsFirstFrameInteractivelyOrNull()
                    return if x1.nil?
                    Arrows::issueOrException(ns2, x1)
                }
            )

            menuitems.item(
                "[selected cubes] move to a child page",
                lambda {
                    return if NavigationPoint::getDownstreamNavigationPointsType1(ns2).size == 0

                    # Selecting the cubes
                    cubes, _ = LucilleCore::selectZeroOrMore("cube", [], NavigationPoint::getDownstreamNavigationPointsType1(ns2), lambda{ |ns| NavigationPoint::toString(ns) })
                    return if cubes.size == 0

                    # Creating the page
                    newpage = NSDataType2::issueNewPageInteractivelyOrNull()

                    # Setting the page as target of this one
                    Arrows::issueOrException(ns, newpage)

                    # Moving the cubes
                    cubes.each{|cube|
                        Arrows::issueOrException(newpage, cube)
                    }
                    cubes.each{|cube|
                        Arrows::remove(ns, cube)
                    }
                }
            )

            menuitems.item(
                "[selected cubes] move to an unconnected page ; and land on that page",
                lambda {
                    return if NavigationPoint::getDownstreamNavigationPointsType1(ns2).size == 0

                    # Selecting the cubes
                    cubes, _ = LucilleCore::selectZeroOrMore("cube", [], NavigationPoint::getDownstreamNavigationPointsType1(ns2), lambda{ |ns| NavigationPoint::toString(ns) })
                    return if cubes.size == 0

                    # Creating the page
                    newpage = NSDataType2::issueNewPageInteractivelyOrNull()

                    # Moving the cubes
                    cubes.each{|cube|
                        Arrows::issueOrException(newpage, cube)
                    }
                    cubes.each{|cube|
                        Arrows::remove(ns, cube)
                    }
                    
                    NSDataType2::landing(newpage)
                }
            )

            menuitems.item(
                "[downstream #{NavigationPoint::ufn("Type2")}] add from existing",
                lambda {
                    x = NSDataType2::selectExistingPageOrMakeNewPageOrNull()
                    return if x.nil?
                    return if x["uuid"] == ns2["uuid"]
                    Arrows::issueOrException(ns2, x)
                }
            )
            menuitems.item(
                "[downstream #{NavigationPoint::ufn("Type2")}] remove",
                lambda {
                    x = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns", NavigationPoint::getDownstreamNavigationPoints(ns2), lambda{|ns| NavigationPoint::toString(ns) })
                    return if x.nil?
                    Arrows::remove(ns2, x)
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
        NSDataType2::selectPagesPerPattern(pattern)
            .map{|ns2|
                {
                    "description"   => NSDataType2::pageToString(ns2),
                    "referencetime" => NavigationPoint::getReferenceUnixtime(ns2),
                    "dive"          => lambda{ NSDataType2::landing(ns2) }
                }
            }
    end
end
