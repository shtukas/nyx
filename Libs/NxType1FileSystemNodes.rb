
# encoding: UTF-8

class NxType1FileSystemNodes

    # ------------------------------------
    # Makers

    # NxType1FileSystemNodes::interactivelyIssueNewOrNull() # nil or node
    def self.interactivelyIssueNewOrNull()

        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::pressEnterToContinue("description (file system location) (empty to abort): ")
        return nil if description == ""

        Items::itemInit(uuid, "NxType1FileSystemNode")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "linkeduuids", [])
        Items::setAttribute(uuid, "notes", [])
        Items::setAttribute(uuid, "tags", [])

        node = Items::itemOrNull(uuid)

        NxType1FileSystemNodes::fsck(node)

        node

    end

    # ------------------------------------
    # Data

    # NxType1FileSystemNodes::toString(node)
    def self.toString(node)
        "📍 #{node["description"]}"
    end

    # ------------------------------------
    # Operations

    # NxType1FileSystemNodes::program(node) # nil or node (to get the node issue `select`)
    def self.program(node)
        loop {

            node = Items::itemOrNull(node["uuid"])
            return if node.nil?

            system('clear')

            description  = node["description"]
            datetime     = node["datetime"]

            puts "- description: #{node["description"].green}"
            puts "- mikuType   : #{node["mikuType"].green}"
            puts "- uuid       : #{node["uuid"]}"
            puts "- datetime   : #{datetime}"

            store = ItemStore.new()

            if node["notes"].size > 0 then
                puts ""
                puts "notes:"
                node["notes"].each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{NxNote::toString(note)}"
                }
            end

            linkednodes = node["linkeduuids"].map{|id| Items::itemOrNull(id) }.compact
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
            puts "commands: select | access | description | connect | disconnect | note | note remove | expose | destroy"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                item = store.get(indx)
                next if item.nil?
                NyxNodesGI::program(item)
                next
            end

            if command == "select" then
                return node
            end

            if command == "access" then
                puts "access has not been implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "description" then
                description = CommonUtils::editTextSynchronously(node["description"])
                next if description == ""
                Items::setAttribute(node["uuid"], "description", description)
                next
            end

            if command == "connect" then
                NyxNodesGI::connect2(node)
                next
            end

            if command == "disconnect" then
                puts "link remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "note" then
                note = NxNote::interactivelyIssueNewOrNull()
                next if note.nil?
                node["notes"] << note
                Items::setAttribute(node["uuid"], "notes", node["notes"])
                next
            end

            if command == "note remove" then
                puts "note remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "expose" then
                puts JSON.pretty_generate(node)
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "destroy" then
                Items::destroy(node["uuid"])
                next
            end
        }

        nil
    end

    # NxType1FileSystemNodes::fsck(item)
    def self.fsck(item)

    end
end
