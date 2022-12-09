# encoding: UTF-8

class NxTodos

    # NxTodos::uuidToNx5Filepath(uuid)
    def self.uuidToNx5Filepath(uuid)
        "#{Config::pathToDataCenter()}/NxTodo/#{uuid}.Nx5"
    end

    # NxTodos::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTodo")
            .select{|filepath| filepath[-4, 4] == ".Nx5" }
    end

    # NxTodos::items()
    def self.items()
        NxTodos::filepaths()
            .map{|filepath| Nx5Ext::readFileAsAttributesOfObject(filepath) }
    end

    # NxTodos::getItemAtFilepathOrNull(filepath)
    def self.getItemAtFilepathOrNull(filepath)
        return nil if !File.exists?(filepath)
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # NxTodos::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        filepath = NxTodos::uuidToNx5Filepath(uuid)
        return nil if !File.exists?(filepath)
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # NxTodos::commitObject(item)
    def self.commitObject(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxTodos::uuidToNx5Filepath(item["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, item["uuid"])
        end
        item.each{|key, value|
            Nx5::emitEventToFile1(filepath, key, value)
        }
    end

    # NxTodos::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxTodos::uuidToNx5Filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
        Item2Cx22::garbageCollection(uuid)
    end

    # NxTodos::setAttribute(uuid, attname, attvalue)
    def self.setAttribute(uuid, attname, attvalue)
        Nx5Ext::setAttribute(NxTodos::uuidToNx5Filepath(uuid), attname, attvalue)
    end

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
        nx113 = Nx113Make::interactivelyMakeNx113OrNull(NxTodos::getElizabethOperatorForUUID(uuid))
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
        NxTodos::commitObject(item)
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
        NxTodos::items()
            .select{|item|
                icx = Item2Cx22::getCx22OrNull(item["uuid"])
                icx and (icx["uuid"] == cx22["uuid"])
            }
    end

    # NxTodos::itemsWithoutCx22()
    def self.itemsWithoutCx22()
        NxTodos::items()
            .select{|item| Item2Cx22::getCx22OrNull(item["uuid"]).nil? }
    end

    # NxTodos::firstUnixtimeOrderItemsForCx22(cx22)
    def self.firstUnixtimeOrderItemsForCx22(cx22)
        filepath = "#{Config::pathToDataCenter()}/Cx22-to-FirstItems/#{cx22["uuid"]},json"
        if File.exists?(filepath) then
            packet = JSON.parse(IO.read(filepath)) # {unixtime, uuids}
            if (Time.new.to_i - packet["unixtime"]) < 3600 then
                return packet["uuids"]
                            .map{|uuid| NxTodos::getItemOrNull(uuid) }
                            .compact
            end
        end
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
    end

    # NxTodos::listingItems()
    def self.listingItems()
        filepath = "#{Config::pathToDataCenter()}/NxTodo-ListingItems.json"
        if File.exists?(filepath) then
            packet = JSON.parse(IO.read(filepath)) # {unixtime, uuids}
            if (Time.new.to_i - packet["unixtime"]) < 3600 then
                return packet["uuids"]
                            .map{|uuid| NxTodos::getItemOrNull(uuid) }
                            .compact
            end
        end
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
    end

    # --------------------------------------------------
    # Operations

    # NxTodos::getElizabethOperatorForUUID(uuid)
    def self.getElizabethOperatorForUUID(uuid)
        filepath = NxTodos::uuidToNx5Filepath(uuid)
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, uuid)
        end
        ElizabethNx5.new(filepath)
    end

    # NxTodos::getElizabethOperatorForItem(item)
    def self.getElizabethOperatorForItem(item)
        raise "(error: c0581614-3ee5-4ed3-a192-537ed22c1dce)" if item["mikuType"] != "NxTodo"
        filepath = NxTodos::uuidToNx5Filepath(item["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, item["uuid"])
        end
        ElizabethNx5.new(filepath)
    end

    # NxTodos::access(item)
    def self.access(item)
        puts NxTodos::toString(item).green
        if item["nx113"] then
            Nx113Access::access(NxTodos::getElizabethOperatorForItem(item), item["nx113"])
        end
    end

    # NxTodos::edit(item) # item
    def self.edit(item)
        if item["nx113"].nil? then
            puts "This item doesn't have a Nx113 attached to it"
            status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
            if status then
                PolyActions::editDescription(item)
                return NxTodos::getItemOrNull(item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::editNx113Carrier(item)
        NxTodos::getItemOrNull(item["uuid"])
    end

    # NxTodos::probe(item)
    def self.probe(item)
        loop {
            actions = ["access", "update description", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                NxTodos::access(item)
            end
            if option == "update description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                NxTodos::setAttribute(item["uuid"], "description", description)
                item = NxTodos::getItemOrNull(item["uuid"])
            end
            if action == "destroy" then
                NxTodos::destroy(item["uuid"])
                PolyActions::garbageCollectionAfterItemDeletion(item)
                return
            end
        }
    end
end
