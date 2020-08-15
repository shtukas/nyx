
=begin

This table is documented in "System Architecture Notes/Pattern Searching Nodes.txt"

table: lookup
    _objectuuid_    text
    _fragment_      text

=end

class NSDataType1PatternSearchLookup

    # NSDataType1PatternSearchLookup::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/NSDataType1PatternSearchLookup.sqlite3"
    end

    # NSDataType1PatternSearchLookup::selectNSDataType1UUIDsByPattern(pattern)
    def self.selectNSDataType1UUIDsByPattern(pattern)
        db = SQLite3::Database.new(NSDataType1PatternSearchLookup::databaseFilepath())
        db.results_as_hash = true
        answer = []
        db.execute( "select * from lookup" , [] ) do |row|
            fragment = row['_fragment_']
            if fragment.downcase.include?(pattern.downcase) then
                answer << row['_objectuuid_']
            end
            
        end
        db.close
        answer.uniq
    end

    # NSDataType1PatternSearchLookup::removeRecordsAgainstNode(objectuuid)
    def self.removeRecordsAgainstNode(objectuuid)
        db = SQLite3::Database.new(NSDataType1PatternSearchLookup::databaseFilepath())
        db.execute "delete from lookup where _objectuuid_=?", [objectuuid]
        db.close
    end

    # NSDataType1PatternSearchLookup::addRecord(objectuuid, fragment)
    def self.addRecord(objectuuid, fragment)
        db = SQLite3::Database.new(NSDataType1PatternSearchLookup::databaseFilepath())
        db.execute "insert into lookup (_objectuuid_, _fragment_) values ( ?, ? )", [objectuuid, fragment]
        db.close
    end

    # NSDataType1PatternSearchLookup::updateLookupForNode(node)
    def self.updateLookupForNode(node)
        NSDataType1PatternSearchLookup::removeRecordsAgainstNode(node["uuid"])
        NSDataType1PatternSearchLookup::addRecord(node["uuid"], node["uuid"])
        NSDataType1PatternSearchLookup::addRecord(node["uuid"], NSDataType1::toString(node))
        Arrows::getTargetsForSource(node).each{|child| 
            NSDataType1PatternSearchLookup::addRecord(node["uuid"], GenericObjectInterface::toString(child))
        }
    end

    # NSDataType1PatternSearchLookup::rebuildLookup()
    def self.rebuildLookup()
        NSDataType1::objects().each{|node|
            NSDataType1PatternSearchLookup::updateLookupForNode(node)
        }
    end

    # NSDataType1PatternSearchLookup::rebuildLookupSlowly()
    def self.rebuildLookupSlowly()
        NSDataType1::objects()
            .shuffle
            .each{|node|
                NSDataType1PatternSearchLookup::updateLookupForNode(node)
                sleep 1
            }
    end
end

class NSDT1ExtendedDataLookups

    # NSDT1ExtendedDataLookups::type1MatchesPattern(point, pattern)
    # Legacy
    def self.type1MatchesPattern(point, pattern)
        return true if point["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType1::toString(point).downcase.include?(pattern.downcase)
        return true if Arrows::getTargetsForSource(point).any?{|child| GenericObjectInterface::toString(child).downcase.include?(pattern.downcase) }
        false
    end

    # NSDT1ExtendedDataLookups::selectType1sPerPattern(pattern)
    # Legacy
    def self.selectType1sPerPattern(pattern)
        # 2020-08-15
        # This is a legacy function that I keep for sentimental reasons,
        # The direct look up using NSDT1ExtendedDataLookups::type1MatchesPattern has been replace by NSDT1ExtendedDataLookups
        NSDataType1::objects()
            .select{|point| NSDT1ExtendedDataLookups::type1MatchesPattern(point, pattern) }
    end

    # NSDT1ExtendedDataLookups::selectNSDataType1sByPattern(pattern)
    def self.selectNSDataType1sByPattern(pattern)
        NSDataType1PatternSearchLookup::selectNSDataType1UUIDsByPattern(pattern)
            .map{|uuid| NSDataType1::getOrNull(uuid) }
            .compact
    end

    # NSDT1ExtendedDataLookups::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDT1ExtendedDataLookups::selectNSDataType1sByPattern(pattern)
            .map{|node|
                {
                    "description"   => NSDataType1::toString(node),
                    "referencetime" => NSDataType1::getReferenceUnixtime(node),
                    "dive"          => lambda{ NSDataType1::landing(node) }
                }
            }
    end
end

class NSDT1ExtendedUserInterface

    # NSDT1ExtendedUserInterface::interactiveSearch()
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
                selected_objects = GenericObjectInterface::applyDateTimeOrderToObjects(NSDT1ExtendedDataLookups::selectType1sPerPattern(pattern))

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

    # NSDT1ExtendedUserInterface::selectExistingType1InteractivelyOrNull()
    def self.selectExistingType1InteractivelyOrNull()
        nodes = NSDT1ExtendedUserInterface::interactiveSearch()
        return nil if nodes.empty?
        system("clear")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| NSDataType1::toString(node) })
    end

    # NSDT1ExtendedUserInterface::selectExistingOrMakeNewType1()
    def self.selectExistingOrMakeNewType1()
        node = NSDT1ExtendedUserInterface::selectExistingType1InteractivelyOrNull()
        return node if node
        return if !LucilleCore::askQuestionAnswerAsBoolean("You did not select an existing node. Would you like to make a new one ? : ")
        NSDataType1::issueNewNodeInteractivelyOrNull()
    end

    # NSDT1ExtendedUserInterface::interactiveSearchAndExplore()
    def self.interactiveSearchAndExplore()
        nodes = NSDT1ExtendedUserInterface::interactiveSearch()
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
