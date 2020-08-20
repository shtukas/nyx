
class NSDT1SelectionDatabaseIO

    # NSDT1SelectionDatabaseIO::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/NSDT1-Selection-Database.sqlite3"
    end

    # NSDT1SelectionDatabaseIO::selectNSDataType1UUIDsByPattern(pattern)
    def self.selectNSDataType1UUIDsByPattern(pattern)
        db = SQLite3::Database.new(NSDT1SelectionDatabaseIO::databaseFilepath())
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

    # NSDT1SelectionDatabaseIO::removeRecordsAgainstNode(objectuuid)
    def self.removeRecordsAgainstNode(objectuuid)
        db = SQLite3::Database.new(NSDT1SelectionDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objectuuid_=?", [objectuuid]
        db.close
    end

    # NSDT1SelectionDatabaseIO::addRecord(objectuuid, fragment)
    def self.addRecord(objectuuid, fragment)
        db = SQLite3::Database.new(NSDT1SelectionDatabaseIO::databaseFilepath())
        db.execute "insert into lookup (_objectuuid_, _fragment_) values ( ?, ? )", [objectuuid, fragment]
        db.close
    end

    # NSDT1SelectionDatabaseIO::updateLookupForNode(node)
    def self.updateLookupForNode(node)
        NSDT1SelectionDatabaseIO::removeRecordsAgainstNode(node["uuid"])
        NSDT1SelectionDatabaseIO::addRecord(node["uuid"], node["uuid"])
        NSDT1SelectionDatabaseIO::addRecord(node["uuid"], NSDataType1::toString(node))
    end

    # NSDT1SelectionDatabaseIO::rebuildLookup()
    def self.rebuildLookup()
        db = SQLite3::Database.new(NSDT1SelectionDatabaseIO::databaseFilepath())
        db.execute "delete from lookup", []
        db.close
        NSDataType1::objects()
        .each{|node|
            puts node["uuid"]
            NSDT1SelectionDatabaseIO::updateLookupForNode(node)
        }
    end

    # NSDT1SelectionDatabaseIO::getDatabaseRecords(): Array[DatabaseRecord]
    # DatabaseRecord: [objectuuid: String, fragment: String]
    def self.getDatabaseRecords()
        db = SQLite3::Database.new(NSDT1SelectionDatabaseIO::databaseFilepath())
        db.results_as_hash = true
        answer = []
        db.execute( "select * from lookup" , [] ) do |row|
            answer << [row['_objectuuid_'], row['_fragment_']]
        end
        db.close
        answer
    end

end

class NSDT1DatabaseInMemory
    def initialize()
        @databaseRecords = NSDT1SelectionDatabaseIO::getDatabaseRecords()
                                .map{ |record| 
                                    record[1] = record[1].downcase
                                    record
                                }
        @supermap = {} # Map[ pattern: String, records: Array[DatabaseRecord] ]
        @cachedObjects = {} # Map[ uuid: String, node: Node ]
    end

    def patternAndRecordsToRecords(pattern, records)
        pattern = pattern.downcase
        @databaseRecords.select{|record| record[1].include?(pattern) }
    end

    def patternToRecords(pattern)
        if @supermap[pattern] then
            return @supermap[pattern]
        end

        minipattern = pattern[0, pattern.size-1]
        if @supermap[minipattern] then
            records = patternAndRecordsToRecords(pattern, @supermap[minipattern])
            @supermap[pattern] = records
            return records
        end

        records = patternAndRecordsToRecords(pattern, @databaseRecords)
        @supermap[pattern] = records
        records
    end

    def objectUUIDToObjectOrNull(objectuuid)
        if @cachedObjects[objectuuid] then
            return @cachedObjects[objectuuid]
        end
        node = NSDataType1::getOrNull(objectuuid)
        return nil if node.nil?
        @cachedObjects[objectuuid] = node
        node
    end

    def patternToNodes(pattern)
        patternToRecords(pattern)
            .map{|record| objectUUIDToObjectOrNull(record[0]) }
            .compact
    end
end

class NSDT1SelectionInterface

    # NSDT1SelectionInterface::selectOneNodeFromNodesOrNull(nodes)
    def self.selectOneNodeFromNodesOrNull(nodes)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda { |node| NSDataType1::toString(node) })
    end

    # NSDT1SelectionInterface::sandboxSelectionOfOneExistingOrNewNodeOrNull()
    def self.sandboxSelectionOfOneExistingOrNewNodeOrNull()
        databaseIM = NSDT1DatabaseInMemory.new()
        loop {
            system("clear")
            puts "[sandbox selection]"
            pattern = LucilleCore::askQuestionAnswerAsString("pattern: ")
            return nil if pattern == ""
            nodes = databaseIM.patternToNodes(pattern)
            nodes = GenericObjectInterface::applyDateTimeOrderToObjects(nodes)
            next if nodes.empty?
            node = NSDT1SelectionInterface::selectOneNodeFromNodesOrNull(nodes)
            next if node.nil?
            loop {
                system("clear")
                puts "[sandbox selection] selected: #{NSDataType1::toString(node)}"
                ops = [
                    "return this node", 
                    "landing", 
                    "back to search",
                    "make new node"
                ]
                op = LucilleCore::selectEntityFromListOfEntitiesOrNull("operations", ops)
                next if op.nil?
                if op == "return this node" then
                    return node
                end
                if op == "landing" then
                    KeyValueStore::destroy(nil, "d64d6e5e-9cc9-41b4-8c42-6062495ef546")
                    NSDataType1::landing(node)
                    # At this point another node could have been selected
                    xnode = KeyValueStore::getOrNull(nil, "d64d6e5e-9cc9-41b4-8c42-6062495ef546")
                    if xnode then
                        node = xnode
                        KeyValueStore::destroy(nil, "d64d6e5e-9cc9-41b4-8c42-6062495ef546")
                    end
                end
                if op == "back to search" then
                    break
                end
                if op == "make new node" then
                    x = NSDataType1::issueNewNodeInteractivelyOrNull()
                    if x then
                        node = x
                    end
                end
            }
        }
    end

    # NSDT1SelectionInterface::interactiveNodeSearchAndExplore()
    def self.interactiveNodeSearchAndExplore()
        databaseIM = NSDT1DatabaseInMemory.new()
        loop {
            system("clear")
            pattern = LucilleCore::askQuestionAnswerAsString("pattern: ")
            return nil if pattern == ""
            nodes = databaseIM.patternToNodes(pattern)
            #nodes = GenericObjectInterface::applyDateTimeOrderToObjects(nodes)
            next if nodes.empty?
            loop {
                #nodes = nodes.select{|node| NSDataType1::getOrNull(node["uuid"])} # one could have been destroyed in the previous loop
                break if nodes.empty?
                system("clear")
                node = NSDT1SelectionInterface::selectOneNodeFromNodesOrNull(nodes)
                break if node.nil?
                NSDataType1::landing(node)
            }
        }
    end

    # NSDT1SelectionInterface::interactiveNodeNcursesSearch(): Array[Nodes]
    def self.interactiveNodeNcursesSearch()

        databaseIM = NSDT1DatabaseInMemory.new()

        Curses::init_screen
        # Initializes a standard screen. At this point the present state of our terminal is saved and the alternate screen buffer is turned on

        Curses::noecho
        # Disables characters typed by the user to be echoed by Curses.getch as they are typed.

        globalState = {
            "userSearchString" => "",
            "userSearchStringLastTimeUpdate" => nil,
            "userSearchStringHasBeenModifiedSinceLastSearch" => false,
            "selectedObjets" => []
        }

        win1 = Curses::Window.new(1, Miscellaneous::screenWidth(), 0, 0)
        win2 = Curses::Window.new(1, Miscellaneous::screenWidth(), 1, 0)
        win3 = Curses::Window.new(Miscellaneous::screenHeight()-2, Miscellaneous::screenWidth(), 2, 0)

        win1.refresh
        win2.refresh
        win3.refresh

        win1UpdateState = lambda {
            win1.setpos(0,0)
            win1.deleteln()
            win1 << ("-> " + globalState["userSearchString"])
            win1.refresh
        }

        win2UpdateStateToSearching = lambda {
            win2.setpos(0,0)
            win2.deleteln()
            win2 << "searching @ #{Time.new.to_s}"
            win2.refresh
        }
        win2UpdateStateToNotSearching = lambda {
            win2.setpos(0,0)
            win2.deleteln()
            win2.refresh
        }

        thread4 = Thread.new {
            loop {
                sleep 0.01

                next if globalState["userSearchString"].size < 3 
                next if globalState["userSearchStringLastTimeUpdate"].nil?
                next if !globalState["userSearchStringHasBeenModifiedSinceLastSearch"]

                pattern = globalState["userSearchString"]
                globalState["userSearchStringHasBeenModifiedSinceLastSearch"] = false

                win2UpdateStateToSearching.call()

                objects = databaseIM.patternToNodes(pattern)
                globalState["selectedObjets"] = objects

                win3.setpos(0,0)
                objects.first(Miscellaneous::screenHeight()-3).each{|object|
                    win3.deleteln()
                    win3 << "#{NSDataType1::toString(object)}\n"
                }
                (win3.maxy - win3.cury).times {win3.deleteln()}
                win3.refresh

                win2UpdateStateToNotSearching.call()
                win1UpdateState.call()
            }
        }

        win1UpdateState.call()

        loop {
            char = win1.getch.to_s # Reads and return a character non blocking

            next if char.size == 0

            if char == '127' then
                # delete
                next if globalState["userSearchString"].length == 0
                globalState["userSearchString"] = globalState["userSearchString"][0, globalState["userSearchString"].length-1]
                globalState["userSearchStringHasBeenModifiedSinceLastSearch"] = true
                globalState["userSearchStringLastTimeUpdate"] = Time.new.to_f

                win1UpdateState.call()
                next
            end

            if char == '10' then
                # enter
                break
            end

            globalState["userSearchString"] = globalState["userSearchString"] + char
            globalState["userSearchStringHasBeenModifiedSinceLastSearch"] = true
            globalState["userSearchStringLastTimeUpdate"] = Time.new.to_f
            win1UpdateState.call()
        }

        Thread.kill(thread4)

        win1.close
        win2.close
        win3.close

        Curses::close_screen # this method restore our terminal's settings

        return globalState["selectedObjets"]
    end
end