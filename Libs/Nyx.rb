
# encoding: UTF-8

class Nyx

    # Nyx::program()
    def self.program()
        loop {
            system("clear")
            operations = [
                "search (all)",
                "search classic (fragment)",
                "new entity",
                "special ops"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "search (all)" then
                Search::funkyInterface()
            end
            if operation == "search classic (fragment)" then
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
                    "make genesis point",
                    "load children from folder locations"
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
                if op == "load children from folder locations" then
                    Nyx::loadChildrenFromFolderLocations()
                end
            end
        }
    end

    # Nyx::loadChildrenFromFolderLocations()
    def self.loadChildrenFromFolderLocations()
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

        envelopFolder = LucilleCore::askQuestionAnswerAsString("envelop folder: ")
        if !File.exists?(envelopFolder) then
            puts "I could not see the envelop folder"
            LucilleCore::pressEnterToContinue()
            return
        end

        makeNode = lambda {|location|
            description = File.basename(location)

            atom = Librarian5Atoms::makeAionPointAtomUsingLocation(location)
            Librarian6Objects::commit(atom)

            uuid       = SecureRandom.uuid
            unixtime   = Time.new.to_i
            datetime   = Time.new.utc.iso8601

            node = {
              "uuid"        => uuid,
              "mikuType"    => "Nx31",
              "description" => description,
              "unixtime"    => unixtime,
              "datetime"    => datetime,
              "atomuuid"    => atom["uuid"]
            }
            Librarian6Objects::commit(node)
            node
        }

        LucilleCore::locationsAtFolder(envelopFolder).each{|location|
            node2 = makeNode.call(location)
            puts JSON.pretty_generate(node2)
            Links::link(node1["uuid"], node2["uuid"], false)
            sleep 2
        }
    end
end
