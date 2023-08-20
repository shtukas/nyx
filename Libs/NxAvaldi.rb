
# encoding: UTF-8

class NxAvaldis

    # ------------------------------------
    # Makers

    # NxAvaldis::interactivelyIssueNewOrNull() # nil or node
    def self.interactivelyIssueNewOrNull()

        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        return nil if description == ""

        # We create Avaldies on the Desktop and then we move them to the target folder.

        Cubes::init("#{Config::userHomeDirectory()}/Desktop", "NxAvaldi", uuid)

        Cubes::setAttribute2(uuid, "unixtime", unixtime)
        Cubes::setAttribute2(uuid, "datetime", datetime)
        Cubes::setAttribute2(uuid, "description", description)

        Cubes::itemOrNull(uuid)
    end

    # ------------------------------------
    # Data

    # NxAvaldis::toString(node)
    def self.toString(node)
        "(node: avaldi) #{node["description"]}"
    end

    # ------------------------------------
    # Operations

    # NxAvaldis::program(item) # nil or item (to get the item issue `select`)
    def self.program(item)
        uuid = item["uuid"]
        loop {

            system('clear')

            description  = item["description"]
            datetime     = item["datetime"]
            taxonomy     = Cub3sX::getSet2(uuid, "taxonomy")
            notes        = Cub3sX::getSet2(uuid, "notes")
            linkeduuids  = Cub3sX::getSet2(uuid, "linkeduuids")

            puts description.green
            puts "- uuid: #{uuid}"
            puts "- datetime: #{datetime}"
            
            if taxonomy.size == 0 then
                puts "You do not have a taxonomy, run `taxonomy`"
            else
                puts "- taxonomy: #{taxonomy.join(", ")}"
            end

            store = ItemStore.new()

            if notes.size > 0 then
                puts ""
                puts "notes:"
                notes.each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{NxNotes::toString(note)}"
                }
            end

            linkednodes = linkeduuids.map{|id| Cubes::itemOrNull(id) }.compact
            if linkednodes.size > 0 then
                puts ""
                puts "related nodes:"
                linkednodes
                    .each{|linkednode|
                        store.register(linkednode, false)
                        puts "(#{store.prefixString()}) #{PolyFunctions::toString(linkednode)}"
                    }
            end

            puts ""
            puts "commands: description | access | taxonomy | connect | disconnect | note | note remove | destroy"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                item = store.get(indx)
                next if item.nil?
                PolyActions::program(item)
                next
            end

            if command == "select" then
                return node
            end

            if command == "description" then
                description = CommonUtils::editTextSynchronously(node["description"])
                next if description == ""
                Cubes::setAttribute2(uuid, "description", description)
                next
            end

            if command == "access" then
                filepath = Cub3sX::uuidToFilepathOrNull(item["uuid"])
                if filepath.nil? then
                    puts "Cubes/Cub3sX could not find a filepath for this Avaldi"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                system("open '#{File.dirname(filepath)}'")
                next
            end

            if command == "taxonomy" then
                taxonomy = NxTaxonomies::selectOneTaxonomyOrNull()
                next if taxonomy.nil?
                Cub3sX::addToSet2(item["uuid"], "taxonomy", taxonomy, taxonomy)
                next
            end

            if command == "connect" then
                node2 = PolyFunctions::architectNodeOrNull()
                if node2 then
                    node["linkeduuids"] = (node["linkeduuids"] + [node2["uuid"]]).uniq
                    Cubes::setAttribute2(node["uuid"], "linkeduuids", node["linkeduuids"])

                    node2["linkeduuids"] = (node2["linkeduuids"] + [node["uuid"]]).uniq
                    Cubes::setAttribute2(node2["uuid"], "linkeduuids", node2["linkeduuids"])
                end
                next
            end

            if command == "disconnect" then
                puts "link remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "coredata" then
                coredataref = CoreDataRefsNxCDRs::interactivelyMakeNewReferenceOrNull(node["uuid"])
                next if coredataref.nil?
                node["coreDataRefs"] = (node["coreDataRefs"] + [coredataref]).uniq
                Cubes::setAttribute2(node["uuid"], "coreDataRefs", node["coreDataRefs"])
            end

            if command == "coredata remove" then
                puts "coredata remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "note" then
                note = NxNotes::interactivelyIssueNewOrNull()
                next if note.nil?
                Cub3sX::addToSet2(item["uuid"], "notes", note["uuid"], note)
            end

            if command == "note remove" then
                puts "note remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
            end

            if command == "destroy" then
                PolyActions::destroy(uuid, description)
            end
        }

        nil
    end
end
