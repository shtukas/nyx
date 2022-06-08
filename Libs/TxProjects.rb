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

    # TxProjects::interactivelyMakeTxProjExpectationOrNull()
    def self.interactivelyMakeTxProjExpectationOrNull()
        types = ["required-hours-days", "required-hours-week-saturday-start", "target-recovery-time", "fire-and-forget-daily"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type: ", types)
        return nil if type.nil?
        if type == "required-hours-days" then
            hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
            return {
                "type"  => "required-hours-days",
                "value" => hours
            }
        end
        if type == "required-hours-week-saturday-start" then
            hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
            return {
                "type"  => "required-hours-week-saturday-start",
                "value" => hours
            }
        end
        if type == "target-recovery-time" then
            hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
            return {
                "type"  => "target-recovery-time",
                "value" => hours
            }
        end
        if type == "fire-and-forget-daily" then
            return {
                "type"  => "fire-and-forget-daily"
            }
        end
    end

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

        universe    = Multiverse::interactivelySelectUniverse()
        expectation = TxProjects::interactivelyMakeTxProjExpectationOrNull()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxProject",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "i1as"        => [nx111],
          "universe"    => universe,
          "expectation" => expectation
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # TxProjects::toString(item)
    def self.toString(item)
        "(project) #{item["description"]} (#{I1as::toStringShort(item["i1as"])}) (#{item["universe"]})"
    end


    # TxProjects::toStringForNS19(item)
    def self.toStringForNS19(item)
        "(project) #{item["description"]}"
    end

    # TxProjects::shouldBeInSection2(item)
    def self.shouldBeInSection2(item)
        return false if XCache::getFlag("915b-09a30622d2b9:FyreIsDoneForToday:#{CommonUtils::today()}:#{item["uuid"]}")

        expectation = item["expectation"]

        if expectation["type"] == "required-hours-days" then
            return Bank::valueAtDate(item["uuid"], CommonUtils::today()) < expectation["value"]*3600
        end

        if expectation["type"] == "required-hours-week-saturday-start" then
            return true # TODO: implement correctly (d43d3026-91ff-4202-9555-297063f6aa60)
        end

        if expectation["type"] == "target-recovery-time" then
            return BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]) < expectation["value"]
        end

        if expectation["type"] == "fire-and-forget-daily" then
            return true # controlled by XCache::getFlag("915b-09a30622d2b9:FyreIsDoneForToday:#{CommonUtils::today()}:#{item["uuid"]}")
        end

        raise "(error: 14712886-8e8f-415c-88e8-3ac3087bc906) : #{expectation}"
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

            puts "access | start | <datecode> | description | iam | note | json | universe | transmute | >nyx | destroy".yellow

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
                EditionDesk::accessItemWithI1asAttribute(item)
                next
            end

            if Interpreting::match("start", command) then
                if !NxBallsService::isRunning(item["uuid"]) then
                    NxBallsService::issue(item["uuid"], item["description"], [item["uuid"], item["universe"]])
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

            if Interpreting::match("json", command) then
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

    # TxProjects::itemsForListing(universe)
    def self.itemsForListing(universe)
        Librarian::getObjectsByMikuTypeAndPossiblyNullUniverse("TxProject", universe)
    end

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
