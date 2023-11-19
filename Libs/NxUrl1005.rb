
# encoding: UTF-8

class NxUrl1005

    # ------------------------------------
    # Makers

    # NxUrl1005::interactivelyIssueNewOrNull() # nil or node
    def self.interactivelyIssueNewOrNull()

        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        return nil if description == ""

        url = LucilleCore::askQuestionAnswerAsString("url: ")
        return nil if url == ""

        Broadcasts::publishItemInit(uuid, "NxUrl1005")
        Broadcasts::publishItemAttributeUpdate(uuid, "unixtime", unixtime)
        Broadcasts::publishItemAttributeUpdate(uuid, "datetime", datetime)
        Broadcasts::publishItemAttributeUpdate(uuid, "description", description)

        Broadcasts::publishItemAttributeUpdate(uuid, "url", url)
        Broadcasts::publishItemAttributeUpdate(uuid, "notes", [])
        Broadcasts::publishItemAttributeUpdate(uuid, "linkeduuids", [])

        node = ItemsDatabase::itemOrNull2(uuid)
        if node.nil? then
            raise "I could not recover newly created node: #{uuid}"
        end
        ItemsDatabase::itemOrNull2(uuid) # in case it was modified during the program dive
    end

    # ------------------------------------
    # Data

    # NxUrl1005::toString(node)
    def self.toString(node)
        "(url) #{node["description"]}"
    end

    # ------------------------------------
    # Operations

    # NxUrl1005::program(node) # nil or node (to get the node issue `select`)
    def self.program(node)
        loop {

            node = ItemsDatabase::itemOrNull2(node["uuid"])
            return if node.nil?

            system('clear')

            description  = node["description"]
            datetime     = node["datetime"]
            notes        = node["notes"] || []
            linkeduuids  = node["linkeduuids"] || []

            puts description.green
            puts "- uuid: #{node["uuid"]}"
            puts "- mikuType: #{node["mikuType"]}"
            puts "- datetime: #{datetime}"

            store = ItemStore.new()

            if notes.size > 0 then
                puts ""
                puts "notes:"
                notes.each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{NxNote::toString(note)}"
                }
            end

            linkednodes = linkeduuids.map{|id| ItemsDatabase::itemOrNull2(id) }.compact
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
            puts "commands: select | description | access | update (aion-point) | connect | disconnect | note | note remove | destroy"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                item = store.get(indx)
                next if item.nil?

                if item["mikuType"] == "NxCoreDataRef" then
                    reference = item
                    CoreDataRefsNxCDRs::program(node["uuid"], reference)
                    next
                end

                PolyActions::program(item)
                next
            end

            if command == "select" then
                return node
            end

            if command == "description" then
                description = CommonUtils::editTextSynchronously(node["description"])
                next if description == ""
                Broadcasts::publishItemAttributeUpdate(node["uuid"], "description", description)
                next
            end

            if command == "access" then
                url = node["url"]
                puts "url: #{url}"
                CommonUtils::openUrlUsingSafari(url)
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "update" then
                url = LucilleCore::askQuestionAnswerAsString("url: ")
                next if url == ""
                Broadcasts::publishItemAttributeUpdate(node["uuid"], "url", url)
                next
            end

            if command == "connect" then
                PolyFunctions::connect2(node)
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
                node["notes"] = (node["notes"] || []) + [note]
                Broadcasts::publishItemAttributeUpdate(node["uuid"], "notes", node["notes"])
                next
            end

            if command == "note remove" then
                puts "note remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "destroy" then
                PolyActions::destroy(node["uuid"], description)
                next
            end
        }

        nil
    end
end
