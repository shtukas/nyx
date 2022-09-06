
# encoding: UTF-8

class DxAionPoint

    # DxAionPoint::items()
    def self.items()
        TheIndex::mikuTypeToItems("DxAionPoint")
    end

    # DxAionPoint::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        location = CommonUtils::interactivelySelectDesktopLocationOrNull()
        return nil if location.nil?

        operator = DxF1Elizabeth.new(uuid, true, true)

        rootnhash = AionCore::commitLocationReturnHash(operator, location)

        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "DxAionPoint")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "rootnhash", rootnhash)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 4cb89267-dcd5-44ca-8f06-530a8089cb3c) How did that happen ? 🤨"
        end
        item
    end

    # DxAionPoint::issueNewUsingLocation(location)
    def self.issueNewUsingLocation(location)
        uuid = SecureRandom.uuid

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = File.basename(location)

        operator = DxF1Elizabeth.new(uuid, true, true)

        rootnhash = AionCore::commitLocationReturnHash(operator, location)

        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "DxAionPoint")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "rootnhash", rootnhash)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: c2b65452-ab3b-44af-ba84-4b00f61a90e5) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # DxAionPoint::toString(item)
    def self.toString(item)
        "(DxAionPoint) #{item["description"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # DxAionPoint::access(item)
    def self.access(item)
        operator = DxF1Elizabeth.new(item["uuid"], true, true)
        rootnhash = item["rootnhash"]
        parentLocation = "#{ENV['HOME']}/Desktop/DxAionPoint-Export-#{SecureRandom.hex(4)}"
        FileUtils.mkdir(parentLocation)
        AionCore::exportHashAtFolder(operator, rootnhash, parentLocation)
        puts "Item exported at #{parentLocation}"
        LucilleCore::pressEnterToContinue()
    end

    # DxAionPoint::edit(item) # item
    def self.edit(item)
        operator = DxF1Elizabeth.new(item["uuid"], true, true)
        rootnhash = item["rootnhash"]
        exportLocation = "#{ENV['HOME']}/Desktop/DxAionPoint-Edit-#{SecureRandom.hex(4)}"
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
        operator = DxF1Elizabeth.new(uuid, true, true)
        rootnhash = AionCore::commitLocationReturnHash(operator, location)
        DxF1::setAttribute2(uuid, "rootnhash", rootnhash)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)

        return TheIndex::getItemOrNull(item["uuid"])
    end
end
