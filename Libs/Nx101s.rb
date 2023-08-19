
# encoding: UTF-8

class NxNotes

    # ------------------------------------
    # Makers

    # NxNotes::interactivelyIssueNewOrNull() # nil or node
    def self.interactivelyIssueNewOrNull()
        text = CommonUtils::editTextSynchronously("")
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxNote",
            "unixtime" => Time.new.to_i,
            "text"     => text
        }
    end

    # ------------------------------------
    # Data

    # NxNotes::toString(note)
    def self.toString(note)
        lines = note["text"].strip.lines
        if lines.empty? then
            return "(empty note)"
        end
        "(note) #{lines.first}"
    end

    # ------------------------------------
    # Operations

    # NxNotes::program(note)
    def self.program(note)
        loop {
            system('clear')

            puts "--------------------------------------"
            puts note["text"]
            puts "--------------------------------------"

            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["edit"])
            return if action.nil?
            if action == "edit" then
                puts "edit is actually not yet impemented"
                LucilleCore::pressEnterToContinue()
            end
        }
        nil
    end
end

class Nx101s

    # ------------------------------------
    # Makers

    # Nx101s::interactivelyIssueNewOrNull() # nil or node
    def self.interactivelyIssueNewOrNull()

        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        return nil if description == ""

        Cubes::init(nil, "Nx101", uuid)
        Cubes::setAttribute2(uuid, "unixtime", unixtime)
        Cubes::setAttribute2(uuid, "datetime", datetime)
        Cubes::setAttribute2(uuid, "description", description)

        Cubes::setAttribute2(uuid, "coreDataRefs", [])
        Cubes::setAttribute2(uuid, "taxonomy", [])
        Cubes::setAttribute2(uuid, "notes", [])
        Cubes::setAttribute2(uuid, "linkeduuids", [])

        node = Cubes::itemOrNull(uuid)
        if node.nil? then
            raise "I could not recover newly created node: #{uuid}"
        end
        Nx101s::program(node)
        Cubes::itemOrNull(uuid) # in case it was modified during the program dive
    end

    # ------------------------------------
    # Data

    # Nx101s::toString(node)
    def self.toString(node)
        "(node) #{node["description"]}"
    end

    # ------------------------------------
    # Operations

    # Nx101s::program(node) # nil or node (to get the node issue `select`)
    def self.program(node)
        uuid = node["uuid"]
        loop {

            system('clear')

            description  = node["description"]
            datetime     = node["datetime"]
            coredatarefs = node["coreDataRefs"]
            taxonomy     = node["taxonomy"]
            notes        = node["notes"]
            linkeduuids  = node["linkeduuids"]

            puts description.green
            puts "- uuid: #{uuid}"
            puts "- datetime: #{datetime}"
            puts "- taxonomy: #{taxonomy.join(", ")}"
            if taxonomy.size == 0 then
                puts "You do not have a taxonomy, run `taxonomy`"
            end

            store = ItemStore.new()

            if coredatarefs.size > 0 then
                puts ""
                puts "coredatarefs:"
                coredatarefs.each{|ref|
                    store.register(ref, false)
                    puts "(#{store.prefixString()}) #{CoreDataRefsNxCDRs::toString(ref)}"
                }
            end

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
                        puts "(#{store.prefixString()}) (node) #{linkednode["description"]}"
                    }
            end

            puts ""
            puts "commands: description | access | taxonomy | connect | disconnect | coredata | coredata remove | note | note remove | destroy"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                item = store.get(indx)
                next if item.nil?
                if item["mikuType"] == "Nx101" then
                    x = Nx101s::program(item)
                    if x then
                        return x # was selected during a dive
                    end
                end
                if item["mikuType"] == "NxNote" then
                    NxNotes::program(item)
                end
                if item["mikuType"] == "NxCoreDataRef" then
                    reference = item
                    CoreDataRefsNxCDRs::program(node["uuid"], reference)
                end
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
                coredatarefs = node["coreDataRefs"]
                if coredatarefs.empty? then
                    puts "This node doesn't have any payload"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                if coredatarefs.size == 1 then
                    CoreDataRefsNxCDRs::access(node["uuid"], coredatarefs.first)
                    next
                end
                coredataref = LucilleCore::selectEntityFromListOfEntitiesOrNull("ref", coredatarefs, lambda{|ref| CoreDataRefsNxCDRs::toString(ref) })
                next if coredataref.nil?
                CoreDataRefsNxCDRs::access(node["uuid"], coredataref)
                next
            end

            if command == "taxonomy" then
                taxonomy = NxTaxonomies::selectOneTaxonomyOrNull()
                next if taxonomy.nil?
                node["taxonomy"] = (node["taxonomy"] + [taxonomy]).uniq
                Cubes::setAttribute2(node["uuid"], "taxonomy", node["taxonomy"])
                next
            end

            if command == "connect" then
                node2 = Nx101s::architectNodeOrNull()
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
                node["notes"] = node["notes"] + [note]
                Cubes::setAttribute2(node["uuid"], "notes", node["notes"])
            end

            if command == "note remove" then
                puts "note remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
            end

            if command == "destroy" then
                puts "> request to destroy nyx node: #{description}"
                code1 = SecureRandom.hex(2)
                code2 = LucilleCore::askQuestionAnswerAsString("Enter destruction code (#{code1}): ")
                if code1 == code2 then
                    if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction: ") then
                        Cubes::destroy(uuid)
                        return
                    end
                end
            end
        }

        nil
    end

    # Nx101s::getNodeOrNullUsingSelectionAndNavigation() nil or node
    def self.getNodeOrNullUsingSelectionAndNavigation()
        puts "get node using selection and navigation".green
        sleep 0.5
        loop {
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort and return null) : ")
            return nil if fragment == ""
            loop {
                selected = Cubes::mikuType('Nx101')
                            .select{|node| Search::match(node, fragment) }

                if selected.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                        break
                    else
                        return nil
                    end
                else
                    selected = selected.select{|node| Cubes::itemOrNull(node["uuid"]) } # In case something has changed, we want the ones that have survived
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|i| i["description"] })
                    if node.nil? then
                        if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                            break
                        else
                            return nil
                        end
                    end
                    node = Nx101s::program(node)
                    if node then
                        return node # was `select`ed
                    end
                end
            }
        }
    end

    # Nx101s::architectNodeOrNull()
    def self.architectNodeOrNull()
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["search and maybe `select`", "build and return"])
            return nil if option.nil?
            if option == "search and maybe `select`" then
                node = Nx101s::getNodeOrNullUsingSelectionAndNavigation()
                if node then
                    return node
                end
            end
            if option == "build and return" then
                node = Nx101s::interactivelyIssueNewOrNull()
                if node then
                    return node
                end
            end
        }
    end
end
