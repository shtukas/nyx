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

        nx111 = Nx111::interactivelyCreateNewNx111OrNull()

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
            end
        end
    end

    # TxTodos::done(item)
    def self.done(item)
        TxTodos::destroy(item["uuid"], true)
    end

    # TxTodos::destroy(uuid, shouldForce)
    def self.destroy(uuid, shouldForce)
        if NxBallsService::isRunning(uuid) then
             NxBallsService::close(uuid, true)
        end
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
