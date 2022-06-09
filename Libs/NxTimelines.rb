
# encoding: UTF-8

class NxTimelines

    # ----------------------------------------------------------------------
    # IO

    # NxTimelines::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxTimeline")
    end

    # NxTimelines::getOrNull(uuid): null or NxTimeline
    def self.getOrNull(uuid)
        Librarian::getObjectByUUIDOrNull(uuid)
    end

    # NxTimelines::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxTimelines::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTimeline",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
        }
        Librarian::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxTimelines::toString(item)
    def self.toString(item)
        "(timeline) #{item["description"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # NxTimelines::landing(item)
    def self.landing(item)
        loop {
            return if item.nil?

            system("clear")

            if $NavigationSandboxState then
                puts "!! Selection sandbox, type `found` when found, or exit".green
            end

            uuid = item["uuid"]

            store = ItemStore.new()

            stack = TheNetworkStack::getStack()
            stack.each{|i| puts "(stack) #{LxFunction::function("toString", i)}" }
            if stack.size > 0 then
                puts ""
            end

            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow

            notes = Ax1Text::itemsForOwner(uuid)
            if notes.size > 0 then
                puts "notes:"
                notes.each{|note|
                    indx = store.register(note, false)
                    puts "    [#{indx.to_s.ljust(3)}] #{Ax1Text::toString(note)}" 
                }
            end

            linked = Links::linked(item["uuid"])
            if linked.size > 0 then
                puts "linked:"
                linked
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity| 
                        indx = store.register(entity, false)
                        linkType = Links::linkTypeOrNull(item["uuid"], entity["uuid"])
                        puts "    [#{indx.to_s.ljust(3)}] [#{linkType.ljust(7)}] #{LxFunction::function("toString", entity)}"
                    }
            end

            commands = []
            commands << "access"
            commands << "description"
            commands << "datetime"
            commands << "note"
            commands << "link"
            commands << "relink"
            commands << "unlink"
            commands << "json"
            commands << "destroy"

            puts commands.join(" | ").yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if $NavigationSandboxState and command == "found" then
                $NavigationSandboxState = ["found", item.clone]
                return
            end

            if $NavigationSandboxState and command == "exit" then
                $NavigationSandboxState = ["exit"]
                return
            end

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if Interpreting::match("access", command) then
                EditionDesk::accessItemWithI1asAttribute(item)
                next
            end

            if Interpreting::match("description", command) then
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian::commit(item)
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = CommonUtils::editTextSynchronously(item["datetime"]).strip
                next if !CommonUtils::isDateTime_UTC_ISO8601(datetime)
                item["datetime"] = datetime
                Librarian::commit(item)
            end

            if Interpreting::match("iam", command) then
                item = I1as::manageI1as(item, item["i1as"])
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("link", command) then
                NyxNetwork::connectToOneOrMoreOthersArchitectured(item)
            end

            if Interpreting::match("relink", command) then
                NyxNetwork::relinkToOneOrMoreLinked(item)
            end

            if Interpreting::match("unlink", command) then
                NyxNetwork::disconnectFromLinkedInteractively(item)
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    NxTimelines::destroy(item["uuid"])
                    break
                end
            end
        }
    end

    # ------------------------------------------------
    # Nx20s

    # NxTimelines::nx20s()
    def self.nx20s()
        NxTimelines::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{NxTimelines::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
