
# encoding: UTF-8

class NxNodes

    # ------------------------------------
    # Makers

    # NxNodes::NxNodesinteractivelyIssueNewNxNodeOrNull() # nil or node
    def self.NxNodesinteractivelyIssueNewNxNodeOrNull()

        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        return nil if description == ""

        Solingen::init("NxNode", uuid)
        Solingen::setAttribute2(uuid, "unixtime", unixtime)
        Solingen::setAttribute2(uuid, "datetime", datetime)
        Solingen::setAttribute2(uuid, "description", description)

        node = Solingen::getItemOrNull(uuid)
        if node.nil? then
            raise "I could not recover newly created node: #{uuid}"
        end
        NxNodes::landing(node)
    end

    # ------------------------------------
    # Data

    # ------------------------------------
    # Operations

    # NxNodes::landing(node) # nil or uuid2
    # This function is originally used as action, a landing, but can also return a uuid
    # when the user issues "fox", and this matters during a fox search
    def self.landing(node)
        uuid = node["uuid"]
        loop {

            system('clear')

            description = Solingen::getMandatoryAttribute2(uuid, "description")
            datetime = Solingen::getSet2(uuid, "datetime")
            coredatarefs = Solingen::getSet2(uuid, "NxCoreDataRefs")
            taxonomy = Solingen::getSet2(uuid, "taxonomy")
            notes = Solingen::getSet2(uuid, "notes")

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
                    puts "(#{store.prefixString()}) #{CoreDataRefs::toString(ref)}"
                }
            end

            if notes.size > 0 then
                puts ""
                puts "notes:"
                notes.each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{note["line"]}"
                }
            end

            linkednodes = Links::nodes(uuid)
            if linkednodes.size > 0 then
                puts ""
                linkednodes
                    .each{|linkednode|
                        store.register(linkednode, false)
                        puts "(#{store.prefixString()}) (node) #{linkednode["description"]}"
                    }
            end

            puts ""
            puts "commands: description | access | taxonomy | link add/remove | coredata add/remove | note add/remove | destroy"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                item = store.get(indx)
                next if item.nil?
                if item["mikuType"] == "NxNode" then
                    o = NxNodes::landing(item)
                    if o then
                        return o
                    end
                    next
                end
                if item["mikuType"] == "NxNote" then
                    NxNote::landing(item)
                end
                if item["mikuType"] == "NxCoreDataRef" then
                    CoreDataRefs::landing(item, node)
                end
                next
            end

            if command == "description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                next if description == ""
                Solingen::setAttribute2(uuid, "description", description)
                next
            end

            if command == "access" then
                coredatarefs = Solingen::getSet2(uuid, "NxCoreDataRefs")
                if coredatarefs.empty? then
                    puts "This node doesn't have any payload"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                if coredatarefs.size == 1 then
                    CoreDataRefs::access(uuid, coredatarefs.first)
                    next
                end
                coredataref = LucilleCore::selectEntityFromListOfEntitiesOrNull("ref", coredatarefs, lambda{|ref| CoreDataRefs::toString(ref) })
                next if coredataref.nil?
                CoreDataRefs::access(uuid, coredataref)
                next
            end

            if command == "taxonomy" then
                taxonomy = NxTaxonomies::selectOneTaxonomyOrNull()
                next if taxonomy.nil?
                Solingen::addToSet2(uuid, "taxonomy", taxonomy, taxonomy)
                next
            end

            if command == "link add" then
                node2 = NxNodes::architectNodeOrNull()
                if node2 then
                    Links::link(node["uuid"], node2["uuid"])
                    o = NxNodes::landing(node2)
                    if o then
                        return o
                    end
                end
                next
            end

            if command == "link remove" then
                puts "link remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "coredata add" then
                coredataref = CoreDataRefs::interactivelyMakeNewReferenceOrNull(uuid)
                next if coredataref.nil?
                Solingen::addToSet2(uuid, "NxCoreDataRefs", coredataref["uuid"], coredataref)
            end

            if command == "coredata remove" then
                puts "coredata remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "note add" then
                note = NxNote::makeNoteOrNull()
                next if note.nil?
                Solingen::addToSet2(uuid, "notes", note["uuid"], note)
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
                        Solingen::destroy(uuid)
                        return
                    end
                end
            end
        }

        nil
    end

    # NxNodes::interactivelySelectNodeOrNull()
    def self.interactivelySelectNodeOrNull()
        Search::select()
    end

    # NxNodes::architectNodeOrNull()
    def self.architectNodeOrNull()
        options = ["select || new", "new"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        return nil if option.nil?
        if option == "select || new" then
            node = NxNodes::interactivelySelectNodeOrNull()
            if node then
                return node
            end
            return NxNodes::NxNodesinteractivelyIssueNewNxNodeOrNull()
        end
        if option == "new" then
            return NxNodes::NxNodesinteractivelyIssueNewNxNodeOrNull()
        end
        nil
    end
end
