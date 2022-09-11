
# encoding: UTF-8

class CxFile

    # CxFile::items()
    def self.items()
        TheIndex::mikuTypeToItems("CxFile")
    end

    # CxFile::interactivelyIssueNewForOwnerOrNull(owneruuid)
    def self.interactivelyIssueNewForOwnerOrNull(owneruuid)
        uuid = SecureRandom.uuid

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        location = CommonUtils::interactivelySelectDesktopLocationOrNull()
        return nil if location.nil?
        return nil if !File.file?(location)
        filepath = location

        operator = DxF1Elizabeth.new(uuid)

        dottedExtension, nhash, parts = PrimitiveFiles::commitFileReturnDataElements(filepath, operator) # [dottedExtension, nhash, parts]

        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "CxFile")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "owneruuid", owneruuid)
        DxF1::setAttribute2(uuid, "dottedExtension", dottedExtension)
        DxF1::setAttribute2(uuid, "nhash", nhash)
        DxF1::setAttribute2(uuid, "parts", parts)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 7221bfe9-c2f7-4948-a878-e23e161ea728) How did that happen ? 🤨"
        end
        item
    end

    # CxFile::issueNewUsingLocationForOwner(owneruuid, filepath)
    def self.issueNewUsingLocationForOwner(owneruuid, filepath)
        raise "(error: 7a83d805-8eb7-4e19-a045-27f955fa1b8e) #{filepath}" if !File.exists?(filepath)
        raise "(error: 35f553da-4465-49bd-b393-756c367db176) #{filepath}" if !File.file?(filepath)

        uuid = SecureRandom.uuid

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        operator = DxF1Elizabeth.new(uuid)

        dottedExtension, nhash, parts = PrimitiveFiles::commitFileReturnDataElements(filepath, operator) # [dottedExtension, nhash, parts]

        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "CxFile")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "owneruuid", owneruuid)
        DxF1::setAttribute2(uuid, "dottedExtension", dottedExtension)
        DxF1::setAttribute2(uuid, "nhash", nhash)
        DxF1::setAttribute2(uuid, "parts", parts)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 7221bfe9-c2f7-4948-a878-e23e161ea728) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # CxFile::toString(item)
    def self.toString(item)
        "(CxFile) #{item["description"] ? item["description"] : "nhash: #{item["nhash"]}"}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # CxFile::access(item)
    def self.access(item)
        puts "CxFile: #{item["description"]}"
        dottedExtension = item["dottedExtension"]
        nhash = item["nhash"]
        parts = item["parts"]
        operator = DxF1Elizabeth.new(item["uuid"])
        filepath = "#{ENV['HOME']}/Desktop/#{nhash}#{dottedExtension}"
        File.open(filepath, "w"){|f|
            parts.each{|nhash|
                blob = operator.getBlobOrNull(nhash)
                raise "(error: 13709695-3dca-493b-be46-62d4ef6cf18f)" if blob.nil?
                f.write(blob)
            }
        }
        system("open '#{filepath}'")
        puts "Item exported at #{filepath}"
        LucilleCore::pressEnterToContinue()
    end
end
