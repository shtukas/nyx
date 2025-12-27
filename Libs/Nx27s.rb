
class Nx27

    # ------------------------------------------------------
    # Interface

    # Nx27::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        return nil if description == ''
        px44 = Px44::interactivelyMakeNewOrNull(uuid)
        px44s = [px44].compact

        Blades::init(uuid)
        Blades::setAttribute(uuid, "datetime"    => Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description" => description)
        Blades::setAttribute(uuid, "px44s"       => px44s)
        Blades::setAttribute(uuid, "linkeduuids" => [])
        Blades::setAttribute(uuid, "notes"       => [])
        Blades::setAttribute(uuid, "tags"        => [])
        Blades::setAttribute(uuid, "mikuType"    => "Nx27")

        Blades::itemOrNull(uuid)
    end

    # ------------------------------------------------------
    # Data

    # Nx27::items()
    def self.items()
        Blades::mikuType('Nx27')
    end

    # Nx27::toString(node)
    def self.toString(node)
        "#{node["description"]}#{node["px44s"].map{|payload| Px44::toString(payload) }}"
    end

    # Nx27::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        Blades::itemOrNull(uuid)
    end

    # ------------------------------------------------------
    # Operations

    # Nx27::programPayload(node)
    def self.programPayload(node)
        loop {
            node = Blades::mikuType(node["uuid"])
            px44s = node["px44s"]
            puts "px44s (#{px44s.count} items):"
            px44s.each{|px44|
                puts "  - #{Px44::toString(px44)}"
            }
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull('option', ['access', 'add', 'remove'])
            break if option.nil?
            if option == 'access' then
                px44 = LucilleCore::selectEntityFromListOfEntitiesOrNull("px44", px44s, lambda{|px44| Px44::toString(px44) })
                next if px44.nil?
                Px44::access(node["uuid"], px44)
            end
            if option == 'add' then
                px44 = Px44::interactivelyMakeNewOrNull(node["uuid"])
                next if px44.nil?
                px44s << px44
                Nodes::setAttribute(node["uuid"], "px44s", px44s)
            end
            if option == 'remove' then
                px44 = LucilleCore::selectEntityFromListOfEntitiesOrNull("px44", px44s, lambda{|px44| Px44::toString(px44) })
                next if px44.nil?
                px44s = px44s.reject{|i| i["uuid"] == px44["uuid"] }
                Nodes::setAttribute(node["uuid"], "px44s", px44s)
            end
        }
    end

    # Nx27::program(node, isSeekingSelect) # nil or node
    def self.program(node, isSeekingSelect)

        # isSeekingSelect: boolean
        # if isSeekingSelect is true, we are trying to identify a node, and in particular 
        # The caller will be paying attention to the return value.

        loop {

            node = Nx27::itemOrNull(node["uuid"])
            break if node.nil?

            system('clear')

            if isSeekingSelect then
                puts " ---------------------------"
                puts "| select                    |"
                puts " ---------------------------"
            end

            description  = node["description"]
            datetime     = node["datetime"]

            puts "- description: #{node["description"].green}"
            puts "- mikuType   : #{node["mikuType"].green}"
            puts "- uuid       : #{node["uuid"]}"
            puts "- datetime   : #{datetime}"
            puts "- px44s      :"
            node["px44s"].each{|payload|
                puts "    - #{Px44::toString(payload).strip}"
            }

            store = ListingStore.new()

            if node["notes"].size > 0 then
                puts ""
                puts "notes:"
                node["notes"].each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{NxNotes::toString(note)}"
                }
            end

            linkednodes = node["linkeduuids"].map{|id| Nodes::itemOrNull(id) }.compact
            if linkednodes.size > 0 then
                puts ""
                puts "related nodes:"
                linkednodes
                    .each{|linkednode|
                        store.register(linkednode, false)
                        puts "(#{store.prefixString()}) (node) #{linkednode["description"]}"
                    }
            end

            if isSeekingSelect then
                puts ""
                puts "commands: #{"select".green} | description | access | payload | connect | disconnect | notes | expose | destroy"
            else
                puts ""
                puts "commands: description | access | payload | connect | disconnect | notes | expose | destroy"
            end

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                item = store.get(indx)
                next if item.nil?
                nx = Nodes::program(item, isSeekingSelect)
                if nx then
                    return nx # was `select`ed
                end
                next
            end

            if command == "select" then
                return node
            end

            if command == "description" then
                description = CommonUtils::editTextSynchronously(node["description"])
                next if description == ""
                Nodes::setAttribute(node["uuid"], "description",description)
                next
            end

            if command == "access" then
                px44s = node["px44s"]
                loop {
                    px44 = LucilleCore::selectEntityFromListOfEntitiesOrNull("px44", px44s, lambda{|px44| Px44::toString(px44) })
                    break if px44.nil?
                    Px44::access(node["uuid"], px44)
                }
                next
            end

            if command == "payload" then
                Nx27::programPayload(node)
                next
            end

            if command == "connect" then
                returned_node = Nodes::connect2(node, isSeekingSelect)
                if returned_node then
                    return returned_node # was `select`ed
                end
                next
            end

            if command == "disconnect" then
                puts "link remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "notes" then
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["add new note", "remove note"])
                next if option.nil?
                if option == "add new note" then
                    note = NxNotes::interactivelyIssueNewOrNull()
                    next if note.nil?
                    node["notes"] << note
                    Nodes::setAttribute(node["uuid"], "notes", node["notes"])
                end
                if option == "remove note" then
                    puts "note remove is not implemented yet"
                    LucilleCore::pressEnterToContinue()
                end
                next
            end

            if command == "expose" then
                puts JSON.pretty_generate(node)
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "destroy" then
                Nodes::deleteItem(node)
                next
            end
        }

        nil
    end

    # Nx27::fsckItem(item)
    def self.fsckItem(item)
        if item["uuid"].nil? then
            raise "item: #{JSON.pretty_generate(item)} is missing its uuid"
        end
        if item["mikuType"].nil? then
            raise "item: #{JSON.pretty_generate(item)} is missing its mikuType"
        end
        if item["mikuType"] != 'Nx27' then
            raise "item: #{JSON.pretty_generate(item)} does not have the correct mikuType"
        end
        if item["description"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a description"
        end
        if item["datetime"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a datetime"
        end

        if item["linkeduuids"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a linkeduuids"
        end
        if item["linkeduuids"].class.to_s != "Array" then
            raise "item: #{JSON.pretty_generate(item)}'s linkeduuids is not an array"
        end

        Fsck::fsckItemNotesAttribute(item)
        Fsck::fsckItemTagsAttribute(item)
        Fsck::fsckItemPx44Attribute(item)
    end
end
