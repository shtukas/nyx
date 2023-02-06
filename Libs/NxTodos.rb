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

    # NxTodos::destroy(uuid)
    def self.destroy(uuid)
        ObjectStore2::destroy("NxTodos", uuid)
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
        board = NxBoards::getItemOfNull("b093459d-70a7-4317-aa7e-326e53bd626a") # vienna (latest)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"     => board["uuid"], # vienna (latest)
            "boardposition" => NxBoards::getBoardNextPosition(board)
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

    # NxTodos::issueUsingItem(item)
    def self.issueUsingItem(item)
        if item["mikuType"] == "NxTop" then
            board, position = NxBoards::interactivelyDecideBoardPositionPair()
            newitem = item.clone
            newitem["uuid"] = SecureRandom.uuid
            newitem["mikuType"] = "NxTodo"
            newitem["boarduuid"] = board["uuid"]
            newitem["boardposition"] = position
            NxTodos::commit(newitem)
            NxTops::destroy(item["uuid"])
            return
        end
        if item["mikuType"] == "NxDrop" then
            board, position = NxBoards::interactivelyDecideBoardPositionPair()
            newitem = item.clone
            newitem["uuid"] = SecureRandom.uuid
            newitem["mikuType"] = "NxTodo"
            newitem["boarduuid"] = board["uuid"]
            newitem["boardposition"] = position
            NxTodos::commit(newitem)
            NxDrops::destroy(item["uuid"])
            return
        end
        if item["mikuType"] == "NxOndate" then
            board, position = NxBoards::interactivelyDecideBoardPositionPair()
            newitem = item.clone
            newitem["uuid"] = SecureRandom.uuid
            newitem["mikuType"] = "NxTodo"
            newitem["boarduuid"] = board["uuid"]
            newitem["boardposition"] = position
            NxTodos::commit(newitem)
            NxOndates::destroy(item["uuid"])
            return
        end

        raise "I do not know how to #{NxTodos::issueUsingItem(JSON.pretty_generate(item))}"
    end

    # --------------------------------------------------
    # Data

    # NxTodos::toString(item)
    def self.toString(item)
        "(todo) (#{"%8.3f" % item["boardposition"]}) #{item["description"]}"
    end

    # NxTodos::toStringForFirstItem(item)
    def self.toStringForFirstItem(item)
        "#{item["description"]}"
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
end
