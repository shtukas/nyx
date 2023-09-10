
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

        Cubes::init("#{Config::userHomeDirectory()}/Desktop", "NxAvaldi", uuid)

        Cubes::setAttribute2(uuid, "unixtime", unixtime)
        Cubes::setAttribute2(uuid, "datetime", datetime)
        Cubes::setAttribute2(uuid, "description", description)

        Cubes::itemOrNull(uuid)
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

            item = Cubes::itemOrNull(item["uuid"])
            return if item.nil?

            system('clear')

            description  = item["description"]
            datetime     = item["datetime"]

            puts description.green
            puts "- uuid: #{item["uuid"]}"
            puts "- datetime: #{datetime}"

            store = ItemStore.new()

            notes = Cub3sX::getSet2(item["uuid"], "notes")
            if notes.size > 0 then
                puts ""
                puts "notes:"
                notes.each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{NxNotes::toString(note)}"
                }
            end

            linkednodes = Cub3sX::getSet2(item["uuid"], "linkeduuids").map{|id| Cubes::itemOrNull(id) }.compact
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
                Cubes::setAttribute2(item["uuid"], "description", description)
                next
            end

            if command == "access" then
                filepath = Cub3sX::uuidToFilepathOrNull(item["uuid"])
                if filepath.nil? then
                    puts "Cubes/Cub3sX could not find a filepath for this Avaldi"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                system("open '#{File.dirname(filepath)}'")
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
                Cub3sX::addToSet2(item["uuid"], "notes", note["uuid"], note)
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
