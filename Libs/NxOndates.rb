# encoding: UTF-8

class NxOndates

    # NxOndates::uuidToNx5Filepath(uuid)
    def self.uuidToNx5Filepath(uuid)
        "#{Config::pathToDataCenter()}/NxOndate/#{uuid}.Nx5"
    end

    # NxOndates::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxOndate")
            .select{|filepath| filepath[-4, 4] == ".Nx5" }
    end

    # NxOndates::items()
    def self.items()
        NxOndates::filepaths()
            .map{|filepath| 
                item = Nx5Ext::readFileAsAttributesOfObject(filepath)
                if item["mikuType"] != "NxOndate" then
                    Nx5Ext::setAttribute(filepath, "mikuType", "NxOndate")
                end
                item["mikuType"] = "NxOndate"
                item
             }
    end

    # NxOndates::getItemAtFilepathOrNull(filepath)
    def self.getItemAtFilepathOrNull(filepath)
        return nil if !File.exists?(filepath)
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # NxOndates::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        filepath = NxOndates::uuidToNx5Filepath(uuid)
        return nil if !File.exists?(filepath)
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # NxOndates::commitObject(item)
    def self.commitObject(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxOndates::uuidToNx5Filepath(item["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, item["uuid"])
        end
        item.each{|key, value|
            Nx5::emitEventToFile1(filepath, key, value)
        }
    end

    # NxOndates::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxOndates::uuidToNx5Filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
        Cx22::garbageCollection(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::interactivelyMakeNx113OrNull(NxOndates::getElizabethOperatorForUUID(uuid))
        datetime = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOndate",
            "unixtime"    => Time.new.to_i,
            "datetime"    => datetime,
            "description" => description,
            "nx113"       => nx113,
        }
        NxOndates::commitObject(item)
        item
    end

    # NxOndates::interactivelyIssueNewTodayOrNull()
    def self.interactivelyIssueNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("today (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::interactivelyMakeNx113OrNull(NxOndates::getElizabethOperatorForUUID(uuid))
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOndate",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
        }
        NxOndates::commitObject(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxOndates::toString(item)
    def self.toString(item)
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")
        "(ondate: #{item["datetime"][0, 10]}) #{item["description"]}#{nx113str}"
    end

    # NxOndates::listingItems()
    def self.listingItems()
        NxOndates::items().select{|item| item["datetime"][0, 10] <= Time.new.to_s[0, 10] }
    end

    # --------------------------------------------------
    # Operations

    # NxOndates::getElizabethOperatorForUUID(uuid)
    def self.getElizabethOperatorForUUID(uuid)
        filepath = NxOndates::uuidToNx5Filepath(uuid)
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, uuid)
        end
        ElizabethNx5.new(filepath)
    end

    # NxOndates::getElizabethOperatorForItem(item)
    def self.getElizabethOperatorForItem(item)
        raise "(error: c0581614-3ee5-4ed3-a192-537ed22c1dce)" if item["mikuType"] != "NxOndate"
        filepath = NxOndates::uuidToNx5Filepath(item["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, item["uuid"])
        end
        ElizabethNx5.new(filepath)
    end

    # NxOndates::access(item)
    def self.access(item)
        puts NxOndates::toString(item).green
        if item["nx113"] then
            Nx113Access::access(NxOndates::getElizabethOperatorForItem(item), item["nx113"])
        end
    end

    # NxOndates::edit(item) # item
    def self.edit(item)
        if item["nx113"].nil? then
            puts "This item doesn't have a Nx113 attached to it"
            status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
            if status then
                PolyActions::editDescription(item)
                return NxOndates::getItemOrNull(item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::editNx113Carrier(item)
        NxOndates::getItemOrNull(item["uuid"])
    end

    # NxOndates::probe(item)
    def self.probe(item)
        loop {
            actions = ["access", "redate", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                NxOndates::access(item)
                next
            end
            if action == "redate" then
                item["datetime"] = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
                NxOndates::commitObject(item)
                next
            end
            if action == "destroy" then
                NxOndates::destroy(item["uuid"])
                PolyActions::garbageCollectionAfterItemDeletion(item)
                return
            end
        }
    end
end
