
# encoding: UTF-8

class Nyx

    # Nyx::program()
    def self.program()
        loop {
            system("clear")
            operations = [
                "search (interactive)",
                "search (fragment)",
                "new entity",
                "special ops"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "search (interactive)" then
                Search::funkyInterface()
            end
            if operation == "search (fragment)" then
                Search::searchClassic()
            end
            if operation == "new entity" then
                item = NyxNetwork::interactivelyMakeNewOrNull()
                next if item.nil?
                LxAction::action("landing", item)
            end
            if operation == "special ops" then
                specialOps = [
                    "listing per date fragment",
                    "make genesis point"
                ]
                op = LucilleCore::selectEntityFromListOfEntitiesOrNull("op", specialOps)
                if op == "listing per date fragment" then
                    fragment = LucilleCore::askQuestionAnswerAsString("fragment: ")
                    items = Nx31s::selectItemsByDateFragment(fragment)
                    loop {
                        item = NyxNetwork::selectEntityFromGivenEntitiesOrNull(items)
                        break if item.nil?
                        Nx31s::landing(item)
                    }
                end
                if op == "make genesis point" then
                    Nyx::makeGenesis()
                end
            end
        }
    end

    # Nyx::makeGenesis()
    def self.makeGenesis()

        # node1 is the aion point that should be a navigation point
        node1uuid = LucilleCore::askQuestionAnswerAsString("Principal uuid: ")
        node1 = Librarian6Objects::getObjectByUUIDOrNull(node1uuid)
        if node1.nil? then
            puts "I could not find a node for this uuid"
            LucilleCore::pressEnterToContinue()
            return
        end
        puts "node1:"
        puts JSON.pretty_generate(node1)
        if node1["mikuType"] != "Nx31" then
            puts "Are we intending to make that transformation with non Nx31 ?"
            LucilleCore::pressEnterToContinue()
            return
        end

        # atom1 is the atom of node1
        atom1 = Librarian6Objects::getObjectByUUIDOrNull(node1["atomuuid"])
        if atom1["type"] != "aion-point" then
            puts "Are we intending to make that transformation with an atom that is not a aion-point ?"
            LucilleCore::pressEnterToContinue()
            return
        end
        puts "atom1:"
        puts JSON.pretty_generate(atom1)

        # I am going to create a new node, call it Genesis, and will give it this atom

        node2 = {
          "uuid"        => SecureRandom.uuid,
          "mikuType"    => "Nx31",
          "description" => "Genesis",
          "unixtime"    => node1["unixtime"],
          "datetime"    => node1["datetime"],
          "atomuuid"    => atom1["uuid"]
        }
        puts "node2:"
        puts JSON.pretty_generate(node2)
        Librarian6Objects::commit(node2)

        # Going to create a navigation node, node3, with the same uuid as node1

        node3 = {
          "uuid"        => node1["uuid"],
          "mikuType"    => "Nx25",
          "unixtime"    => node1["unixtime"],
          "description" => node1["description"]
        }
        puts "node3:"
        puts JSON.pretty_generate(node3)
        Librarian6Objects::commit(node3)

        # We now link node3 (which is replacing node1) and node2 which is the Genesis node

        Links::link(node3["uuid"], node2["uuid"], 1)

    end
end
