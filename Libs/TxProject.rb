# encoding: UTF-8

class TxProject

    # TxProject::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxProject")
    end

    # TxProject::destroy(uuid)
    def self.destroy(uuid)
        Bank::put("todo-done-count-afb1-11ac2d97a0a8", 1)
        Librarian::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxProject::interactivelyIssueNewOrNull(description = nil)
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

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxProject",
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

    # TxProject::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        "(project) #{item["description"]}#{nx111String} (rt: #{BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]).round(2)})"
    end

    # TxProject::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(project) #{item["description"]}"
    end

    # TxProject::totalTimeCommitment()
    def self.totalTimeCommitment()
        TxProject::items()
            .select{|item| item["nx15"]["type"] == "time-commitment" }
            .map{|item| item["nx15"]["value"] }
            .inject(0, :+)
    end

    # --------------------------------------------------
    # Operations

    # TxProject::doubleDots(item)
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
            TxProject::done(item)
        end
    end

    # TxProject::done(item)
    def self.done(item)
        puts TxProject::toString(item).green
        NxBallsService::close(item["uuid"], true)
        answer = LucilleCore::askQuestionAnswerAsString("This is a TxProject. Do you want to: `done for the day`, `destroy` or nothing ? ")
        if answer == "done for the day" then
            XCache::setFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}", true)
        end
        if answer == "destroy" then
            if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of TxProject '#{item["description"].green}' ? ", true) then
                TxProject::destroy(item["uuid"])
            end
        end
    end

    # TxProject::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxProject::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("plus", items, lambda{|item| TxProject::toString(item) })
            break if item.nil?
            Landing::implementsNx111Landing(item)
        }
    end

    # --------------------------------------------------

    # TxProject::nx20s()
    def self.nx20s()
        Librarian::getObjectsByMikuType("TxProject")
            .map{|item|
                {
                    "announce" => TxProject::toStringForSearch(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end
