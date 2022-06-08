# encoding: UTF-8

class RStreamProgressMonitor
    def initialize()
        @data = JSON.parse(XCache::getOrDefaultValue("18705e17-41a7-4c7b-986b-a6a9292e8bb4", "[]"))
    end
    def anotherOne()
        @data << Time.new.to_i
        XCache::set("18705e17-41a7-4c7b-986b-a6a9292e8bb4", JSON.generate(@data))
    end
    def getCount()
        @data.size
    end
end

$RStreamProgressMonitor = RStreamProgressMonitor.new()

class TxTodos

    # TxTodos::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxTodo")
    end

    # --------------------------------------------------
    # Makers

    # TxTodos::interactivelyCreateNewOrNull(description = nil)
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
          "mikuType"    => "TxTodo",
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

    # TxTodos::toString(item)
    def self.toString(item)
        "(todo) #{item["description"]} (#{Nx111::toStringShort(item["nx111"])})"
    end

    # TxTodos::toStringForNS19(item)
    def self.toStringForNS19(item)
        "(todo) #{item["description"]}"
    end

    # TxTodos::shouldShowInListing(item)
    def self.shouldShowInListing(item)
        if item["nx54"]["type"] == "todo" then
            return true
        end

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

    # TxTodos::doubleDots(item)
    def self.doubleDots(item)

        if !NxBallsService::isRunning(item["uuid"]) then
            NxBallsService::issue(item["uuid"], item["announce"] ? item["announce"] : "(item: #{item["uuid"]})" , [item["uuid"]])
        end

        LxAction::action("access", item)

        if item["nx54"]["type"] == "todo" then
            if LucilleCore::askQuestionAnswerAsBoolean("Delete '#{item["description"].green}' ? ") then
                NxBallsService::close(item["uuid"], true)
                TxTodos::immediateDestroy(item)
            end
            return
        end

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

    # TxTodos::done(item)
    def self.done(item)
        if item["nx54"]["type"] == "todo" then
            if LucilleCore::askQuestionAnswerAsBoolean("Delete '#{item["description"].green}' ? ") then
                TxTodos::immediateDestroy(item)
            end
        end
        if item["nx54"]["type"] == "fire-and-forget-daily" then
            puts "Completed for today: '#{item["description"].green}'"
            XCache::setFlag("8744d935-c347-44fe-b648-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}")
        end
        if NxBallsService::isRunning(item["uuid"]) then
             NxBallsService::close(item["uuid"], true)
        end
    end

    # TxTodos::immediateDestroy(item)
    def self.immediateDestroy(item)
        Librarian::destroy(item["item"])
    end

    # TxTodos::landing(item)
    def self.landing(item)

        loop {

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts "#{TxTodos::toString(item)}#{NxBallsService::activityStringOrEmptyString(" (", uuid, ")")}".green
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
                Transmutation::transmutation2(item, "TxTodo")
                break
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxTodos::toString(item)}' ? ", true) then
                    NxBallsService::close(item["uuid"], true)
                    TxTodos::immediateDestroy(item["uuid"])
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

    # TxTodos::itemsForListing()
    def self.itemsForListing()
        TxTodos::items()
            .select{|item| TxTodos::shouldShowInListing(item) }
            .sort{|i1, i2| Nx54::nx54ToPriority(i1["nx54"]) <=> Nx54::nx54ToPriority(i2["nx54"]) }
            .take(20)
    end

    # --------------------------------------------------

    # TxTodos::nx20s()
    def self.nx20s()
        Librarian::getObjectsByMikuType("TxTodo")
            .map{|item|
                {
                    "announce" => TxTodos::toStringForNS19(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end
