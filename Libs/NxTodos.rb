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

    # NxTodos::interactivelyIssueNewRegularOrNull()
    def self.interactivelyIssueNewRegularOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        board = NxBoards::interactivelySelectOne()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field2"      => "regular",
            "field11"     => coredataref,
            "boarduuid"   => board["uuid"]
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

    # --------------------------------------------------
    # Data

    # NxTodos::toString(item)
    def self.toString(item)
        flavour = (lambda {|item|
            return "" if item["field2"] == "regular"
            return ", ondate #{item["datetime"][0, 10]}" if item["field2"] == "ondate"
            return ", triage" if item["field2"] == "triage"
            raise "(error: ca9b365a-2e14-4523-8df9-fe2d6a6dd5f4) #{item}"
        }).call(item)
        "(todo#{flavour}) #{item["description"]}"
    end

    # NxTodos::toStringForSearch(item)
    def self.toStringForSearch(item)
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
