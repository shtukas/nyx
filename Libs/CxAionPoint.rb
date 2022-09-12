
# encoding: UTF-8

class CxAionPoint

    # CxAionPoint::items()
    def self.items()
        TheIndex::mikuTypeToItems("CxAionPoint")
    end

    # CxAionPoint::interactivelyIssueNewForOwnerOrNull(owneruuid)
    def self.interactivelyIssueNewForOwnerOrNull(owneruuid)
        uuid = SecureRandom.uuid

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        location = CommonUtils::interactivelySelectDesktopLocationOrNull()
        return nil if location.nil?

        operator = DxF1Elizabeth.new(uuid)

        rootnhash = AionCore::commitLocationReturnHash(operator, location)

        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "CxAionPoint")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "owneruuid", owneruuid)
        DxF1::setAttribute2(uuid, "rootnhash", rootnhash)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 2295bb26-24ee-41c1-ae8d-a918367977c2) How did that happen ? 🤨"
        end
        item
    end

    # CxAionPoint::issueNewForOwnerOrNull(owneruuid, location)
    def self.issueNewForOwnerOrNull(owneruuid, location)
        uuid = SecureRandom.uuid

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        operator = DxF1Elizabeth.new(uuid)

        rootnhash = AionCore::commitLocationReturnHash(operator, location)

        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "CxAionPoint")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "owneruuid", owneruuid)
        DxF1::setAttribute2(uuid, "rootnhash", rootnhash)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 2295bb26-24ee-41c1-ae8d-a918367977c2) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # CxAionPoint::toString(item)
    def self.toString(item)
        "(CxAionPoint) #{item["description"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # CxAionPoint::access(item)
    def self.access(item)
        operator = DxF1Elizabeth.new(item["uuid"])
        rootnhash = item["rootnhash"]
        parentLocation = "#{ENV['HOME']}/Desktop/CxAionPoint-Export-#{SecureRandom.hex(4)}"
        FileUtils.mkdir(parentLocation)
        AionCore::exportHashAtFolder(operator, rootnhash, parentLocation)
        puts "Item exported at #{parentLocation}"
        LucilleCore::pressEnterToContinue()
    end

    # CxAionPoint::edit(item) # item
    def self.edit(item)
        operator = DxF1Elizabeth.new(item["uuid"])
        rootnhash = item["rootnhash"]
        exportLocation = "#{ENV['HOME']}/Desktop/CxAionPoint-Edit-#{SecureRandom.hex(4)}"
        FileUtils.mkdir(exportLocation)
        AionCore::exportHashAtFolder(operator, rootnhash, exportLocation)
        puts "Item exported at #{exportLocation}. Continue to upload update"
        LucilleCore::pressEnterToContinue()

        acquireLocationInsideExportFolder = lambda {|exportLocation|
            locations = LucilleCore::locationsAtFolder(exportLocation).select{|loc| File.basename(loc)[0, 1] != "."}
            if locations.size == 0 then
                puts "I am in the middle of a CxAionPoint edit. I cannot see anything inside the export folder"
                puts "Exit"
                exit
            end
            if locations.size == 1 then
                return locations[0]
            end
            if locations.size > 1 then
                puts "I am in the middle of a CxAionPoint edit. I found more than one location in the export folder."
                puts "Exit"
                exit
            end
        }

        location = acquireLocationInsideExportFolder.call(exportLocation)

        uuid = item["uuid"]
        operator = DxF1Elizabeth.new(uuid)
        rootnhash = AionCore::commitLocationReturnHash(operator, location)
        DxF1::setAttribute2(uuid, "rootnhash", rootnhash)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)

        return TheIndex::getItemOrNull(item["uuid"])
    end
end
