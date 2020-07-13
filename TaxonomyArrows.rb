
# encoding: UTF-8

class TaxonomyArrows

    # TaxonomyArrows::make(source, target)
    def self.make(source, target)
        {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "d83a3ff5-023e-482c-8658-f7cfdbb6b738",
            "unixtime"   => Time.new.to_f,
            "sourceuuid" => source["uuid"],
            "targetuuid" => target["uuid"]
        }
    end

    # TaxonomyArrows::issue(source, target)
    def self.issue(source, target)
        return if Cliques::isRoot?(target)
        arrow = TaxonomyArrows::make(source, target)
        NyxObjects::put(arrow)
        arrow
    end

    # TaxonomyArrows::getTargetsForSource(source)
    def self.getTargetsForSource(source)
        NyxObjects::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .select{|arrow| arrow["sourceuuid"] == source["uuid"] }
            .map{|arrow| arrow["targetuuid"] }
            .map{|targetuuid| NyxObjects::getOrNull(targetuuid) }
            .compact
    end

    # TaxonomyArrows::getSourcesForTarget(target)
    def self.getSourcesForTarget(target)
        NyxObjects::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .select{|arrow| arrow["targetuuid"] == target["uuid"] }
            .map{|arrow| arrow["sourceuuid"] }
            .map{|sourceuuid| NyxObjects::getOrNull(sourceuuid) }
            .compact
    end

    # TaxonomyArrows::destroyArrow(source, target)
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

    # TaxonomyArrows::arrowExists?(source, target)
    def self.arrowExists?(source, target)
        NyxObjects::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .any?{|arrow|  
                b1 = (arrow["sourceuuid"] == source["uuid"])
                b2 = (arrow["targetuuid"] == target["uuid"])
                b1 and b2
            }
    end
end
