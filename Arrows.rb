
# encoding: UTF-8

class Arrows

    # Arrows::make(source, target)
    def self.make(source, target)
        {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "d83a3ff5-023e-482c-8658-f7cfdbb6b738",
            "unixtime"   => Time.new.to_f,
            "sourceuuid" => source["uuid"],
            "targetuuid" => target["uuid"]
        }
    end

    # Arrows::issue(source, target)
    def self.issue(source, target)
        return if Cliques::isRoot?(target)
        arrow = Arrows::make(source, target)
        NyxObjects::put(arrow)
        arrow
    end

    # Arrows::makeWithUUIDs(sourceuuid, targetuuid)
    def self.makeWithUUIDs(sourceuuid, targetuuid)
        {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "d83a3ff5-023e-482c-8658-f7cfdbb6b738",
            "unixtime"   => Time.new.to_f,
            "sourceuuid" => sourceuuid,
            "targetuuid" => targetuuid
        }
    end

    # Arrows::issueWithUUIDs(sourceuuid, targetuuid)
    def self.issueWithUUIDs(sourceuuid, targetuuid)
        arrow = Arrows::makeWithUUIDs(sourceuuid, targetuuid)
        NyxObjects::put(arrow)
        arrow
    end

    # Arrows::arrows()
    def self.arrows()
        NyxObjects::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
    end

    # Arrows::destroyArrow(source, target)
    def self.destroyArrow(source, target)
        NyxObjects::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .select{|arrow| 
                b1 = (arrow["sourceuuid"] == source["uuid"])
                b2 = (arrow["targetuuid"] == target["uuid"])
                b1 and b2
            }
            .first(1)
            .each{|arrow| NyxObjects::destroy(arrow["uuid"]) }
    end

    # Arrows::arrowExists?(source, target)
    def self.arrowExists?(source, target)
        NyxObjects::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .any?{|arrow|  
                b1 = (arrow["sourceuuid"] == source["uuid"])
                b2 = (arrow["targetuuid"] == target["uuid"])
                b1 and b2
            }
    end

    # Arrows::getTargetsForSource(source)
    def self.getTargetsForSource(source)
        NyxObjects::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .select{|arrow| arrow["sourceuuid"] == source["uuid"] }
            .map{|arrow| arrow["targetuuid"] }
            .uniq
            .map{|targetuuid| NyxObjects::getOrNull(targetuuid) }
            .compact
    end

    # Arrows::getTargetOfGivenSetsForSource(source, setids)
    def self.getTargetOfGivenSetsForSource(source, setids)
        Arrows::getTargetsForSource(source).select{|object|
            setids.include?(object["nyxNxSet"])
        }
    end

    # Arrows::getTargetsForSourceUUID(sourceuuid)
    def self.getTargetsForSourceUUID(sourceuuid)
        NyxObjects::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .select{|arrow| arrow["sourceuuid"] == sourceuuid }
            .map{|arrow| arrow["targetuuid"] }
            .uniq
            .map{|targetuuid| NyxObjects::getOrNull(targetuuid) }
            .compact
    end

    # Arrows::getTargetOfGivenSetsForSourceUUID(sourceuuid, setids)
    def self.getTargetOfGivenSetsForSourceUUID(sourceuuid, setids)
        Arrows::getTargetsForSourceUUID(sourceuuid).select{|object|
            setids.include?(object["nyxNxSet"])
        }
    end

    # Arrows::getSourcesForTarget(target)
    def self.getSourcesForTarget(target)
        NyxObjects::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .select{|arrow| arrow["targetuuid"] == target["uuid"] }
            .map{|arrow| arrow["sourceuuid"] }
            .uniq
            .map{|sourceuuid| NyxObjects::getOrNull(sourceuuid) }
            .compact
    end

    # Arrows::getSourceOfGivenSetsForTarget(target, setids)
    def self.getSourceOfGivenSetsForTarget(target, setids)
        Arrows::getSourcesForTarget(target).select{|object|
            setids.include?(object["nyxNxSet"])
        }
    end
end
