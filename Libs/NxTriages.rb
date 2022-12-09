# encoding: UTF-8

class NxTriages

    # NxTriages::uuidToNx5Filepath(uuid)
    def self.uuidToNx5Filepath(uuid)
        "#{Config::pathToDataCenter()}/NxTriage/#{uuid}.Nx5"
    end

    # NxTriages::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTriage")
            .select{|filepath| filepath[-4, 4] == ".Nx5" }
    end

    # NxTriages::items()
    def self.items()
        NxTriages::filepaths()
            .map{|filepath| Nx5Ext::readFileAsAttributesOfObject(filepath) }
    end

    # NxTriages::getItemAtFilepathOrNull(filepath)
    def self.getItemAtFilepathOrNull(filepath)
        return nil if !File.exists?(filepath)
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # NxTriages::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        filepath = NxTriages::uuidToNx5Filepath(uuid)
        return nil if !File.exists?(filepath)
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # NxTriages::commitObject(item)
    def self.commitObject(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxTriages::uuidToNx5Filepath(item["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, item["uuid"])
        end
        item.each{|key, value|
            Nx5::emitEventToFile1(filepath, key, value)
        }
    end

    # NxTriages::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxTriages::uuidToNx5Filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # NxTriages::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        operator = NxTriages::getElizabethOperatorForUUID(uuid)
        nx113 = Nx113Make::aionpoint(operator, location)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTriage",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
        }
        NxTriages::commitObject(item)
        item
    end

    # NxTriages::issueUsingUrl(url)
    def self.issueUsingUrl(url)
        description = File.basename(location)
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::url(url)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTriage",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
        }
        NxTodos::commitObject(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTriages::toString(item)
    def self.toString(item)
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")
        "(triage) #{item["description"]}#{nx113str}"
    end

    # NxTriages::listingItems()
    def self.listingItems()
        NxTriages::items()
    end

    # --------------------------------------------------
    # Operations

    # NxTriages::getElizabethOperatorForUUID(uuid)
    def self.getElizabethOperatorForUUID(uuid)
        filepath = NxTriages::uuidToNx5Filepath(uuid)
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, uuid)
        end
        ElizabethNx5.new(filepath)
    end

    # NxTriages::getElizabethOperatorForItem(item)
    def self.getElizabethOperatorForItem(item)
        raise "(error: c0581614-3ee5-4ed3-a192-537ed22c1dce)" if item["mikuType"] != "NxTriage"
        filepath = NxTriages::uuidToNx5Filepath(item["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, item["uuid"])
        end
        ElizabethNx5.new(filepath)
    end

    # NxTriages::access(item)
    def self.access(item)
        puts NxTriages::toString(item).green
        if item["nx113"] then
            Nx113Access::access(NxTriages::getElizabethOperatorForItem(item), item["nx113"])
        end
    end

    # NxTriages::edit(item) # item
    def self.edit(item)
        if item["nx113"].nil? then
            puts "This item doesn't have a Nx113 attached to it"
            status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
            if status then
                PolyActions::editDescription(item)
                return NxTriages::getItemOrNull(item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::editNx113Carrier(item)
        NxTriages::getItemOrNull(item["uuid"])
    end

    # NxTriages::probe(item)
    def self.probe(item)
        loop {
            actions = ["access", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                NxTriages::access(item)
            end
            if action == "destroy" then
                NxTriages::destroy(item["uuid"])
                PolyActions::garbageCollectionAfterItemDeletion(item)
                return
            end
        }
    end

    # NxTriages::transmuteItemToNxTodo(item)
    def self.transmuteItemToNxTodo(item)
        # We apply this to only to Triage items
        if item["mikuType"] != "NxTriage" then
            puts "NxTriages::transmuteItemToNxTodo only applies to NxTriages"
            LucilleCore::pressEnterToContinue()
            return
        end

        filepath1 = NxTriages::uuidToNx5Filepath(item["uuid"])
        filepath2 = NxTodos::uuidToNx5Filepath(item["uuid"])

        # We start by setting a lightspeed
        lightspeed = LightSpeed::interactivelyCreateNewLightSpeed()
        Nx5Ext::setAttribute(filepath1, "lightspeed", lightspeed)

        # We set the new Miku Type
        Nx5Ext::setAttribute(filepath1, "mikuType", "NxTodo")

        FileUtils.mv(filepath1, filepath2)

        item = NxTodos::getItemOrNull(item["uuid"])
        if item.nil?  then
            puts "This should not have happened (error: 38cd2c4d-c0d6-4652-b83b-63b9c077448d)"
            puts "    - filepath1: #{filepath1}"
            puts "    - filepath2: #{filepath2}"
            exit
        end

        # The file has moved to the NxTodo folder, now let's ask for a group
        Item2Cx22::interactivelySelectAndMapToCx22OrNothing(item["uuid"])
    end
end
