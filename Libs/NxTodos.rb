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
        Cx22Mapping::garbageCollection(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTodos::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = CommonUtils::timeStringL22() # We want the items to come in time order, ideally
        nx113 = Nx113Make::interactivelyMakeNx113OrNull(NxTodos::getElizabethOperatorForUUID(uuid))
        lightspeed = LightSpeed::interactivelyCreateNewLightSpeed()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "lightspeed"  => lightspeed
        }
        NxTodos::commitObject(item)
        item
    end

    # NxTodos::issueFromElements(uuid, description, nx113, lightspeed)
    def self.issueFromElements(uuid, description, nx113, lightspeed)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "lightspeed"  => lightspeed
        }
        NxTodos::commitObject(item)
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

    # NxTodos::getTopUnderPerformingCx22OrNull()
    def self.getTopUnderPerformingCx22OrNull()
        Cx22::itemsInCompletionOrder()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .select{|cx22| Ax39::completionRatio(cx22["uuid"], cx22["ax39"]) < 1 }
            .first
    end

    # NxTodos::listingItemsUseTheForce()
    def self.listingItemsUseTheForce()
        puts "> NxTodos::listingItemsUseTheForce()"
        NxTodos::filepaths()
            .map{|filepath|
                item = Nx5Ext::readFileAsAttributesOfObject(filepath)
                priority = PolyFunctions::listingPriorityOrNull(item)
                {
                    "item"     => item,
                    "priority" => priority || -1
                }
            }
            .sort{|p1, p2| p1["priority"] <=> p2["priority"] }
            .reverse
            .first(20)
            .map{|packet| packet["item"] }
    end

    # NxTodos::listingItems()
    def self.listingItems()
        filepath = LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTodo-ListingItems").select{|filepath| filepath[-5, 5] == ".json" }.last
        return [] if filepath.nil?
        packet = JSON.parse(IO.read(filepath)) # {"instanceId": String, "unixtime": Float, "items": Array[Item] }
        packet["items"].map{|item| NxTodos::getItemOrNull(item["uuid"]) }.compact
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
            actions = ["access", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                NxTodos::access(item)
            end
            if action == "destroy" then
                NxTodos::destroy(item["uuid"])
                PolyActions::garbageCollectionAfterItemDeletion(item)
                return
            end
        }
    end

    # NxTodos::generateListingPacket()
    def self.generateListingPacket()
        packet = {
            "instanceId" => Config::thisInstanceId(),
            "unixtime"   => Time.new.to_i,
            "items"      => NxTodos::listingItemsUseTheForce()
        }
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTodo-ListingItems").each{|filepath| LucilleCore::removeFileSystemLocation(filepath) }
        filepath = "#{Config::pathToDataCenter()}/NxTodo-ListingItems/#{CommonUtils::timeStringL22()}-#{Config::thisInstanceId()}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(packet)) }
    end

    # NxTodos::listingItemsManager()
    def self.listingItemsManager()
        Thread.new {
            loop {
                sleep 1200
                filepath = LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTodo-ListingItems").select{|filepath| filepath[-5, 5] == ".json" }.last
                if filepath.nil? then
                    NxTodos::generateListingPacket()
                    next
                end
                packet = JSON.parse(IO.read(filepath))
                # {"instanceId": String, "unixtime": Float, "items": Array[Item] }
                if packet["instanceId"] < Config::thisInstanceId() then
                    NxTodos::generateListingPacket()
                else
                    if (Time.new.to_i - packet["unixtime"]) > 3600*2 then
                        NxTodos::generateListingPacket()
                    end
                end
            }
        }
    end
end
