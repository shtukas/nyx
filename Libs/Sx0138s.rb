
# encoding: UTF-8

class Sx0138s

    # ------------------------------------
    # Makers

    # Sx0138s::interactivelyIssueNewOrNull() # nil or node
    def self.interactivelyIssueNewOrNull()

        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        return nil if description == ""

        payload = Px44::interactivelyMakeNewOrNull()

        Items::itemInit(uuid, "Sx0138")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload", payload)
        Items::setAttribute(uuid, "linkeduuids", [])
        Items::setAttribute(uuid, "notes", [])
        Items::setAttribute(uuid, "tags", [])

        node = Items::itemOrNull(uuid)

        Sx0138s::fsck(node)

        node
    end

    # ------------------------------------
    # Data

    # Sx0138s::toString(node)
    def self.toString(node)
        "#{node["description"]}#{Px44::toStringSuffix(node["payload"])}"
    end

    # ------------------------------------
    # Operations

    # Sx0138s::program(node) # nil or node (to get the node issue `select`)
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
            puts "- payload    : #{Px44::toStringSuffix(node["payload"]).strip}"

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
            puts "commands: select | description | access | payload | connect | disconnect | note | note remove | expose | destroy"

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

            if command == "description" then
                description = CommonUtils::editTextSynchronously(node["description"])
                next if description == ""
                Items::setAttribute(node["uuid"], "description",description)
                next
            end

            if command == "access" then
                Px44::access(node["payload"])
                next
            end

            if command == "payload" then
                payload = Px44::interactivelyMakeNewOrNull()
                next if payload.nil?
                Items::setAttribute(node["uuid"], "payload",payload)
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

    # Sx0138s::fsck(item)
    def self.fsck(item)
        if item["payload"] then
            Px44::fsck(item["payload"])
        end
    end
end
