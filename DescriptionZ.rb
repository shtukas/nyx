
# encoding: UTF-8

class DescriptionZ

    # DescriptionZ::make(targetuuid, description)
    def self.make(targetuuid, description)
        raise "[DescriptionZ error 9482c130]" if description.strip.size == 0
        if description.lines.to_a.size > 1 then
            description = description.lines.first.strip
        end
        {
            "uuid"        => SecureRandom.uuid,
            "nyxNxSet"    => "4f5ae9bc-9b2a-46ff-9f8b-49bfcabc5a9f",
            "unixtime"    => Time.new.to_f,
            "targetuuid"  => targetuuid,
            "description" => description
        }
    end

    # DescriptionZ::issue(targetuuid, description)
    def self.issue(targetuuid, description)
        object = DescriptionZ::make(targetuuid, description)
        NyxObjects::put(object)
        object
    end

    # DescriptionZ::issue(targetuuid, description)
    def self.issueReplacementOfAnyExisting(targetuuid, description)
        existingobjects = DescriptionZ::getDescriptionZsForTargetInTimeOrder(targetuuid)
        object = DescriptionZ::make(targetuuid, description)
        NyxObjects::put(object)
        existingobjects.each{|o|
            DescriptionZ::destroy(o)
        }
        object
    end

    # DescriptionZ::getDescriptionZsForTargetInTimeOrder(targetuuid)
    def self.getDescriptionZsForTargetInTimeOrder(targetuuid)
        NyxObjects::getSet("4f5ae9bc-9b2a-46ff-9f8b-49bfcabc5a9f")
            .select{|object| object["targetuuid"] == targetuuid }
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # DescriptionZ::getLastDescriptionForTargetOrNull(targetuuid)
    def self.getLastDescriptionForTargetOrNull(targetuuid)
        zs = DescriptionZ::getDescriptionZsForTargetInTimeOrder(targetuuid)
        return nil if zs.size == 0
        zs.last["description"]
    end

    # DescriptionZ::destroy(object)
    def self.destroy(object)
        NyxObjects::destroy(object["uuid"])
    end
end
