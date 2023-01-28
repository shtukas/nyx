# encoding: UTF-8

class NxTodos

    # --------------------------------------------------
    # Makers

    # NxTodos::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = CommonUtils::timeStringL22()
        nx113 = Nx113Make::interactivelyMakeNx113OrNull()
        tcId = NxTimeFibers::interactivelySelectItem()["uuid"]
        tcPos = NxTimeFibers::interactivelyDecideProjectPosition(tcId)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "tcId"       => tcId,
            "tcPos" => tcPos
        }
        TodoDatabase2::commitItem(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTodos::toString(item)
    def self.toString(item)
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")
        "(todo) #{item["description"]}#{nx113str}"
    end

    # NxTodos::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(todo) #{item["description"]}"
    end

    # NxTodos::itemsForNxTimeFiber(tcId)
    def self.itemsForNxTimeFiber(tcId)
        Database2Data::itemsForMikuType("NxTodo")
            .select{|item|
                item["tcId"] == tcId
            }
    end

    # --------------------------------------------------
    # Operations

    # NxTodos::access(item)
    def self.access(item)
        puts NxTodos::toString(item).green
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        end
    end

    # NxTodos::probe(item)
    def self.probe(item)
        loop {
            system("clear")
            item = TodoDatabase2::getItemByUUIDOrNull(item["uuid"])
            puts NxTodos::toString(item)
            actions = ["access", "update description", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                NxTodos::access(item)
            end
            if action == "update description" then
                puts "edit description:"
                item["description"] = CommonUtils::editTextSynchronously(item["description"])
                TodoDatabase2::commitItem(item)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of NxTodo '#{NxTodos::toString(item)}' ? ") then
                    TodoDatabase2::destroy(item["uuid"])
                    return
                end
            end
        }
    end
end
