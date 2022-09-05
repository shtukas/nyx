
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

        operator = DxF1Elizabeth.new(uuid, true, true)

        rootnhash = AionCore::commitLocationReturnHash(operator, location)

        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "CxAionPoint")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "owneruuid", owneruuid)
        DxF1::setAttribute2(uuid, "rootnhash", rootnhash)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
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

        operator = DxF1Elizabeth.new(uuid, true, true)

        rootnhash = AionCore::commitLocationReturnHash(operator, location)

        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "CxAionPoint")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "owneruuid", owneruuid)
        DxF1::setAttribute2(uuid, "rootnhash", rootnhash)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
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
        operator = DxF1Elizabeth.new(item["uuid"], true, true)
        rootnhash = item["rootnhash"]
        parentLocation = "#{ENV['HOME']}/Desktop/DxPure-Export-#{SecureRandom.hex(4)}"
        FileUtils.mkdir(parentLocation)
        AionCore::exportHashAtFolder(operator, rootnhash, parentLocation)
        puts "Item exported at #{parentLocation}"
        LucilleCore::pressEnterToContinue()
    end

    # CxAionPoint::edit(item) # item
    def self.edit(item)
        operator = DxF1Elizabeth.new(item["uuid"], true, true)
        rootnhash = item["rootnhash"]
        parentLocation = "#{ENV['HOME']}/Desktop/CxAionPoint-Edit-#{SecureRandom.hex(4)}"
        FileUtils.mkdir(parentLocation)
        AionCore::exportHashAtFolder(operator, rootnhash, parentLocation)
        puts "Item exported at #{parentLocation}. Continue to upload update"
        LucilleCore::pressEnterToContinue()

        location = CommonUtils::interactivelySelectDesktopLocationOrNull()
        return item if location.nil?

        uuid = item["uuid"]
        operator = DxF1Elizabeth.new(uuid, true, true)
        rootnhash = AionCore::commitLocationReturnHash(operator, location)
        DxF1::setAttribute2(uuid, "rootnhash", rootnhash)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)

        return TheIndex::getItemOrNull(item["uuid"])
    end
end
