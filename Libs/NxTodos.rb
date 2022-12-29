# encoding: UTF-8

class NxTodos

    # --------------------------------------------------
    # Makers

    # NxTodos::decidePriority()
    def self.decidePriority()
        priority = LucilleCore::askQuestionAnswerAsString("priority 1, 2, 3 : ").to_i
        if ![1, 2, 3].include?(priority) then
            return NxTodos::decidePriority()
        end
        priority
    end

    # NxTodos::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = CommonUtils::timeStringL22() # We want the items to come in time order, ideally
        nx113 = Nx113Make::interactivelyMakeNx113OrNull()
        priority = NxTodos::decidePriority()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "priority"    => priority
        }
        ItemsManager::commit("NxTodo", item)
        item
    end

    # NxTodos::issueUsingNxOndate(nxondate)
    def self.issueUsingNxOndate(nxondate)
        item = nxondate.clone
        item["uuid"] = CommonUtils::timeStringL22()
        item["mikuType"] = "NxTodo"
        item["priority"] = NxTodos::decidePriority()
        ItemsManager::commit("NxTodo", item)
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

    # NxTodos::itemsForCx22(cx22)
    def self.itemsForCx22(cx22)
        ItemsManager::items("NxTodo")
            .select{|item|
                icx = ItemToCx22::getCx22OrNull(item["uuid"])
                icx and (icx["uuid"] == cx22["uuid"])
            }
    end

    # NxTodos::itemsWithoutCx22()
    def self.itemsWithoutCx22()
        ItemsManager::items("NxTodo")
            .select{|item| ItemToCx22::getCx22OrNull(item["uuid"]).nil? }
    end

    # NxTodos::firstItemsForCx22(cx22)
    def self.firstItemsForCx22(cx22)
        filepath = "#{Config::pathToDataCenter()}/Cx22-to-FirstItems/#{cx22["uuid"]}.json"

        getDataOrNull = lambda {|filepath|
            return nil if !File.exists?(filepath)
            packet = JSON.parse(IO.read(filepath))
            packet["uuids"]
                .map{|uuid| ItemsManager::getOrNull("NxTodo", uuid) }
                .compact
        }

        getRecentDataOrNull = lambda {|filepath|
            return nil if !File.exists?(filepath)
            packet = JSON.parse(IO.read(filepath))
            return nil if (Time.new.to_i - packet["unixtime"]) > 3600
            packet["uuids"]
                .map{|uuid| ItemsManager::getOrNull("NxTodo", uuid) }
                .compact
        }

        issueNewFile = lambda {|filepath, cx22|
            items = NxTodos::itemsForCx22(cx22)
                        .sort{|i1, i2| i1["priority"] <=> i2["priority"] }
                        .first(10)
            uuids = items.map{|item| item["uuid"] }
            packet = {
                "unixtime" => Time.new.to_i,
                "uuids"    => uuids
            }
            File.open(filepath,  "w"){|f| f.puts(JSON.pretty_generate(packet)) }
            items
        }

        if Config::getOrNull("isLeaderInstance") then
            items = getRecentDataOrNull.call(filepath)
            return items if items
            return issueNewFile.call(filepath, cx22)
        else
            return (getDataOrNull.call(filepath) || [])
        end
    end

    # NxTodos::listingItems()
    def self.listingItems()
        filepath = "#{Config::pathToDataCenter()}/NxTodo-ListingItems.json"

        getDataOrNull = lambda {|filepath|
            return nil if !File.exists?(filepath)
            packet = JSON.parse(IO.read(filepath))
            packet["uuids"]
                .map{|uuid| ItemsManager::getOrNull("NxTodo", uuid) }
                .compact
        }

        getRecentDataOrNull = lambda {|filepath|
            return nil if !File.exists?(filepath)
            packet = JSON.parse(IO.read(filepath))
            return nil if (Time.new.to_i - packet["unixtime"]) > 3600
            packet["uuids"]
                .map{|uuid| ItemsManager::getOrNull("NxTodo", uuid) }
                .compact
        }

        issueNewFile = lambda {|filepath|
            items = NxTodos::itemsWithoutCx22()
                        .sort{|i1, i2| i1["priority"] <=> i2["priority"] }
                        .first(10)
            uuids = items.map{|item| item["uuid"] }
            packet = {
                "unixtime" => Time.new.to_i,
                "uuids"    => uuids
            }
            File.open(filepath,  "w"){|f| f.puts(JSON.pretty_generate(packet)) }
            items
        }

        if Config::getOrNull("isLeaderInstance") then
            items = getRecentDataOrNull.call(filepath)
            return items if items
            return issueNewFile.call(filepath)
        else
            return (getDataOrNull.call(filepath) || [])
        end
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
                return ItemsManager::getOrNull("NxTodo", item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::editNx113Carrier(item)
        ItemsManager::getOrNull("NxTodo", item["uuid"])
    end

    # NxTodos::probe(item)
    def self.probe(item)
        loop {
            item = ItemsManager::getOrNull("NxTodo", item["uuid"])
            actions = ["access", "update description", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                NxTodos::access(item)
            end
            if option == "update description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                item["description"] = description
                ItemsManager::commit("NxTodo", item)
            end
            if action == "destroy" then
                ItemsManager::destroy("NxTodo", item["uuid"])
                PolyActions::garbageCollectionAfterItemDeletion(item)
                return
            end
        }
    end
end
