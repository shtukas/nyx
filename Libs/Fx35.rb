
class Fx35FileSystemHelpers

    # Fx35FileSystemHelpers::locateOrNullUseTheForce(uuid)
    def self.locateOrNullUseTheForce(uuid)
        # This function take the uuid of a Fx35 and return the filepath where it is
        Find.find("#{Config::userHomeDirectory()}/Galaxy") do |path|
            if File.file?(path) then
                filepath = path
                if filepath[-14, 14] == ".nyx-fx35.json" then
                    node = JSON.parse(IO.read(filepath))
                    if node["uuid"] == uuid then
                        return filepath
                    end
                end
            end
        end
        nil
    end

    # Fx35FileSystemHelpers::locateOrNull(uuid)
    def self.locateOrNull(uuid)
        filepath = XCache::getOrNull("1a389ffa-2e8d-4b71-9694-4310a1ad44c1")
        if filepath and File.exist?(filepath) then
            node = JSON.parse(IO.read(filepath))
            if node["uuid"] == uuid then
                return filepath
            end
        end

        puts "Looking for Fx35 #{uuid}"
        filepath = Fx35FileSystemHelpers::locateOrNullUseTheForce(uuid)

        if filepath then
            XCache::set("1a389ffa-2e8d-4b71-9694-4310a1ad44c1", filepath)
        end

        filepath
    end

end

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
        item["description"] ? "#{item["description"]}" : "(Fx35: #{item["uuid"]})"
    end

    # Fx35::toString(item)
    def self.toString(item)
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

            description = Fx35::description(node)
            datetime    = node["datetime"]

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
                node = Nodes::program(item, isSeekingSelect)
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
                Nodes::setAttribute(node["uuid"], "description",description)
                next
            end

            if command == "access" then
                filepath = Fx35FileSystemHelpers::locateOrNull(node["uuid"])
                if filepath.nil? then
                    puts "I could not locate the file for Fx35 uuid"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                directory = File.dirname(filepath)

                # Let's update the description of the node in the database
                # if it has diverged from the name of the directory
                if node["description"] != File.basename(directory) then
                    node["description"] = File.basename(directory)
                    ItemsDatabase::commitItem(node)
                end

                puts "opening directory: #{directory}"
                system("open '#{directory}'")
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "payload" then
                Fx35::programPayload(node)
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

        Utils::fsckItemNotesAttribute(item)
        Utils::fsckItemTagsAttribute(item)
    end
end
