
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

        DxF1::setJsonEncoded(uuid, "uuid", uuid)
        DxF1::setJsonEncoded(uuid, "mikuType", "DxFile")
        DxF1::setJsonEncoded(uuid, "unixtime", unixtime)
        DxF1::setJsonEncoded(uuid, "datetime", datetime)
        DxF1::setJsonEncoded(uuid, "description", description)
        DxF1::setJsonEncoded(uuid, "dottedExtension", dottedExtension)
        DxF1::setJsonEncoded(uuid, "nhash", nhash)
        DxF1::setJsonEncoded(uuid, "parts", parts)

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
        "(DxFile) #{item["description"]}"
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
