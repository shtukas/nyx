# encoding: UTF-8

class Ax38

    # Ax38::type()
    def self.types()
        ["standard (stack until done with hourly overflow)", "today/asap" , "daily-fire-and-forget", "daily-time-commitment", "weekly-time-commitment"]
    end

    # Ax38::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", Ax38::types())
    end

    # Ax38::interactivelyCreateNewAxOrNull()
    def self.interactivelyCreateNewAxOrNull()
        type = Ax38::interactivelySelectTypeOrNull()
        return nil if type.nil?
        if type == "standard (stack until done with hourly overflow)" then
            return {
                "type" => "standard"
            }
        end
        if type == "today/asap" then
            return {
                "type" => "today/asap"
            }
        end
        if type == "daily-fire-and-forget" then
            return {
                "type" => "daily-fire-and-forget"
            }
        end
        if type == "daily-time-commitment" then
            hours = LucilleCore::askQuestionAnswerAsString("daily hours : ")
            return nil if hours == ""
            return {
                "type"  => "daily-time-commitment",
                "hours" => hours.to_f
            }
        end
        if type == "weekly-time-commitment" then
            hours = LucilleCore::askQuestionAnswerAsString("weekly hours : ")
            return nil if hours == ""
            return {
                "type"  => "weekly-time-commitment",
                "hours" => hours.to_f
            }
        end
    end

    # Ax38::toString(ax38)
    def self.toString(ax38)
        if ax38.nil? then
            return "📥"
        end

        if ax38["type"] == "standard" then
            return "⛵️"
        end

        if ax38["type"] == "today/asap" then
            return "today/asap"
        end

        if ax38["type"] == "daily-fire-and-forget" then
            return "daily once 🪄"
        end

        if ax38["type"] == "daily-time-commitment" then
            return "today: #{ax38["hours"]} hours"
        end

        if ax38["type"] == "weekly-time-commitment" then
            return "weekly: #{ax38["hours"]} hours"
        end
    end
end

class TxZNumbersAcceleration

    # TxZNumbersAcceleration::rt(item)
    def self.rt(item)
        XCache::getOrDefaultValue("zero-rt-6e6e6fbebbc5:#{item["uuid"]}", "0").to_f
    end

    # TxZNumbersAcceleration::combined_value(item)
    def self.combined_value(item)
        XCache::getOrDefaultValue("combined-value-53a4f8ab8a64:#{item["uuid"]}", "0").to_f
    end
end

Thread.new {
    loop {
        sleep 32
        TxZero::items().each{|item|
            rt = BankExtended::stdRecoveredDailyTimeInHours(item["uuid"])
            XCache::set("zero-rt-6e6e6fbebbc5:#{item["uuid"]}", rt)
            cvalue = Bank::combinedValueOnThoseDays(item["uuid"], CommonUtils::dateSinceLastSaturday())
            XCache::set("combined-value-53a4f8ab8a64:#{item["uuid"]}", rt)
        }
        
    }
}

