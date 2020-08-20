
class NSDT1SelectionDatabaseInterface

    # NSDT1SelectionDatabaseInterface::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/NSDT1-Selection-Database.sqlite3"
    end

    # NSDT1SelectionDatabaseInterface::selectNSDataType1UUIDsByPattern(pattern)
    def self.selectNSDataType1UUIDsByPattern(pattern)
        db = SQLite3::Database.new(NSDT1SelectionDatabaseInterface::databaseFilepath())
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

    # NSDT1SelectionDatabaseInterface::removeRecordsAgainstNode(objectuuid)
    def self.removeRecordsAgainstNode(objectuuid)
        db = SQLite3::Database.new(NSDT1SelectionDatabaseInterface::databaseFilepath())
        db.execute "delete from lookup where _objectuuid_=?", [objectuuid]
        db.close
    end

    # NSDT1SelectionDatabaseInterface::addRecord(objectuuid, fragment)
    def self.addRecord(objectuuid, fragment)
        db = SQLite3::Database.new(NSDT1SelectionDatabaseInterface::databaseFilepath())
        db.execute "insert into lookup (_objectuuid_, _fragment_) values ( ?, ? )", [objectuuid, fragment]
        db.close
    end

    # NSDT1SelectionDatabaseInterface::updateLookupForNode(node)
    def self.updateLookupForNode(node)
        NSDT1SelectionDatabaseInterface::removeRecordsAgainstNode(node["uuid"])
        NSDT1SelectionDatabaseInterface::addRecord(node["uuid"], node["uuid"])
        NSDT1SelectionDatabaseInterface::addRecord(node["uuid"], NSDataType1::toString(node))
    end

    # NSDT1SelectionDatabaseInterface::rebuildLookup()
    def self.rebuildLookup()
        db = SQLite3::Database.new(NSDT1SelectionDatabaseInterface::databaseFilepath())
        db.execute "delete from lookup", []
        db.close
        NSDataType1::objects()
        .each{|node|
            puts node["uuid"]
            NSDT1SelectionDatabaseInterface::updateLookupForNode(node)
        }
    end

end

