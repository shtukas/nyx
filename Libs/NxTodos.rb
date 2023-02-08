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

    # NxTodos::interactivelyIssueNewOrNull(streamOpt)
    def self.interactivelyIssueNewOrNull(streamOpt)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        stream = streamOpt ? streamOpt : NxStreams::interactivelySelectOne()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"     => stream["uuid"],
            "boardposition" => NxStreams::interactivelyDecideNewStreamPosition(stream)
        }
        NxTodos::commit(item)
        item
    end

    # NxTodos::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        coredataref = "url:#{DatablobStore::put(url)}"
        stream = NxStreams::getItemOfNull("b093459d-70a7-4317-aa7e-326e53bd626a") # vienna (latest)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"     => stream["uuid"], # vienna (latest)
            "boardposition" => NxStreams::computeNextStreamPosition(stream)
        }
        ObjectStore2::commit("NxTriages", item)
        item
    end

    # NxTodos::issueStreamLine(line, streamuuid, streamposition)
    def self.issueStreamLine(line, streamuuid, streamposition)
        description = line
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => nil,
            "boarduuid"     => streamuuid,
            "boardposition" => streamposition
        }
        NxTodos::commit(item)
        item
    end

    # NxTodos::issueUsingItem(item)
    def self.issueUsingItem(item)
        if item["mikuType"] == "NxTop" then
            stream, position = NxStreams::interactivelyDecideStreamPositionPair()
            newitem = item.clone
            newitem["uuid"] = SecureRandom.uuid
            newitem["mikuType"] = "NxTodo"
            newitem["boarduuid"] = stream["uuid"]
            newitem["boardposition"] = position
            NxTodos::commit(newitem)
            NxTops::destroy(item["uuid"])
            return
        end
        if item["mikuType"] == "NxDrop" then
            stream, position = NxStreams::interactivelyDecideStreamPositionPair()
            newitem = item.clone
            newitem["uuid"] = SecureRandom.uuid
            newitem["mikuType"] = "NxTodo"
            newitem["boarduuid"] = stream["uuid"]
            newitem["boardposition"] = position
            NxTodos::commit(newitem)
            NxDrops::destroy(item["uuid"])
            return
        end
        if item["mikuType"] == "NxOndate" then
            stream, position = NxStreams::interactivelyDecideStreamPositionPair()
            newitem = item.clone
            newitem["uuid"] = SecureRandom.uuid
            newitem["mikuType"] = "NxTodo"
            newitem["boarduuid"] = stream["uuid"]
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
        "(todo) (pos: #{"%8.3f" % item["boardposition"]}) #{item["description"]}"
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
