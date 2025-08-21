
class Fx35

    # ------------------------------------------------------
    # Interface

    # Fx35::issueNewToDesktop()
    def self.issueNewToDesktop()
        uuid = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "Fx35",
            "datetime"    => Time.new.utc.iso8601,
            "description" => nil,
            "linkeduuids" => [],
            "notes"       => [],
            "tags"        => [],
            "lastKnownLocation" => nil
        }
        filepath = "#{Config::userHomeDirectory()}/Desktop/Fx35.nyx-fx35.json"
        if File.exist?(filepath) then
            puts "There is a Fx35.nyx-fx35.json file on the Desktop, please remove it"
            LucilleCore::pressEnterToContinue()
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        ItemsDatabase::commitItem(item)
        item
    end

    # ------------------------------------------------------
    # Data

    # Fx35::description(item)
    def self.description(item)
        node["description"] ? "#{node["description"]}" : "(Fx35: #{item["uuid"]})"
    end

    # Fx35::toString(node)
    def self.toString(node)
        Fx35::description(item)
    end

    # Fx35::items()
    def self.items()
        ItemsDatabase::mikuType('Fx35')
    end

    # ------------------------------------------------------
    # Operations

    # Fx35::programNode(node, isSeekingSelect) # nil or node
    def self.programNode(node, isSeekingSelect)

        # isSeekingSelect: boolean
        # if isSeekingSelect is true, we are trying to identify a node, and in particular 
        # The caller will be paying attention to the return value.

        loop {

            node = ItemsDatabase::itemOrNull(node["uuid"])
            break if node.nil?

            system('clear')

            if isSeekingSelect then
                puts " ---------------------------"
                puts "| select                    |"
                puts " ---------------------------"
            end

            description  = Fx35::description(item)
            datetime     = node["datetime"]

            puts "- description: #{description.green}"
            puts "- mikuType   : #{node["mikuType"].green}"
            puts "- uuid       : #{node["uuid"]}"
            puts "- datetime   : #{datetime}"

            store = ListingStore.new()

            if node["notes"].size > 0 then
                puts ""
                puts "notes:"
                node["notes"].each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{NxNotes::toString(note)}"
                }
            end

            linkednodes = node["linkeduuids"].map{|id| ItemsDatabase::itemOrNull(id) }.compact
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
                node = PolyFunctions::programNode(item, isSeekingSelect)
                if node then
                    return node # was `select`ed
                end
                next
            end

            if command == "select" then
                return node
            end

            if command == "description" then
                description = CommonUtils::editTextSynchronously(node["description"])
                next if description == ""
                ItemsDatabase::setAttribute(node["uuid"], "description",description)
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
                Fx35::programPayload(node)
                next
            end

            if command == "connect" then
                returned_node = PolyFunctions::connect2(node, isSeekingSelect)
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
                    ItemsDatabase::setAttribute(node["uuid"], "notes", node["notes"])
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
                ItemsDatabase::deleteItem(node["uuid"])
                next
            end
        }

        nil
    end

    # Fx35::fsckItem(item)
    def self.fsckItem(item)
        if item["uuid"].nil? then
            raise "item: #{JSON.pretty_generate(item)} is missing its uuid"
        end
        if item["mikuType"].nil? then
            raise "item: #{JSON.pretty_generate(item)} is missing its mikuType"
        end
        if item["mikuType"] != 'Fx35' then
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

        # TODO: fsck the notes
        if item["notes"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a notes"
        end
        if item["notes"].class.to_s != "Array" then
            raise "item: #{JSON.pretty_generate(item)}'s notes is not an array"
        end
        item["notes"].each{|note|
            NxNotes::fsck(note)
        }

        # TODO: fsck the tags
        if item["tags"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a tags"
        end
        if item["tags"].class.to_s != "Array" then
            raise "item: #{JSON.pretty_generate(item)}'s tags is not an array"
        end

        # TODO: fsck the px44s
        if item["px44s"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a px44s"
        end
        if item["px44s"].class.to_s != "Array" then
            raise "item: #{JSON.pretty_generate(item)}'s px44s is not an array"
        end
        if item["px44s"].any?{|px44| px44.class.to_s != "Hash" } then
            puts "I have a node with what appears to be an incorrect px44s array"
            puts "node:"
            puts JSON.pretty_generate(item)
            if LucilleCore::askQuestionAnswerAsBoolean("Should I repair the array by discarding the non hash elements ? ") then
                item["px44s"] = item["px44s"].select{|element| element.class.to_s == "Hash" }
                puts "node (updated):"
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                ItemsDatabase::setAttribute(item["uuid"], "px44s", item["px44s"])
            end
        end
        item["px44s"].each{|px44|
            uuid = item["uuid"]
            Px44::fsck(uuid, px44)
        }
    end
end
