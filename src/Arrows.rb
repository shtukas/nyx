
# encoding: UTF-8

class Arrows

    # Arrows::issueOrException(source, target)
    def self.issueOrException(source, target)
        raise "[error: bc82b3b6]" if (source["uuid"] == target["uuid"])
        if Arrows::exists?(source, target) then
            arrow = NyxObjects2::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
                        .select{|arrow|  
                            b1 = (arrow["sourceuuid"] == source["uuid"])
                            b2 = (arrow["targetuuid"] == target["uuid"])
                            b1 and b2
                        }.first
            raise "[error: 23b2e534]" if arrow.nil?
            return arrow
        end
        arrow = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "d83a3ff5-023e-482c-8658-f7cfdbb6b738",
            "unixtime"   => Time.new.to_f,
            "sourceuuid" => source["uuid"],
            "targetuuid" => target["uuid"]
        }
        NyxObjects2::put(arrow)
        arrow
    end

    # Arrows::arrows()
    def self.arrows()
        NyxObjects2::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
    end

    # Arrows::remove(source, target)
    def self.remove(source, target)
        NyxObjects2::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .select{|arrow| 
                b1 = (arrow["sourceuuid"] == source["uuid"])
                b2 = (arrow["targetuuid"] == target["uuid"])
                b1 and b2
            }
            .each{|arrow| NyxObjects2::destroy(arrow) }
    end

    # Arrows::exists?(source, target)
    def self.exists?(source, target)
        NyxObjects2::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .any?{|arrow|  
                b1 = (arrow["sourceuuid"] == source["uuid"])
                b2 = (arrow["targetuuid"] == target["uuid"])
                b1 and b2
            }
    end

    # Arrows::getTargetsForSource(source)
    def self.getTargetsForSource(source)
        NyxObjects2::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .select{|arrow| arrow["sourceuuid"] == source["uuid"] }
            .map{|arrow| arrow["targetuuid"] }
            .uniq
            .map{|targetuuid| NyxObjects2::getOrNull(targetuuid) }
            .compact
    end

    # Arrows::getSourcesForTarget(target)
    def self.getSourcesForTarget(target)
        NyxObjects2::getSet("d83a3ff5-023e-482c-8658-f7cfdbb6b738")
            .select{|arrow| arrow["targetuuid"] == target["uuid"] }
            .map{|arrow| arrow["sourceuuid"] }
            .uniq
            .map{|sourceuuid| NyxObjects2::getOrNull(sourceuuid) }
            .compact
    end
end
