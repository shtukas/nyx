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
        Cx22::garbageCollection(uuid)
    end

    # --------------------------------------------------
    # Makers

    # --------------------------------------------------
    # Data

    # NxTriages::toString(item)
    def self.toString(item)
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")
        "(triage)#{nx113str} #{item["description"]}"
    end

    # NxTriages::listingItems()
    def self.listingItems()
        NxTriages::filepaths().reduce([]){|selected, itemfilepath|
            if selected.size >= 10 then
                selected
            else
                item = NxTriages::getItemAtFilepathOrNull(itemfilepath)
                selected + [item]
            end
        }
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
end
