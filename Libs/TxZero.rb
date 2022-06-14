# encoding: UTF-8

class Ax38

    # Ax38::type()
    def self.types()
        ["standard (do until done with hourly overflow)", "daily-fire-and-forget", "daily-time-commitment", "weekly-time-commitment"]
    end

    # Ax38::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", Ax38::types())
    end

    # Ax38::interactivelyCreateNewAxOrNull()
    def self.interactivelyCreateNewAxOrNull()
        type = Ax38::interactivelySelectTypeOrNull()
        return nil if type.nil?
        if type == "standard (do until done with hourly overflow)" then
            {
                "type" => "standard"
            }
        end
        if type == "daily-fire-and-forget" then
            {
                "type" => "daily-fire-and-forget"
            }
        end
        if type == "daily-time-commitment" then
            hours = LucilleCore::askQuestionAnswerAsString("daily hours : ")
            return nil if hours == ""
            {
                "type"  => "daily-time-commitment",
                "hours" => hours.to_f
            }
        end
        if type == "weekly-time-commitment" then
            hours = LucilleCore::askQuestionAnswerAsString("weekly hours : ")
            return nil if hours == ""
            {
                "type"  => "weekly-time-commitment",
                "hours" => hours.to_f
            }
        end
    end

    # Ax38::itemShouldShow(item)
    def self.itemShouldShow(item)
        return false if XCache::getFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}")
        true
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
          "ax38"        => ax38,
          "ordinal"     => TxZero::getNewTopOrdinal()
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
          "ax38"         => nil,
          "ordinal"      => TxZero::getNewTopOrdinal()
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # TxZero::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        "(zero) #{item["description"]}#{nx111String} (rt: #{TxZNumbersAcceleration::rt(item).round(2)})"
    end

    # TxZero::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(zero) #{item["description"]}"
    end

    # TxZero::totalTimeCommitment()
    def self.totalTimeCommitment()
        TxZero::items()
            .select{|item| item["nx15"]["type"] == "time-commitment" }
            .map{|item| item["nx15"]["value"] }
            .inject(0, :+)
    end

    # TxZero::getNewTopOrdinal()
    def self.getNewTopOrdinal()
        TxZero::items().map{|item| item["ordinal"] }.max + 1
    end

    # TxZero::getNewBottomOrdinal()
    def self.getNewBottomOrdinal()
        TxZero::items().map{|item| item["ordinal"] }.min - 1
    end

    # TxZero::rotateItem(item)
    def self.rotateItem(item)
        item["ordinal"] = TxZero::getNewBottomOrdinal()
        Librarian::commit(item)
    end

    # --------------------------------------------------
    # Operations

    # TxZero::doubleDots(item)
    def self.doubleDots(item)

        if !NxBallsService::isRunning(item["uuid"]) then
            NxBallsService::issue(item["uuid"], item["announce"] ? item["announce"] : "(item: #{item["uuid"]})" , [item["uuid"]])
        end

        LxAction::action("access", item)

        answer = LucilleCore::askQuestionAnswerAsString("`continue` or `done` ? ")

        if answer == "continue" then
            return
        end

        if answer == "done" then
            TxZero::done(item)
        end
    end

    # TxZero::done(item)
    def self.done(item)
        puts TxZero::toString(item).green
        NxBallsService::close(item["uuid"], true)
 
        if item["ax38"].nil? then
            ax38 = Ax38::interactivelyCreateNewAxOrNull()
            if ax38 then
                item["ax38"] = ax38
                Librarian::commit(item)
            end
        end

        twoChoices = lambda{|item|
            answer = LucilleCore::askQuestionAnswerAsString("This is a TxZero. Do you want to: `done for the day`, `destroy` or nothing ? ")
            if answer == "done for the day" then
                XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
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
        TxZero::items()
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
            .reverse
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
