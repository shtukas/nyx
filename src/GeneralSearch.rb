
# encoding: UTF-8

class GeneralSearch

    # GeneralSearch::searchNx1630NGX15(pattern)
    def self.searchNx1630NGX15(pattern)
        SelectionLookupDataset::patternToNGX15s(pattern)
            .map{|ngx15|
                {
                    "description"   => NGX15::toString(ngx15),
                    "referencetime" => DateTime.parse(GenericNyxObject::getObjectReferenceDateTime(ngx15)).to_time.to_f,
                    "dive"          => lambda{ NGX15::landing(ngx15) }
                }
            }
    end

    # GeneralSearch::searchNx1630Quark(pattern)
    def self.searchNx1630Quark(pattern)
        SelectionLookupDataset::patternToQuarks(pattern)
            .map{|quark|
                {
                    "description"   => Quarks::toString(quark),
                    "referencetime" => DateTime.parse(GenericNyxObject::getObjectReferenceDateTime(quark)).to_time.to_f,
                    "dive"          => lambda{ Quarks::landing(quark) }
                }
            }
    end

    # GeneralSearch::searchNx1630Tag(pattern)
    def self.searchNx1630Tag(pattern)
        SelectionLookupDataset::patternToTags(pattern)
            .map{|tag|
                {
                    "description"   => Tags::toString(tag),
                    "referencetime" => DateTime.parse(GenericNyxObject::getObjectReferenceDateTime(tag)).to_time.to_f,
                    "dive"          => lambda{ Tags::landing(tag) }
                }
            }
    end

    # GeneralSearch::searchNx1630OpsNode(pattern)
    def self.searchNx1630OpsNode(pattern)
        SelectionLookupDataset::patternToOperationalListings(pattern)
            .map{|node|
                {
                    "description"   => OperationalListings::toString(node),
                    "referencetime" => DateTime.parse(GenericNyxObject::getObjectReferenceDateTime(node)).to_time.to_f,
                    "dive"          => lambda{ OperationalListings::landing(node) }
                }
            }
    end

    # GeneralSearch::searchNx1630EncyclopediaNode(pattern)
    def self.searchNx1630EncyclopediaNode(pattern)
        SelectionLookupDataset::patternToEncyclopediaNodes(pattern)
            .map{|node|
                {
                    "description"   => EncyclopediaNodes::toString(node),
                    "referencetime" => DateTime.parse(GenericNyxObject::getObjectReferenceDateTime(node)).to_time.to_f,
                    "dive"          => lambda{ EncyclopediaNodes::landing(node) }
                }
            }
    end

    # GeneralSearch::searchNx1630Asteroid(pattern)
    def self.searchNx1630Asteroid(pattern)
        SelectionLookupDataset::patternToAsteroids(pattern)
            .map{|asteroid|
                {
                    "description"   => Asteroids::toString(asteroid),
                    "referencetime" => asteroid["unixtime"],
                    "dive"          => lambda{ Asteroids::landing(asteroid) }
                }
            }
    end

    # GeneralSearch::searchNx1630Wave(pattern)
    def self.searchNx1630Wave(pattern)
        SelectionLookupDataset::patternToWaves(pattern)
            .map{|wave|
                {
                    "description"   => Waves::toString(wave),
                    "referencetime" => wave["unixtime"],
                    "dive"          => lambda { Waves::waveDive(wave) }
                }
            }
    end

    # GeneralSearch::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        [
            GeneralSearch::searchNx1630NGX15(pattern),
            GeneralSearch::searchNx1630Quark(pattern),
            GeneralSearch::searchNx1630Tag(pattern),
            GeneralSearch::searchNx1630OpsNode(pattern),
            GeneralSearch::searchNx1630EncyclopediaNode(pattern),
            GeneralSearch::searchNx1630Asteroid(pattern),
            GeneralSearch::searchNx1630Wave(pattern)
        ]
            .flatten
            .sort{|i1, i2| i1["referencetime"] <=> i2["referencetime"] }
    end

    # GeneralSearch::searchAndDive()
    def self.searchAndDive()
        loop {
            system("clear")
            pattern = LucilleCore::askQuestionAnswerAsString("search pattern: ")
            return if pattern.size == 0
            next if pattern.size < 3
            searchresults = GeneralSearch::searchNx1630(pattern)
            loop {
                system("clear")
                puts "search results for '#{pattern}':"
                ms = LCoreMenuItemsNX1.new()
                searchresults
                    .each{|sr| 
                        ms.item(
                            sr["description"], 
                            sr["dive"]
                        )
                    }
                status = ms.promptAndRunSandbox()
                break if !status
            }
        }
    end


    # GeneralSearch::ncurseXp1OrNull(object, lambdaToString)
    # lambda1: pattern: String -> Array[String]
    # lambda2: string:  String -> Object
    def self.ncurseXp1OrNull(lambda1, lambda2)

        windowUpdate = lambda { |win, strs|
            win.setpos(0,0)
            strs.each{|str|
                win.deleteln()
                win << (str + "\n")
            }
            win.refresh
        }

        Curses::init_screen
        # Initializes a standard screen. At this point the present state of our terminal is saved and the alternate screen buffer is turned on

        Curses::noecho
        # Disables characters typed by the user to be echoed by Curses.getch as they are typed.

        inputString = ""

        win1 = Curses::Window.new(1, Miscellaneous::screenWidth(), 0, 0)
        win2 = Curses::Window.new(1, Miscellaneous::screenWidth(), 1, 0)
        win3 = Curses::Window.new(Miscellaneous::screenHeight()-2, Miscellaneous::screenWidth(), 2, 0)

        win1.refresh
        win2.refresh
        win3.refresh

        # windowUpdate.call(win1, ["line1"])
        # windowUpdate.call(win2, ["line2"])
        # windowUpdate.call(win3, ["line3", "line4"])

        windowUpdate.call(win1, [""])

        loop {
            char = win1.getch.to_s # Reads and return a character non blocking

            next if char.size == 0

            if char == '127' then
                # delete
                next if inputString.length == 0
                inputString = inputString[0, inputString.length-1]
                windowUpdate.call(win1, [inputString])
                next
            end

            if char == '10' then
                # enter
                break
            end

            inputString = inputString + char
            windowUpdate.call(win1, [inputString])
        }

        win1.close
        win2.close
        win3.close

        Curses::close_screen # this method restore our terminal's settings

        # -----------------------------------------------------------------------

        system("clear")

        lines = lambda1.call(inputString)
        line = LucilleCore::selectEntityFromListOfEntitiesOrNull("", lines)
        return nil if line.nil?
        lambda2.call(line) # this returns an object
    end
end