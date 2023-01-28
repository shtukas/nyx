# encoding: UTF-8

class NxTodosIO 

    # Utils

    # NxTodosIO::repositoryFolderPath()
    def self.repositoryFolderPath()
        "#{Config::pathToDataCenter()}/NxTodo"
    end

    # NxTodosIO::filepath(uuid)
    def self.filepath(uuid)
        "#{NxTodosIO::repositoryFolderPath()}/#{uuid}.json"
    end

    # Public Interface

    # NxTodosIO::commit(object)
    def self.commit(object)
        TodoDatabase2::commitItem(object)
    end

    # NxTodosIO::getOrNull(uuid)
    def self.getOrNull(uuid)
        TodoDatabase2::getItemByUUIDOrNull(uuid)
    end

    # NxTodosIO::items()
    def self.items()
        Database2Data::itemsForMikuType("NxTodo")
    end

    # NxTodosIO::destroy(uuid)
    def self.destroy(uuid)
        TodoDatabase2::destroy(uuid)
    end
end

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
        NxTodosIO::commit(item)
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
        NxTodosIO::items()
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

    # NxTodos::edit(item) # item
    def self.edit(item)
        if item["nx113"].nil? then
            puts "This item doesn't have a Nx113 attached to it"
            status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
            if status then
                PolyActions::editDescription(item)
                return NxTodosIO::getOrNull(item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::editNx113Carrier(item)
        NxTodosIO::getOrNull(item["uuid"])
    end

    # NxTodos::probe(item)
    def self.probe(item)
        loop {
            system("clear")
            item = NxTodosIO::getOrNull(item["uuid"])
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
                NxTodosIO::commit(item)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of NxTodo '#{NxTodos::toString(item)}' ? ") then
                    NxTodosIO::destroy(item["uuid"])
                    return
                end
            end
        }
    end
end