class TxZero

    # TxZero::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxZero")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # TxZero::destroy(uuid)
    def self.destroy(uuid)
        Bank::put("todo-done-count-afb1-11ac2d97a0a8", 1)
        Librarian::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxZero::interactivelyIssueNewOrNull(description = nil)
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
          "mikuType"    => "TxZero",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "ax38"        => ax38
        }
        Librarian::commit(item)
        item
    end

    # TxZero::locationToZero(location)
    def self.locationToZero(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx111 = Nx111::locationToAionPointNx111OrNull(location)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        item = {
          "uuid"         => uuid,
          "mikuType"     => "TxZero",
          "description"  => description,
          "unixtime"     => unixtime,
          "datetime"     => datetime,
          "nx111"        => nx111,
          "ax38"         => nil
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # TxZero::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        "(zero) #{item["description"]}#{nx111String} (#{Ax38::toString(item["ax38"])}) (rt: #{TxZNumbersAcceleration::rt(item).round(2)})"
    end

    # TxZero::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(zero) #{item["description"]}"
    end

    # TxZero::itemShouldShow(item)
    def self.itemShouldShow(item)
        return false if XCache::getFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}")

        if item["ax38"] and item["ax38"]["type"] == "daily-time-commitment" then
            return TxZNumbersAcceleration::rt(item) < item["ax38"]["hours"]
        end

        if item["ax38"] and item["ax38"]["type"] == "weekly-time-commitment" then
            return false if Time.new.wday == 5 # We don't show those on Fridays
            return TxZNumbersAcceleration::combined_value(item) < item["ax38"]["hours"]
        end

        true
    end

    # --------------------------------------------------
    # Operations

    # TxZero::setAx38(item)
    def self.setAx38(item)
        ax38 = Ax38::interactivelyCreateNewAxOrNull()
        if ax38 then
            item["ax38"] = ax38
            Librarian::commit(item)
        end
    end

    # TxZero::doubleDotMissingAx38(item)
    def self.doubleDotMissingAx38(item)
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["access and decide", "set Ax38"])
        return if action.nil?
        if action == "access and decide" then
            LxAction::action("access", item)
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["destroy", "set Ax38"])
            return if action.nil?
            if action == "destroy" then
                TxZero::destroy(item["uuid"])
            end
            if action == "set Ax38" then
                TxZero::setAx38(item)
            end
            return
        end
        if action == "set Ax38" then
            TxZero::setAx38(item)
            return
        end
    end

    # TxZero::doubleDot(item)
    def self.doubleDot(item)
        if item["ax38"].nil? then
            TxZero::doubleDotMissingAx38(item)
            return
        end

        if NxBallsService::isRunning(item["uuid"]) then
            NxBallsService::close(item["uuid"], true)
            if item["ax38"]["type"] == "daily-fire-and-forget" then
                XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
            end
            if item["ax38"]["type"] == "today/asap" or item["ax38"]["type"] == "standard" then
                if LucilleCore::askQuestionAnswerAsBoolean("'#{item["description"].green}' destroy ? ", true) then
                    TxZero::destroy(item["uuid"])
                end
            end
        else
            NxBallsService::issue(item["uuid"], item["announce"] ? item["announce"] : "(item: #{item["uuid"]})" , [item["uuid"]])
            LxAction::action("access", item)
        end
    end

    # TxZero::done(item)
    def self.done(item)

        puts TxZero::toString(item).green
        NxBallsService::close(item["uuid"], true)

        twoChoices = lambda{|item|
            answer = LucilleCore::askQuestionAnswerAsString("This is a TxZero. Do you want to: `done for the day`, `destroy` or nothing ? ")
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
                TxZero::destroy(item["uuid"])
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

    # TxZero::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxZero::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("zero", items, lambda{|item| TxZero::toString(item) })
            break if item.nil?
            Landing::implementsNx111Landing(item)
        }
    end

    # --------------------------------------------------

    # TxZero::itemsForListing()
    def self.itemsForListing()
        items = TxZero::items()
                    .select{|item| TxZero::itemShouldShow(item) }
                    .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                    .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }

        i1s, items = items.partition{|item| item["ax38"].nil? }
        i2s, items = items.partition{|item| item["ax38"]["type"] == "today/asap" }
        i3s, items = items.partition{|item| item["ax38"]["type"] == "daily-fire-and-forget" }
        i4s, items = items.partition{|item| item["ax38"]["type"] == "daily-time-commitment" }
        i5s, items = items.partition{|item| item["ax38"]["type"] == "weekly-time-commitment" }

        i1s + i2s + i3s + i4s + i5s + items
    end

    # TxZero::nx20s()
    def self.nx20s()
        Librarian::getObjectsByMikuType("TxZero")
            .map{|item|
                {
                    "announce" => TxZero::toStringForSearch(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end
