
# encoding: UTF-8

class NSDataTypeX

    # NSDataTypeX::currentTypeIdentifiers()
    def self.currentTypeIdentifiers()
        # NSDataTypeX with a type not in this list will be garbage collected.
        [
            "4868c01e-2621-4329-8602-6a6fc92bc51c", # Description
            "77b95849-efbb-4b3f-b353-347658486447", # DateTime ISO 8601
            "e55d3bcd-f193-42ac-a7b7-4b9fc31527c8", # Note
        ]
    end

    # NSDataTypeX::make(targetuuid, typeIdentifier, payload)
    def self.make(targetuuid, typeIdentifier, payload)
        raise "[error: 99f69854-ba25-437c-aeeb-96dc69386709]" if !NSDataTypeX::currentTypeIdentifiers().include?(typeIdentifier)
        {
            "uuid"           => SecureRandom.uuid,
            "nyxNxSet"       => "5c99134b-2b61-4750-8519-49c1d896556f",
            "unixtime"       => Time.new.to_f,
            "targetuuid"     => targetuuid,
            "typeIdentifier" => typeIdentifier,
            "payload"        => payload
        }
    end

    # NSDataTypeX::issue(targetuuid, typeIdentifier, payload)
    def self.issue(targetuuid, typeIdentifier, payload)
        object = NSDataTypeX::make(targetuuid, typeIdentifier, payload)
        NyxObjects2::put(object)
        object
    end

    # NSDataTypeX::attributes()
    def self.attributes()
        NyxObjects2::getSet("5c99134b-2b61-4750-8519-49c1d896556f")
    end

    # NSDataTypeX::getAttributesOfGivenTypeForTargetInTimeOrder(targetuuid, typeIdentifier)
    def self.getAttributesOfGivenTypeForTargetInTimeOrder(targetuuid, typeIdentifier)
        NSDataTypeX::attributes()
            .select{|attribute| (attribute["targetuuid"] == targetuuid) and (attribute["typeIdentifier"] == typeIdentifier)}
            .sort{|n1,n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # NSDataTypeX::getLastAttributeOfGivenTypeForTargetOrNull(targetuuid, typeIdentifier)
    def self.getLastAttributeOfGivenTypeForTargetOrNull(targetuuid, typeIdentifier)
        NSDataTypeX::getAttributesOfGivenTypeForTargetInTimeOrder(targetuuid, typeIdentifier).last
    end
end

class NSDataTypeXExtended

    # NSDataTypeXExtended::issueDescriptionForTarget(target, description)
    def self.issueDescriptionForTarget(target, description)
        NSDataTypeX::issue(target["uuid"], "4868c01e-2621-4329-8602-6a6fc92bc51c", description)
    end

    # NSDataTypeXExtended::getLastDescriptionForTargetOrNull(target)
    def self.getLastDescriptionForTargetOrNull(target)
        attribute = NSDataTypeX::getLastAttributeOfGivenTypeForTargetOrNull(target["uuid"], "4868c01e-2621-4329-8602-6a6fc92bc51c")
        return nil if attribute.nil?
        attribute["payload"]
    end

    # NSDataTypeXExtended::issueDateTimeIso8601ForTarget(target, datetime)
    def self.issueDateTimeIso8601ForTarget(target, datetime)
        raise "[error: 94222cc7-d035-4d9d-a7a8-e351a6bd1d12]" if !Miscellaneous::isDateTime_UTC_ISO8601(datetime)
        NSDataTypeX::issue(target["uuid"], "77b95849-efbb-4b3f-b353-347658486447", datetime)
    end

    # NSDataTypeXExtended::getLastDateTimeForTargetOrNull(target)
    def self.getLastDateTimeForTargetOrNull(target)
        attribute = NSDataTypeX::getLastAttributeOfGivenTypeForTargetOrNull(target["uuid"], "77b95849-efbb-4b3f-b353-347658486447")
        return nil if attribute.nil?
        attribute["payload"]
    end

    # NSDataTypeXExtended::issueNoteForTarget(target, text)
    def self.issueNoteForTarget(target, text)
        prefix = SecureRandom.hex
        filename = "#{prefix}.txt"
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/NSDataTypeX-e55d3bcd-f193-42ac-a7b7-4b9fc31527c8/#{filename}"
        File.open(filepath, "w"){|f| f.puts(text) }
        NSDataTypeX::issue(target["uuid"], "e55d3bcd-f193-42ac-a7b7-4b9fc31527c8", prefix)
    end

    # NSDataTypeXExtended::getLastNoteTextForTargetOrNull(target)
    def self.getLastNoteTextForTargetOrNull(target)
        attribute = NSDataTypeX::getLastAttributeOfGivenTypeForTargetOrNull(target["uuid"], "e55d3bcd-f193-42ac-a7b7-4b9fc31527c8")
        return nil if attribute.nil?
        prefix = attribute["payload"]
        filename = "#{prefix}.txt"
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/NSDataTypeX-e55d3bcd-f193-42ac-a7b7-4b9fc31527c8/#{filename}"
        if !File.exists?(filepath) then
            raise "436e21ad-9a82-419f-84b6-d43ce868a6eb"
        end
        IO.read(filepath)
    end
end
