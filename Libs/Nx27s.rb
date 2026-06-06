
class Nx27

    # ------------------------------------------------------
    # Interface

    # Nx27::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        return nil if description == ''
        Px44::interactivelyIssueNewOrNull(uuid)
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime"   , Time.new.to_i)
        Items::setAttribute(uuid, "datetime"   , Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "linkeduuids", [])
        Items::setAttribute(uuid, "notes"      , [])
        Items::setAttribute(uuid, "tags"       , [])
        Items::setAttribute(uuid, "mikuType"   , "Nx27")
        Items::getItemOrNull(uuid)
    end

    # ------------------------------------------------------
    # Data

    # Nx27::items()
    def self.items()
        Items::getMikuType('Nx27')
    end

    # Nx27::toString(node)
    def self.toString(node)
        "#{node["description"]}"
    end

    # ------------------------------------------------------
    # Operations

    # Nx27::program(node, isSeekingSelect) # nil or node
    def self.program(node, isSeekingSelect)

        # isSeekingSelect: boolean
        # if isSeekingSelect is true, we are trying to identify a node, and in particular 
        # The caller will be paying attention to the return value.

        loop {

            node = Items::getItemOrNull(node["uuid"])
            break if node.nil?

            system('clear')

            if isSeekingSelect then
                puts " ---------------------------"
                puts "| select                    |"
                puts " ---------------------------"
            end

            store = ListingStore.new()

            description  = node["description"]
            datetime     = node["datetime"]

            puts "description: #{node["description"].green}"
            puts "mikuType   : #{node["mikuType"].green}"
            puts "uuid       : #{node["uuid"]}"
            puts "datetime   : #{datetime}"
            puts "px44s      :"
            Px44::px44sForNode(node["uuid"]).each{|px44|
                store.register(px44)
                puts "    - [#{store.prefixString()}] #{Px44::toString(px44).strip}"
            }

            if (node["notes"] || []).size > 0 then
                puts ""
                puts "notes:"
                node["notes"].each{|note|
                    store.register(note)
                    puts "(#{store.prefixString()}) #{NxNotes::toString(note)}"
                }
            end

            linkednodes = (node["linkeduuids"] || []).map{|id| Items::getItemOrNull(id) }.compact
            if linkednodes.size > 0 then
                puts ""
                puts "linked nodes:"
                linkednodes
                    .each{|linkednode|
                        store.register(linkednode)
                        puts "    - [#{store.prefixString()}] (node) #{linkednode["description"]}"
                    }
            end

            if isSeekingSelect then
                puts ""
                puts "commands: #{"select".green} | description | access | payload | connect | disconnect | notes | expose | destroy"
            else
                puts ""
                puts "commands: description | payload | connect | disconnect | notes | expose | destroy"
            end

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                item = store.get(indx)
                next if item.nil?
                nx = PolyActions::programGeneralItem(item, isSeekingSelect)
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
                # Items::setAttribute returns an item, because it may not be the item that 
                # was submitted, in case we had to do a reconciliation
                node = Items::setAttribute(node["uuid"], "description",description)
                next
            end

            if command == "payload" then
                Px44::programNodePx44s(node)
                next
            end

            if command == "connect" then
                returned_node = PolyActions::connect2(node, isSeekingSelect)
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
                    (node["notes"] || []) << note

                    # Items::setAttribute returns an item, because it may not be the item that 
                    # was submitted, in case we had to do a reconciliation
                    node = Items::setAttribute(node["uuid"], "notes", node["notes"])
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
                Items::deleteItem(node["uuid"])
                next
            end
        }

        nil
    end

    # Nx27::fsck(item)
    def self.fsck(item)
        if item["uuid"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a uuid"
        end
        if item["mikuType"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a mikuType"
        end
        if item["mikuType"] != 'Nx27' then
            raise "item: #{JSON.pretty_generate(item)} does not have the correct mikuType"
        end
        if item["unixtime"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a unixtime"
        end
        if item["datetime"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a datetime"
        end
        if item["description"].nil? then
            raise "item: #{JSON.pretty_generate(item)} does not have a description"
        end

        (item["px44s"] || []).each{|px44|
            Px44::fsck(px44)
        }

        (item["notes"] || []).each{|note|
            NxNotes::fsck(note)
        }
    end
end
