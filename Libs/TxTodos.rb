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

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), uuid)
        return nil if nx111.nil?

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
        "(todo) #{item["description"]} (#{Nx111::toStringShort(item["nx111"])})"
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

        if LucilleCore::askQuestionAnswerAsBoolean("Delete '#{item["description"].green}' ? ") then
            NxBallsService::close(item["uuid"], true)
            TxTodos::destroy(item["uuid"])
        end
    end

    # TxTodos::done(item, shouldForce = false)
    def self.done(item, shouldForce = false)
        if shouldForce then
            TxTodos::destroy(item["uuid"])
        else
            if LucilleCore::askQuestionAnswerAsBoolean("Delete '#{item["description"].green}' ? ") then
                TxTodos::destroy(item["uui"])
            end
        end
        if NxBallsService::isRunning(item["uuid"]) then
             NxBallsService::close(item["uuid"], true)
        end
    end

    # TxTodos::destroy(uuid)
    def self.destroy(uuid)
        Bank::put("todo-done-count-afb1-11ac2d97a0a8", 1)
        Librarian::destroy(item["uuid"])
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
        "DC68E964-0012-4CAB-AC9F-563BA7180808"
    end

    # TxTodos::resetCache()
    def self.resetCache()

        XCacheSets::values(TxTodos::cacheLocation()).each{|item|
            XCacheSets::destroy(TxTodos::cacheLocation(), item["uuid"])
        }

        items1 = TxTodos::items().reduce([]){|selection, item|
            if selection.select{|item| DoNotShowUntil::isVisible(item["uuid"]) }.size >= 10 then
                selection
            else
                selection + [item]
            end
        }

        items2 = TxTodos::items().reverse.reduce([]){|selection, item|
            if selection.select{|item| DoNotShowUntil::isVisible(item["uuid"]) }.size >= 10 then
                selection
            else
                selection + [item]
            end
        }

        items3 = TxTodos::items().shuffle.reduce([]){|selection, item|
            if selection.select{|item| DoNotShowUntil::isVisible(item["uuid"]) }.size >= 10 then
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
        items = XCacheSets::values(TxTodos::cacheLocation())
        if items.size < 10 then
            puts "TxTodos::resetCache()".green
            TxTodos::resetCache()
            items = XCacheSets::values(TxTodos::cacheLocation())
        end
        items
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
