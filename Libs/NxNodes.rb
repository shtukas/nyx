
class NxNodes

    # NxNodes::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        filepath = Blades::makeNewFileForInProgressNodeCreation(uuid)
        mikuType = "NxNode28"
        datetime = Time.new.utc.iso8601
        description = LucilleCore::pressEnterToContinue("description (empty to abort): ")
        if description == '' then
            FileUtils.rm(filepath)
            return nil
        end
        payload = Px44::interactivelyMakeNewOrNull(uuid)

        payloads    = [payload].compact
        linkeduuids = []
        notes       = []
        tags        = []
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxNode28",
            "datetime"    => datetime,
            "description" => description,
            "payloads"    => payloads,
            "linkeduuids" => linkeduuids,
            "notes"       => notes,
            "tags"        => tags
        }

        Blades::commitItemToItsBladeFile(item)

        HardProblem::nodeHasBeenCreated(item)

        item
    end

    # -----------------------------------------------
    # Data

    # NxNodes::toString(node)
    def self.toString(node)
        "#{node["description"]}#{node["payloads"].map{|payload| Px44::toString(payload) }}"
    end

    # NxNodes::items()
    def self.items()
        HardProblem::nodes()
    end

    # -----------------------------------------------
    # Operations

    # NxNodes::fsckNxNode(node28)
    def self.fsckNxNode(node28)
        if node28["uuid"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} is missing its uuid"
        end
        if node28["mikuType"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} is missing its mikuType"
        end
        if node28["mikuType"] != 'NxNode28' then
            raise "node28: #{JSON.pretty_generate(node28)} does not have the correct mikuType"
        end
        if node28["description"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a description"
        end
        if node28["datetime"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a datetime"
        end

        if node28["linkeduuids"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a linkeduuids"
        end
        if node28["linkeduuids"].class.to_s != "Array" then
            raise "node28: #{JSON.pretty_generate(node28)}'s linkeduuids is not an array"
        end

        # TODO: fsck the notes
        if node28["notes"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a notes"
        end
        if node28["notes"].class.to_s != "Array" then
            raise "node28: #{JSON.pretty_generate(node28)}'s notes is not an array"
        end
        node28["notes"].each{|note|
            NxNotes::fsck(note)
        }

        # TODO: fsck the tags
        if node28["tags"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a tags"
        end
        if node28["tags"].class.to_s != "Array" then
            raise "node28: #{JSON.pretty_generate(node28)}'s tags is not an array"
        end

        # TODO: fsck the payloads
        if node28["payloads"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a payloads"
        end
        if node28["payloads"].class.to_s != "Array" then
            raise "node28: #{JSON.pretty_generate(node28)}'s payloads is not an array"
        end
        node28["payloads"].each{|px44|
            uuid = node28["uuid"]
            Px44::fsck(uuid, px44)
        }
    end

    # NxNodes::program(node) # nil or node (to get the node issue `select`)
    def self.program(node)
        loop {

            node = Blades::getItemOrNull(node["uuid"])
            return if node.nil?

            system('clear')

            description  = node["description"]
            datetime     = node["datetime"]

            puts "- description: #{node["description"].green}"
            puts "- mikuType   : #{node["mikuType"].green}"
            puts "- uuid       : #{node["uuid"]}"
            puts "- datetime   : #{datetime}"
            puts "- payloads   :"
            node["payloads"].each{|payload|
                puts "    - #{Px44::toString(payload).strip}"
            }

            store = ItemStore.new()

            if node["notes"].size > 0 then
                puts ""
                puts "notes:"
                node["notes"].each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{NxNotes::toString(note)}"
                }
            end

            linkednodes = node["linkeduuids"].map{|id| Blades::getItemOrNull(id) }.compact
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
            puts "commands: select | description | access | payloads | connect | disconnect | note | note remove | expose | destroy"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                item = store.get(indx)
                next if item.nil?
                PolyFunctions::program(item)
                next
            end

            if command == "select" then
                return node
            end

            if command == "description" then
                description = CommonUtils::editTextSynchronously(node["description"])
                next if description == ""
                Blades::setAttribute(node["uuid"], "description",description)
                next
            end

            if command == "access" then
                node["payloads"].each{|payload|
                    Px44::access(node["uuid"], payload)
                }
                next
            end

            if command == "payloads" then
                payload = Px44::interactivelyMakeNewOrNull(node["uuid"])
                next if payload.nil?
                node["payloads"] << payload
                Blades::setAttribute(node["uuid"], "payloads", node["payloads"])
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
                note = NxNotes::interactivelyIssueNewOrNull()
                next if note.nil?
                node["notes"] << note
                Blades::setAttribute(node["uuid"], "notes", node["notes"])
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
                Blades::destroy(node["uuid"])
                next
            end
        }

        nil
    end
end
