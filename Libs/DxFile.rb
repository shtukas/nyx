
# encoding: UTF-8

class DxFile

    # DxFile::items()
    def self.items()
        TheIndex::mikuTypeToItems("DxFile")
    end

    # DxFile::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description.nil?

        location = CommonUtils::interactivelySelectDesktopLocationOrNull()
        return nil if location.nil?
        return nil if !File.file?(location)
        filepath = location

        operator = DxF1Elizabeth.new(uuid)

        dottedExtension, nhash, parts = PrimitiveFiles::commitFileReturnDataElements(filepath, operator) # [dottedExtension, nhash, parts]

        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "DxFile")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "dottedExtension", dottedExtension)
        DxF1::setAttribute2(uuid, "nhash", nhash)
        DxF1::setAttribute2(uuid, "parts", parts)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 7221bfe9-c2f7-4948-a878-e23e161ea728) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # DxFile::toString(item)
    def self.toString(item)
        "(DxFile) #{item["description"] ? item["description"] : "nhash: #{item["nhash"]}"}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # DxFile::access(item)
    def self.access(item)
        puts "DxFile: #{item["description"]}"
        puts "I do not yet know how to access a DxFile (I guess we just need to export the file, should not be too difficult)"
        LucilleCore::pressEnterToContinue()
    end
end
