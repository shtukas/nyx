# encoding: UTF-8

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

        isProject = LucilleCore::askQuestionAnswerAsBoolean("is project ? ")

        item = {
          "uuid"         => uuid,
          "mikuType"     => "TxZero",
          "description"  => description,
          "unixtime"     => unixtime,
          "datetime"     => datetime,
          "nx111"        => nx111,
          "isProject"    => isProject
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
          "nx111"        => nx111
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # TxZero::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        "(zero) #{item["description"]}#{nx111String} (rt: #{TxZero::rt_vX(item).round(2)})"
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

    # TxZero::rt_vX(item)
    def self.rt_vX(item)
        XCache::getOrDefaultValue("zero-rt-6e6e6fbebbc5:#{item["uuid"]}", "0").to_f
    end

    # TxZero::combined_value_vX(item)
    def self.combined_value_vX(item)
        XCache::getOrDefaultValue("combined-value-53a4f8ab8a64:#{item["uuid"]}", "0").to_f
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
        answer = LucilleCore::askQuestionAnswerAsString("This is a TxZero. Do you want to: `done for the day`, `destroy` or nothing ? ")
        if answer == "done for the day" then
            XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
        end
        if answer == "destroy" then
            if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of TxZero '#{item["description"].green}' ? ", true) then
                TxZero::destroy(item["uuid"])
            end
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

    # TxZero::ensureExtraAttributes()
    def self.ensureExtraAttributes()
        TxZero::items().each{|item|
            next if XCache::getOrNull("c5b3502c-6773-4b4d-b830-9b0e76375ac8:#{item["uuid"]}")
            puts item["description"].green
            flag = LucilleCore::askQuestionAnswerAsBoolean("priority today ? : ")
            XCache::set("c5b3502c-6773-4b4d-b830-9b0e76375ac8:#{item["uuid"]}", flag.to_s)
        }
    end

    # --------------------------------------------------

    # TxZero::itemsForListing()
    def self.itemsForListing()
        TxZero::ensureExtraAttributes()
        items = TxZero::items()
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        p1, p2 = items.partition{|item| XCache::getOrNull("c5b3502c-6773-4b4d-b830-9b0e76375ac8:#{item["uuid"]}") == "true" }
        p1 + p2
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
