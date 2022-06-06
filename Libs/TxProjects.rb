j# encoding: UTF-8

class TxProjects

    # TxProjects::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxProject")
    end

    # TxProjects::itemsForUniverse(universe)
    def self.itemsForUniverse(universe)
        Librarian::getObjectsByMikuTypeAndUniverse("TxProject", universe)
    end

    # TxProjects::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxProjects::interactivelyCreateNewOrNull(description = nil)
    def self.interactivelyCreateNewOrNull(description = nil)
        if description.nil? then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
        end

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), uuid)
        return nil if nx111.nil?

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        universe   = Multiverse::interactivelySelectUniverse()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxProject",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "i1as"        => [nx111],
          "universe"    => universe
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # TxProjects::toString(item)
    def self.toString(item)
        "(project) #{item["description"]} (#{I1as::toStringShort(item["i1as"])})"
    end

    # TxProjects::toStringForNS16(item, rt)
    def self.toStringForNS16(item, rt)
        "(project) #{item["description"]} (#{I1as::toStringShort(item["i1as"])})"
    end

    # TxProjects::toStringForNS19(item)
    def self.toStringForNS19(item)
        "(project) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxProjects::complete(item)
    def self.complete(item)
        TxProjects::destroy(item["uuid"])
    end

    # TxProjects::landing(item)
    def self.landing(item)

        loop {

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts TxProjects::toString(item).green
            puts "uuid: #{uuid}".yellow

            puts "i1as:"
            item["i1as"].each{|nx111|
                puts "    #{Nx111::toString(nx111)}"
            } 

            puts "rt: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            notes = Ax1Text::itemsForOwner(uuid)
            if notes.size > 0 then
                puts "notes:"
                notes.each{|note|
                    indx = store.register(note, false)
                    puts "    [#{indx.to_s.ljust(3)}] #{Ax1Text::toString(note)}" 
                }
            end

            puts "access | start | <datecode> | description | iam | note | show json | universe | transmute | >nyx | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if (unixtime = CommonUtils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                EditionDesk::accessItem(item)
                next
            end

            if Interpreting::match("start", command) then
                if !NxBallsService::isRunning(item["uuid"]) then
                    NxBallsService::issue(item["uuid"], item["description"], [item["uuid"]])
                end
                next
            end

            if Interpreting::match("description", command) then
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian::commit(item)
                next
            end

            if Interpreting::match("iam", command) then
                item = I1as::manageI1as(item, item["i1as"])
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("transmute", command) then
                Transmutation::transmutation2(item, "TxProject")
                break
            end

            if Interpreting::match("universe", command) then
                item["universe"] = Multiverse::interactivelySelectUniverse()
                Librarian::commit(item)
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match(">nyx", command) then
                ix = {
                    "uuid"        => SecureRandom.uuid,
                    "mikuType"    => "Nx100",
                    "unixtime"    => item["unixtime"],
                    "datetime"    => item["datetime"],
                    "description" => item["description"],
                    "i1as"        => item["i1as"],
                    "flavour"     => Nx102Flavor::interactivelyCreateNewFlavour()
                }
                Librarian::commit(ix)
                LxAction::action("landing", ix)
                TxProjects::complete(item)
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxProjects::toString(item)}' ? ", true) then
                    TxProjects::complete(item)
                    break
                end
                next
            end
        }
    end

    # TxProjects::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxProjects::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("project", items, lambda{|item| TxProjects::toString(item) })
            break if item.nil?
            TxProjects::landing(item)
        }
    end

    # --------------------------------------------------
    # nx16s

    # TxProjects::ns16s(universe)
    def self.ns16s(universe)
        TxProjects::itemsForUniverse(universe)
            .map{|item| 
                uuid = item["uuid"]
                rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
                announce = TxProjects::toStringForNS16(item, rt)
                {
                    "uuid"      => uuid,
                    "mikuType"  => "NS16:TxProject",
                    "announce"  => announce,
                    "TxProject" => item,
                    "rt"        => rt,
                    "universe"  => item["universe"]
                }
            }
            .sort{|i1, i2| i1["rt"] <=> i2["rt"] }
    end

    # --------------------------------------------------

    # TxProjects::nx20s()
    def self.nx20s()
        TxProjects::items().map{|item|
            {
                "announce" => TxProjects::toStringForNS19(item),
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
