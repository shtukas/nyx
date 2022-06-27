# encoding: UTF-8

class NxShip

    # NxShip::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxShip")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # NxShip::destroy(uuid)
    def self.destroy(uuid)
        Bank::put("todo-done-count-afb1-11ac2d97a0a8", 1)
        Librarian::destroyClique(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxShip::interactivelyIssueNewOrNull(description = nil)
    def self.interactivelyIssueNewOrNull(description = nil)
        if description.nil? or description == "" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
        else
            puts "description: #{description}"
        end

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewNx111OrNull()

        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        ax38 = Ax38::interactivelyCreateNewAxOrNull()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "NxShip",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "ax38"        => ax38
        }
        Librarian::commit(item)
        item
    end

    # NxShip::issueFromLocation(location)
    def self.issueFromLocation(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx111 = Nx111::locationToAionPointNx111OrNull(location)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        item = {
          "uuid"         => uuid,
          "mikuType"     => "NxShip",
          "description"  => description,
          "unixtime"     => unixtime,
          "datetime"     => datetime,
          "nx111"        => nx111,
          "ax38"         => nil
        }
        Librarian::commit(item)
        item
    end

    # NxShip::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid        = SecureRandom.uuid
        description = "(vienna) #{url}"
        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        nx111 = {
            "uuid" => SecureRandom.uuid,
            "type" => "url",
            "url"  => url
        }

        item = {
          "uuid"        => uuid,
          "mikuType"    => "NxShip",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "nx111"       => nx111,
          "ax38"        => nil
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxShip::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        "(ship) #{item["description"]}#{nx111String} (#{Ax38::toString(item["ax38"])}) (rt: #{TxNumbersAcceleration::rt(item).round(2)})"
    end

    # NxShip::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(ship) #{item["description"]}"
    end

    # NxShip::itemShouldShow(item)
    def self.itemShouldShow(item)
        return false if XCache::getFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}")

        if item["ax38"] and item["ax38"]["type"] == "daily-time-commitment" then
            return TxNumbersAcceleration::rt(item) < item["ax38"]["hours"]
        end

        if item["ax38"] and item["ax38"]["type"] == "weekly-time-commitment" then
            return false if Time.new.wday == 5 # We don't show those on Fridays
            return TxNumbersAcceleration::combined_value(item) < item["ax38"]["hours"]
        end

        true
    end

    # NxShip::itemsForListingHighPriority()
    def self.itemsForListingHighPriority()
        items = NxShip::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .select{|item| NxShip::itemShouldShow(item) }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }

        i0s, items = items.partition{|item| item["ax38"].nil? }
        i1s, items = items.partition{|item| item["ax38"]["type"] == "today/asap" }
        i2s, items = items.partition{|item| item["ax38"]["type"] == "daily-fire-and-forget" }
        i3s, items = items.partition{|item| item["ax38"]["type"] == "daily-time-commitment" }
        i4s, items = items.partition{|item| item["ax38"]["type"] == "weekly-time-commitment" }

        i0s + i1s
    end


    # NxShip::itemsForListingLowPriority()
    def self.itemsForListingLowPriority()
        items = NxShip::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .select{|item| NxShip::itemShouldShow(item) }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }

        i0s, items = items.partition{|item| item["ax38"].nil? }
        i1s, items = items.partition{|item| item["ax38"]["type"] == "today/asap" }
        i2s, items = items.partition{|item| item["ax38"]["type"] == "daily-fire-and-forget" }
        i3s, items = items.partition{|item| item["ax38"]["type"] == "daily-time-commitment" }
        i4s, items = items.partition{|item| item["ax38"]["type"] == "weekly-time-commitment" }

        i2s + i3s + i4s + items
    end

    # NxShip::nx20s()
    def self.nx20s()
        NxShip::items()
            .map{|item|
                {
                    "announce" => NxShip::toStringForSearch(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end

    # --------------------------------------------------
    # Operations

    # NxShip::setAx38(item)
    def self.setAx38(item)
        ax38 = Ax38::interactivelyCreateNewAxOrNull()
        if ax38 then
            item["ax38"] = ax38
            Librarian::commit(item)
        end
    end

    # NxShip::doubleDotMissingAx38(item)
    def self.doubleDotMissingAx38(item)
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["access and decide", "set Ax38"])
        return if action.nil?
        if action == "access and decide" then
            LxAction::action("access", item)
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["destroy", "set Ax38"])
            return if action.nil?
            if action == "destroy" then
                NxShip::destroy(item["uuid"])
            end
            if action == "set Ax38" then
                NxShip::setAx38(item)
            end
            return
        end
        if action == "set Ax38" then
            NxShip::setAx38(item)
            return
        end
    end

    # NxShip::doubleDot(item)
    def self.doubleDot(item)
        if item["ax38"].nil? then
            NxShip::doubleDotMissingAx38(item)
            return
        end

        if NxBallsService::isRunning(item["uuid"]) then
            NxBallsService::close(item["uuid"], true)
            if item["ax38"]["type"] == "daily-fire-and-forget" then
                XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
            end
            if item["ax38"]["type"] == "today/asap" or item["ax38"]["type"] == "standard" then
                if LucilleCore::askQuestionAnswerAsBoolean("'#{item["description"].green}' destroy ? ", true) then
                    NxShip::destroy(item["uuid"])
                end
            end
        else
            NxBallsService::issue(item["uuid"], item["announce"] ? item["announce"] : "(item: #{item["uuid"]})" , [item["uuid"]])
            LxAction::action("access", item)
        end
    end

    # NxShip::done(item)
    def self.done(item)

        puts NxShip::toString(item).green
        NxBallsService::close(item["uuid"], true)

        twoChoices = lambda{|item|
            answer = LucilleCore::askQuestionAnswerAsString("This is a NxShip. Do you want to: `done for the day`, `destroy` or nothing ? ")
            if answer == "done for the day" then
                XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
                if item["ax38"].nil? then
                    ax38 = Ax38::interactivelyCreateNewAxOrNull()
                    if ax38 then
                        item["ax38"] = ax38
                        Librarian::commit(item)
                    end
                end
            end
            if answer == "destroy" then
                NxShip::destroy(item["uuid"])
            end
        }

        if item["ax38"].nil? then
            twoChoices.call(item)
            return
        end

        if item["ax38"]["type"] == "standard" then
            twoChoices.call(item)
            return
        end

        if item["ax38"]["type"] == "today/asap" then
            twoChoices.call(item)
            return
        end

        if item["ax38"]["type"] == "daily-fire-and-forget" then
            XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
            return
        end

        if item["ax38"]["type"] == "daily-time-commitment" then
            if BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]) < item["ax38"]["hours"] then
                if LucilleCore::askQuestionAnswerAsBoolean("You are below daily target, do you want to close for the day anyway ? ") then
                    XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
                end
            else
                XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
            end
            return
        end
        if item["ax38"]["type"] == "daily-time-commitment" then
            if Bank::combinedValueOnThoseDays(item["uuid"], CommonUtils::dateSinceLastSaturday()) < item["ax38"]["hours"] then
                if LucilleCore::askQuestionAnswerAsBoolean("You are below weekly target, do you want to close for the day anyway ? ") then
                    XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
                end
            else
                XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
            end
            return
        end
    end

    # NxShip::dive()
    def self.dive()
        loop {
            system("clear")
            items = NxShip::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("ship", items, lambda{|item| NxShip::toString(item) })
            break if item.nil?
            Landing::implementsNx111Landing(item)
        }
    end
end
