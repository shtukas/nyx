# encoding: UTF-8

class Nx15

    # Nx15::interactivelyCreateNew()
    def self.interactivelyCreateNew()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("plus", ["until-done-for-the-day", "time-commitment"])
        if type.nil? then
            return {
                "type"  => "time-commitment",
                "value" => 1
            }
        end
        if type == "time-commitment" then
            hours = LucilleCore::askQuestionAnswerAsString("hours ? ").to_f
            return {
                "type"  => "time-commitment",
                "value" => hours
            }
        end
        if type == "until-done-for-the-day" then
            return {
                "type"  => "until-done-for-the-day"
            }
        end
    end

    # Nx15::toString(nx15)
    def self.toString(nx15)
        if nx15["type"] == "time-commitment" then
            return "time: #{nx15["value"]}"
        end
        if nx15["type"] == "until-done-for-the-day" then
            return "until done"
        end
    end

end

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

    # TxPlus::interactivelyIssueNewOrNull(description = nil)
    def self.interactivelyIssueNewOrNull(description = nil)
        if description.nil? or description == "" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
        else
            puts "description: #{description}"
        end

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::types(), uuid)
        nx15  = Nx15::interactivelyCreateNew()

        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxPlus",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "nx111"       => nx111,
          "nx15"        => nx15
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # TxPlus::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        "(plus) #{item["description"]}#{nx111String} (rt: #{BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]).round(2)}) (#{Nx15::toString(item["nx15"])})"
    end

    # TxPlus::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(plus) #{item["description"]}"
    end

    # TxPlus::totalTimeCommitment()
    def self.totalTimeCommitment()
        TxPlus::items()
            .select{|item| item["nx15"]["type"] == "time-commitment" }
            .map{|item| item["nx15"]["value"] }
            .inject(0, :+)
    end

    # --------------------------------------------------
    # Operations

    # TxPlus::doubleDots(item)
    def self.doubleDots(item)

        if !NxBallsService::isRunning(item["uuid"]) then
            NxBallsService::issue(item["uuid"], item["announce"] ? item["announce"] : "(item: #{item["uuid"]})" , [item["uuid"]])
        end

        LxAction::action("access", item)

        answer = LucilleCore::askQuestionAnswerAsString("`continue` or `done` ? ")

        if answer == "contiue" then
            return
        end

        if answer == "done" then
            TxPlus::done(item)
        end
    end

    # TxPlus::done(item)
    def self.done(item)
        puts TxPlus::toString(item).green
        NxBallsService::close(item["uuid"], true)
        answer = LucilleCore::askQuestionAnswerAsString("This is a TxPlus. Do you want to: `done for the day`, `destroy`, `nothing` ? ")
        if answer == "done for the day" then
            XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
        end
        if answer == "destroy" then
            if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of TxPlus '#{item["description"].green}' ? ", true) then
                TxPlus::destroy(item["uuid"])
            end
        end
    end

    # TxPlus::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxPlus::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("plus", items, lambda{|item| TxPlus::toString(item) })
            break if item.nil?
            Landing::implementsNx111Landing(item)
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
