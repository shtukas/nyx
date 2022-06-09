# encoding: UTF-8

class TxProjects

    # TxProjects::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxProject")
    end

    # --------------------------------------------------
    # Makers

    # TxProjects::interactivelyCreateNewOrNull(description = nil)
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
        nx54 = Nx54::makeNew()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxProject",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "nx111"       => nx111,
          "nx54" => nx54
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # TxProjects::toString(item)
    def self.toString(item)
        "(project) #{item["description"]} (#{Nx111::toStringShort(item["nx111"])}) (#{Nx54::toString(item["nx54"])})"
    end

    # TxProjects::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(project) #{item["description"]}"
    end

    # TxProjects::availableForSection2(item)
    def self.availableForSection2(item)
        if item["nx54"]["type"] == "required-hours-days" then
            return Bank::valueAtDate(item["uuid"], CommonUtils::today()) < item["nx54"]["value"]
        end

        if item["nx54"]["type"] == "required-hours-week-saturday-start" then
            return BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]) < 0.5 # TODO: to correct (dbae7ba5-6157-4022-af27-8f030952d02d)
        end

        if item["nx54"]["type"] == "target-recovery-time" then
            return BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]) < item["nx54"]["value"]
        end

        if item["nx54"]["type"] == "fire-and-forget-daily" then
            return !XCache::setFlag("8744d935-c347-44fe-b648-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
        end

        raise "(error: dcf30e93-9a64-42e0-9370-d1009d946c1e) #{item}"
    end

    # --------------------------------------------------
    # Operations

    # TxProjects::doubleDots(item)
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

    # TxProjects::done(item)
    def self.done(item)
        if item["nx54"]["type"] == "fire-and-forget-daily" then
            puts "Completed for today: '#{item["description"].green}'"
            XCache::setFlag("8744d935-c347-44fe-b648-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}")
        end
        if NxBallsService::isRunning(item["uuid"]) then
             NxBallsService::close(item["uuid"], true)
        end
    end

    # TxProjects::destroy(item)
    def self.destroy(item)
        Bank::put("todo-done-count-afb1-11ac2d97a0a8", 1)
        Librarian::destroy(item["item"])
    end

    # TxProjects::landing(item)
    def self.landing(item)

        loop {

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts "#{TxProjects::toString(item)}#{NxBallsService::activityStringOrEmptyString(" (", uuid, ")")}".green
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
                EditionDesk::accessItemWithI1asAttribute(item)
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
                Transmutation::transmutation2(item, "TxProject")
                break
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxProjects::toString(item)}' ? ", true) then
                    NxBallsService::close(item["uuid"], true)
                    TxProjects::destroy(item["uuid"])
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

    # --------------------------------------------------

    # TxProjects::itemsForListing()
    def self.itemsForListing()
        TxProjects::items()
            .select{|item| TxProjects::availableForSection2(item) }
    end

    # --------------------------------------------------

    # TxProjects::nx20s()
    def self.nx20s()
        Librarian::getObjectsByMikuType("TxProject")
            .map{|item|
                {
                    "announce" => TxProjects::toStringForSearch(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end
