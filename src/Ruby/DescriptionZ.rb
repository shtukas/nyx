
# encoding: UTF-8

class DescriptionZ

    # DescriptionZ::make(description)
    def self.make(description)
        raise "[DescriptionZ error 9482c130]" if description.strip.size == 0
        if description.lines.to_a.size > 1 then
            description = description.lines.first.strip
        end
        {
            "uuid"        => SecureRandom.uuid,
            "nyxNxSet"    => "4f5ae9bc-9b2a-46ff-9f8b-49bfcabc5a9f",
            "unixtime"    => Time.new.to_f,
            "description" => description
        }
    end

    # DescriptionZ::issue(description)
    def self.issue(description)
        object = DescriptionZ::make(description)
        NyxObjects::put(object)
        object
    end

    # DescriptionZ::descriptionz()
    def self.descriptionz()
        NyxObjects::getSet("4f5ae9bc-9b2a-46ff-9f8b-49bfcabc5a9f")
    end

    # DescriptionZ::getDescriptionZForSourceInTimeOrder(source)
    def self.getDescriptionZForSourceInTimeOrder(source)
        Arrows::getTargetsOfGivenSetsForSource(source, ["4f5ae9bc-9b2a-46ff-9f8b-49bfcabc5a9f"])
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # DescriptionZ::getLastDescriptionForSourceOrNull(source)
    def self.getLastDescriptionForSourceOrNull(source)
        zs = DescriptionZ::getDescriptionZForSourceInTimeOrder(source)
        return nil if zs.size == 0
        zs.last["description"]
    end

    # DescriptionZ::destroy(object)
    def self.destroy(object)
        NyxObjects::destroy(object)
    end
end