class NSDT1SelectionCore

    # NSDT1SelectionCore::nodeMatchesPattern(point, pattern)
    # Legacy
    def self.nodeMatchesPattern(point, pattern)
        return true if point["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType1::toString(point).downcase.include?(pattern.downcase)
        return true if Arrows::getTargetsForSource(point).any?{|child| GenericObjectInterface::toString(child).downcase.include?(pattern.downcase) }
        false
    end

    # NSDT1SelectionCore::selectNodesPerPattern_v1(pattern)
    # Legacy
    def self.selectNodesPerPattern_v1(pattern)
        # 2020-08-15
        # This is a legacy function that I keep for sentimental reasons,
        # The direct look up using NSDT1SelectionCore::nodeMatchesPattern has been replace by NSDT1SelectionCore
        NSDataType1::objects()
            .select{|point| NSDT1SelectionCore::nodeMatchesPattern(point, pattern) }
    end

    # NSDT1SelectionCore::selectNodesPerPattern_v2(pattern)
    def self.selectNodesPerPattern_v2(pattern)
        NSDT1SelectionDatabaseInterface::selectNSDataType1UUIDsByPattern(pattern)
            .map{|uuid| NSDataType1::getOrNull(uuid) }
            .compact
    end

    # NSDT1SelectionCore::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDT1SelectionCore::selectNodesPerPattern_v2(pattern)
            .map{|node|
                {
                    "description"   => NSDataType1::toString(node),
                    "referencetime" => NSDataType1::getReferenceUnixtime(node),
                    "dive"          => lambda{ NSDataType1::landing(node) }
                }
            }
    end
end

class NSDT1NodeDisplayTree
    # NSDT1NodeDisplayTree::optimizeNodeOrderForTreeMaking(nodes)
    def self.optimizeNodeOrderForTreeMaking(nodes)
        nodes.reduce([]){|ns, node|
            if ns.any?{|n| NSDT1NodeDisplayTree::firstIsParentOfSecond(n, node) } then
                ns + [ node ]
            else
                [ node ] + ns
            end
        }
    end

    # NSDT1NodeDisplayTree::firstIsParentOfSecond(node1, node2)
    def self.firstIsParentOfSecond(node1, node2)
        Arrows::getTargetUUIDsForSource(node1).include?(node2["uuid"])
    end

    # NSDT1NodeDisplayTree::nodeToDisplayTreeNode(node)
    def self.nodeToDisplayTreeNode(node)
        {
            "node" => node,
            "children" => []
        }
    end

    # NSDT1NodeDisplayTree::reduceDisplayTreeNodeAndNode(displayTreeNode, node, depth)
    def self.reduceDisplayTreeNodeAndNode(displayTreeNode, node, depth)
        newDisplayTreeNode = 
            if NSDT1NodeDisplayTree::firstIsParentOfSecond(displayTreeNode["node"], node) then
                {
                    "node" => displayTreeNode["node"],
                    "children" => displayTreeNode["children"] + [ NSDT1NodeDisplayTree::nodeToDisplayTreeNode(node) ]
                }
            else
                {
                    "node" => displayTreeNode["node"],
                    "children" => displayTreeNode["children"].map{|dtn| NSDT1NodeDisplayTree::reduceDisplayTreeNodeAndNode(dtn, node, depth+1) }
                }
            end

        if depth == 0 and !newDisplayTreeNode.to_s.include?(node["uuid"]) then # I know....
            {
                "node" => displayTreeNode["node"],
                "children" => displayTreeNode["children"] + [ NSDT1NodeDisplayTree::nodeToDisplayTreeNode(node) ]
            }
        else
            newDisplayTreeNode
        end
    end

    # NSDT1NodeDisplayTree::displayTreeNode(displayTreeNode, padding, menuitems)
    def self.displayTreeNode(displayTreeNode, padding, menuitems)
        ordinal = menuitems.ordinal(lambda { displayTreeNode["node"] })
        puts "[#{ordinal.to_s.ljust(2)}] " + padding + NSDataType1::toString(displayTreeNode["node"])
        displayTreeNode["children"].each{|dtn|
            NSDT1NodeDisplayTree::displayTreeNode(dtn, padding + "    ", menuitems)
        }
    end

    # NSDT1NodeDisplayTree::nodesToDisplayTreeNode(nodes)
    def self.nodesToDisplayTreeNode(nodes)
        nodes = NSDT1NodeDisplayTree::optimizeNodeOrderForTreeMaking(nodes)
        rootDisplayTreeNode = {
            "node" => {
                "uuid"         => SecureRandom.hex,
                "nyxNxSet"     => "c18e8093-63d6-4072-8827-14f238975d04",
                "unixtime"     => 1597862159
            },
            "children" => []
        }
        nodes.reduce(rootDisplayTreeNode){|displayTreeNode, node|
            NSDT1NodeDisplayTree::reduceDisplayTreeNodeAndNode(displayTreeNode, node, 0)
        }
    end

    # The below was made as proof of concept. Might use it one day ^^

    # NSDT1NodeDisplayTree::selectOneNodeFromNodesOrNull(nodes)
    def self.selectOneNodeFromNodesOrNull(nodes)
        nodes = nodes.select{|node| NSDataType1::getOrNull(node["uuid"])}
        displayTreeNode = NSDT1NodeDisplayTree::nodesToDisplayTreeNode(nodes)
        menuitems = LCoreMenuItemsNX1.new()
        NSDT1NodeDisplayTree::displayTreeNode(displayTreeNode, "", menuitems)
        menuitems.promptAndRunFunctionGetValueOrNull() # returns a node or null
    end
end

class NSDT1SelectionInterface

    # NSDT1SelectionInterface::selectOneNodeFromNodesOrNull(nodes)
    def self.selectOneNodeFromNodesOrNull(nodes)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda { |node| NSDataType1::toString(node) })
    end

    # NSDT1SelectionInterface::sandboxSelectionOfOneExistingOrNewNodeOrNull()
    def self.sandboxSelectionOfOneExistingOrNewNodeOrNull()
        loop {
            system("clear")
            puts "[sandbox selection]"
            pattern = LucilleCore::askQuestionAnswerAsString("pattern: ")
            return nil if pattern == ""
            nodes = NSDT1SelectionCore::selectNodesPerPattern_v2(pattern)
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
        loop {
            system("clear")
            pattern = LucilleCore::askQuestionAnswerAsString("pattern: ")
            return nil if pattern == ""
            nodes = NSDT1SelectionCore::selectNodesPerPattern_v2(pattern)
            nodes = GenericObjectInterface::applyDateTimeOrderToObjects(nodes)
            next if nodes.empty?
            loop {
                nodes = nodes.select{|node| NSDataType1::getOrNull(node["uuid"])} # one could have been destroyed in the previous loop
                break if nodes.empty?
                system("clear")
                node = NSDT1SelectionInterface::selectOneNodeFromNodesOrNull(nodes)
                break if node.nil?
                NSDataType1::landing(node)
            }
        }
    end
end

class NSDT1NcursesSelectionInterface

    # NSDT1NcursesSelectionInterface::interactiveNodeNcursesSearch(): Array[Nodes]
    def self.interactiveNodeNcursesSearch()

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
                next if (Time.new.to_f - globalState["userSearchStringLastTimeUpdate"]) < 0.25
                next if !globalState["userSearchStringHasBeenModifiedSinceLastSearch"]


                pattern = globalState["userSearchString"]
                globalState["userSearchStringHasBeenModifiedSinceLastSearch"] = false

                win2UpdateStateToSearching.call()

                objects = GenericObjectInterface::applyDateTimeOrderToObjects(NSDT1SelectionCore::selectNodesPerPattern_v2(pattern))
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