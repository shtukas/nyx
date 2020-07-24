
# encoding: UTF-8

class NSDataTypeX

    # NSDataTypeX::currentTypeIdentifiers()
    def self.currentTypeIdentifiers()
        # NSDataTypeX with a type not in this list will be garbage collected.
        [
            "4868c01e-2621-4329-8602-6a6fc92bc51c" # description
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
        NyxObjects::put(object)
        object
    end

    # NSDataTypeX::attributes()
    def self.attributes()
        NyxObjects::getSet("5c99134b-2b61-4750-8519-49c1d896556f")
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

    # NSDataTypeXExtended::getLastDescriptionForTargetOrNull(target)
    def self.getLastDescriptionForTargetOrNull(target)
        attribute = NSDataTypeX::getLastAttributeOfGivenTypeForTargetOrNull(target["uuid"], "4868c01e-2621-4329-8602-6a6fc92bc51c")
        return nil if attribute.nil?
        attribute["payload"]
    end

    # NSDataTypeXExtended::issueDescriptionForTarget(target, description)
    def self.issueDescriptionForTarget(target, description)
        NSDataTypeX::issue(target["uuid"], "4868c01e-2621-4329-8602-6a6fc92bc51c", description)
    end
end
