
# encoding: UTF-8

class NxAvaldis

    # ------------------------------------
    # Makers

    # NxAvaldis::interactivelyIssueNewOrNull() # nil or item
    def self.interactivelyIssueNewOrNull()

        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        return nil if description == ""

        # We create Avaldies on the Desktop and then we move them to the target folder.

        PolyActions::init(uuid, "NxAvaldi")

        PolyActions::setAttribute2(uuid, "unixtime", unixtime)
        PolyActions::setAttribute2(uuid, "datetime", datetime)
        PolyActions::setAttribute2(uuid, "description", description)

        filepath = "#{Config::userHomeDirectory()}/Desktop/nyx-avalni-#{SecureRandom.hex(4)}.cub4x"
        File.open(filepath, "w"){|f| f.write(uuid) }
        puts "Move the NyxAvaldi file from the Desktop to its natural location"
        LucilleCore::pressEnterToContinue()

        PolyFunctions::itemOrNull2(uuid)
    end

    # ------------------------------------
    # Data

    # NxAvaldis::toString(item)
    def self.toString(item)
        "(item: avaldi) #{item["description"]}"
    end

    # ------------------------------------
    # Operations

    # NxAvaldis::program(item) # nil or item (to get the item issue `select`)
    def self.program(item)
        loop {

            item = PolyFunctions::itemOrNull2(item["uuid"])
            return if item.nil?

            system('clear')

            description  = item["description"]
            datetime     = item["datetime"]
            notes        = item["notes"] || []
            linkeduuids  = item["linkeduuids"] || []

            puts description.green
            puts "- uuid: #{item["uuid"]}"
            puts "- mikuType: #{item["mikuType"]}"
            puts "- datetime: #{datetime}"

            store = ItemStore.new()

            if notes.size > 0 then
                puts ""
                puts "notes:"
                notes.each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{NxNotes::toString(note)}"
                }
            end

            linkednodes = linkeduuids.map{|id| PolyFunctions::itemOrNull2(id) }.compact
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
            puts "commands: select | description | access | connect | disconnect | note | note remove | destroy"

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
                return item
            end

            if command == "description" then
                description = CommonUtils::editTextSynchronously(item["description"])
                next if description == ""
                PolyActions::setAttribute2(item["uuid"], "description", description)
                next
            end

            if command == "access" then
                # We are looking for a .cub4x files that contains the uuid of the item
                puts "locating .cub4x file..."
                filepath = Galaxy::cub4xFilepathOrNull(item["uuid"])
                if filepath.nil? then
                    puts "I could not locate the .cub4x file for this Avalni item"
                    LucilleCore::pressEnterToContinue()
                    next
                else
                    system("open '#{File.dirname(filepath)}'")
                end
                next
            end

            if command == "connect" then
                PolyFunctions::connect2(item)
                next
            end

            if command == "disconnect" then
                puts "link remove is not implemented yet for avaldi"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "note" then
                note = NxNotes::interactivelyIssueNewOrNull()
                next if note.nil?
                notes = item["notes"] + [note]
                PolyActions::setAttribute2(item["uuid"], "notes", notes)
            end

            if command == "note remove" then
                puts "note remove is not implemented yet for avaldi"
                LucilleCore::pressEnterToContinue()
            end

            if command == "destroy" then
                PolyActions::destroy(item["uuid"], description)
            end
        }

        nil
    end
end
