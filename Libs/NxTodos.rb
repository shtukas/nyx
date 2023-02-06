# encoding: UTF-8

class NxTodos

    # NxTodos::items()
    def self.items()
        ObjectStore2::objects("NxTodos")
    end

    # NxTodos::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxTodos", item)
    end

    # --------------------------------------------------
    # Makers

    # NxTodos::interactivelyIssueNewOrNull(contextualBoardOpt)
    def self.interactivelyIssueNewOrNull(contextualBoardOpt)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        board = contextualBoardOpt ? contextualBoardOpt : NxBoards::interactivelySelectOne()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"     => board["uuid"],
            "boardposition" => NxBoards::decideNewBoardPosition(board)
        }
        NxTodos::commit(item)
        item
    end

    # NxTodos::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        coredataref = "url:#{DatablobStore::put(url)}"
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"   => "b093459d-70a7-4317-aa7e-326e53bd626a" # vienna (latest)
        }
        ObjectStore2::commit("NxTriages", item)
        item
    end

    # NxTodos::issueBoardLine(line, boarduuid, boardposition)
    def self.issueBoardLine(line, boarduuid, boardposition)
        description = line
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => nil,
            "boarduuid"     => boarduuid,
            "boardposition" => boardposition
        }
        NxTodos::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTodos::toString(item)
    def self.toString(item)
        "(todo) #{item["description"]}"
    end

    # NxTodos::listingItems()
    def self.listingItems()
        NxTodos::items().take(1)
    end

    # --------------------------------------------------
    # Operations

    # NxTodos::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end

    # NxTodos::doneprocess(item)
    def self.doneprocess(item)
        puts PolyFunctions::toString(item)
        if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTodo '#{item["description"].green}' ? ", true) then
            if item["field11"] then
                puts "You are attempting to done a NxTodo which carries a core data reference string"
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["destroy", "exit"])
                return if option == ""
                if option == "destroy" then
                    ObjectStore2::destroy("NxTodos", item["uuid"])
                    return
                end
                if option == "exit" then
                    return
                end
                return
            else
                ObjectStore2::destroy("NxTodos", item["uuid"])
            end
        end
    end
end
