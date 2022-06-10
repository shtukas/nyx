# encoding: UTF-8

class TxTodos

    # TxTodos::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxTodo")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
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

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypes(), uuid)

        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
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

    # TxTodos::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        "(todo) #{item["description"]}#{nx111String} (rt: #{BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]).round(2)})"
    end

    # TxTodos::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(todo) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxTodos::doubleDots(item)
    def self.doubleDots(item)

        if !NxBallsService::isRunning(item["uuid"]) then
            NxBallsService::issue(item["uuid"], item["announce"] ? item["announce"] : "(item: #{item["uuid"]})" , [item["uuid"]])
        end

        LxAction::action("access", item)

        if LucilleCore::askQuestionAnswerAsBoolean("'#{item["description"].green}'. Destroy ? ") then
            NxBallsService::close(item["uuid"], true)
            TxTodos::destroy(item["uuid"], true)
            return
        end

        if NxBallsService::isRunning(item["uuid"]) then
            if LucilleCore::askQuestionAnswerAsBoolean("'#{item["description"].green}'. Stop ? ") then
                NxBallsService::close(item["uuid"], true)
                if LucilleCore::askQuestionAnswerAsBoolean("'#{item["description"].green}'. Done for today ? ") then
                    NxBallsService::close(item["uuid"], true)
                    XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
                end
            end
        end
    end

    # TxTodos::done(item)
    def self.done(item)
        puts item["description"].green
        answer = LucilleCore::askQuestionAnswerAsString("Do you want to: `done for the day`, `destroy` or nothing ? ")
        if answer == "done for the day" then
            XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
        end
        if answer == "destroy" then
            TxTodos::destroy(item["uuid"], true)
        end
    end

    # TxTodos::destroy(uuid, shouldForce)
    def self.destroy(uuid, shouldForce)
        if NxBallsService::isRunning(uuid) then
             NxBallsService::close(uuid, true)
        end
        XCacheSets::destroy(TxTodos::cacheLocation(), uuid)
        item = Librarian::getObjectByUUIDOrNull(uuid)
        return if item.nil?
        if shouldForce then
            Librarian::destroy(uuid)
        else
            if LucilleCore::askQuestionAnswerAsBoolean("Delete '#{item["description"].green}' ? ") then
                Librarian::destroy(uuid)
            end
        end
        Bank::put("todo-done-count-afb1-11ac2d97a0a8", 1)
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
                nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypes(), item["uuid"])
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
                    TxTodos::destroy(item["uuid"])
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

    # TxTodos::cacheLocation()
    def self.cacheLocation()
        "DC68E964-0012-4CAB-AC9F-563BA7180808:#{CommonUtils::today()}"
    end

    # TxTodos::updateCache()
    def self.updateCache()

        # We add as many items to require in total at most 12 hours of focus a day (between TxPlus and TxTodo)

        idealCount    = [12 - TxPlus::totalTimeCommitment(), 0].max
        existingCount = XCacheSets::values(TxTodos::cacheLocation()).count
        missingCount  = [idealCount - existingCount, 0].max

        puts "idealCount    = #{idealCount}"
        puts "existingCount = #{existingCount}"
        puts "missingCount  = #{missingCount}"

        return if missingCount == 0

        items1 = TxTodos::items().reduce([]){|selection, item|
            if selection.select{|item| DoNotShowUntil::isVisible(item["uuid"]) }.size >= (missingCount/3)+1 then
                selection
            else
                selection + [item]
            end
        }

        items2 = TxTodos::items().reverse.reduce([]){|selection, item|
            if selection.select{|item| DoNotShowUntil::isVisible(item["uuid"]) }.size >= (missingCount/3)+1 then
                selection
            else
                selection + [item]
            end
        }

        items3 = TxTodos::items().shuffle.reduce([]){|selection, item|
            if selection.select{|item| DoNotShowUntil::isVisible(item["uuid"]) }.size >= (missingCount/3)+1 then
                selection
            else
                selection + [item]
            end
        }

        (items1+items2+items3).each{|item|
            XCacheSets::set(TxTodos::cacheLocation(), item["uuid"], item)
        }
    end

    # TxTodos::itemsForListing()
    def self.itemsForListing()
        if !XCache::getFlag("6ab5d7c1-c9ed-4fa9-8fd4-7e31594834610:#{CommonUtils::today()}") then
            puts "TxTodos::updateCache()".green
            TxTodos::updateCache()
            XCache::setFlag("6ab5d7c1-c9ed-4fa9-8fd4-7e31594834610:#{CommonUtils::today()}", true)
        end

        XCacheSets::values(TxTodos::cacheLocation())
    end

    # --------------------------------------------------

    # TxTodos::nx20s()
    def self.nx20s()
        Librarian::getObjectsByMikuType("TxTodo")
            .map{|item|
                {
                    "announce" => TxTodos::toStringForSearch(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end
