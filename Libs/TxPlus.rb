# encoding: UTF-8

class TxPlus

    # TxPlus::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxPlus")
    end

    # TxPlus::destroy(uuid)
    def self.destroy(uuid)
        Bank::put("todo-done-count-afb1-11ac2d97a0a8", 1)
        Librarian::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxPlus::interactivelyCreateNewOrNull(description = nil)
    def self.interactivelyCreateNewOrNull(description = nil)
        if description.nil? or description == "" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
        else
            puts "description: #{description}"
        end

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), uuid)
        return nil if nx111.nil?

        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxPlus",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "nx111"       => nx111
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # TxPlus::toString(item)
    def self.toString(item)
        "(plus) #{item["description"]} (#{Nx111::toStringShort(item["nx111"])})"
    end

    # TxPlus::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(plus) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxPlus::doubleDots(item)
    def self.doubleDots(item)

        if !NxBallsService::isRunning(item["uuid"]) then
            NxBallsService::issue(item["uuid"], item["announce"] ? item["announce"] : "(item: #{item["uuid"]})" , [item["uuid"]])
        end

        LxAction::action("access", item)

        if item["nx54"]["type"] == "required-hours-days" then
            return
        end

        if item["nx54"]["type"] == "required-hours-week-saturday-start" then
            return
        end

        if item["nx54"]["type"] == "target-recovery-time" then
            return
        end

        if item["nx54"]["type"] == "fire-and-forget-daily" then
            if LucilleCore::askQuestionAnswerAsBoolean("Completed for today: '#{item["description"].green}' ? ") then
                NxBallsService::close(item["uuid"], true)
                XCache::setFlag("8744d935-c347-44fe-b648-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}")
            end
            return
        end

        raise "(error: ac55d44c-60b1-4fee-8a79-27cb3265c373)"
    end

    # TxPlus::done(item)
    def self.done(item)
        if item["nx54"]["type"] == "fire-and-forget-daily" then
            puts "Completed for today: '#{item["description"].green}'"
            XCache::setFlag("8744d935-c347-44fe-b648-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}")
        end
        if NxBallsService::isRunning(item["uuid"]) then
             NxBallsService::close(item["uuid"], true)
        end
    end

    # TxPlus::landing(item)
    def self.landing(item)

        loop {

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts "#{TxPlus::toString(item)}#{NxBallsService::activityStringOrEmptyString(" (", uuid, ")")}".green
            puts "uuid: #{uuid}".yellow
            puts "nx111: #{item["nx111"]}"
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow
            puts "rt: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            notes = Ax1Text::itemsForOwner(uuid)
            if notes.size > 0 then
                puts "notes:"
                notes.each{|note|
                    indx = store.register(note, false)
                    puts "    [#{indx.to_s.ljust(3)}] #{Ax1Text::toString(note)}" 
                }
            end

            puts "access | start | <datecode> | description | iam | transmute | note | json | >nyx | destroy".yellow

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
                EditionDesk::accessItemNx111Pair(item, item["nx111"])
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
                nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), item["uuid"])
                next if nx111.nil?
                item["nx111"] = nx111
                Librarian::commit(item)
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("transmute", command) then
                Transmutation::transmutation2(item, "TxPlus")
                break
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxPlus::toString(item)}' ? ", true) then
                    NxBallsService::close(item["uuid"], true)
                    TxPlus::destroy(item["uuid"])
                    break
                end
                next
            end

            if command == ">nyx" then
                i2 = Transmutation::interactivelyNx50ToNyx(item)
                LxAction::action("landing", i2)
                break
            end
        }
    end

    # TxPlus::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxPlus::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("plus", items, lambda{|item| TxPlus::toString(item) })
            break if item.nil?
            TxPlus::landing(item)
        }
    end

    # --------------------------------------------------

    # TxPlus::itemsForListing()
    def self.itemsForListing()
        TxPlus::items()
    end

    # --------------------------------------------------

    # TxPlus::nx20s()
    def self.nx20s()
        Librarian::getObjectsByMikuType("TxPlus")
            .map{|item|
                {
                    "announce" => TxPlus::toStringForSearch(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end
