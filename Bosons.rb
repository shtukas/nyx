
# encoding: UTF-8

class Bosons

    # Bosons::make(clique, quark)
    def self.make(clique, quark)
        {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "13f3499d-fa9c-44bb-91d3-8a3ccffecefb",
            "unixtime"   => Time.new.to_f,
            "cliqueuuid" => clique["uuid"],
            "quarkuuid"  => quark["uuid"]
        }
    end

    # Bosons::issue(clique, quark)
    def self.issue(clique, quark)
        boson = Bosons::make(clique, quark)
        NyxObjects::put(boson)
        boson
    end

    # Bosons::getQuarksForClique(clique)
    def self.getQuarksForClique(clique)
        NyxObjects::getSet("13f3499d-fa9c-44bb-91d3-8a3ccffecefb")
            .select{|boson| boson["cliqueuuid"] == clique["uuid"] }
            .map{|boson| boson["quarkuuid"] }
            .map{|quarkuuid| Quarks::getOrNull(quarkuuid) }
            .compact
    end

    # Bosons::getCliquesForQuark(quark)
    def self.getCliquesForQuark(quark)
        NyxObjects::getSet("13f3499d-fa9c-44bb-91d3-8a3ccffecefb")
            .select{|boson| boson["quarkuuid"] == quark["uuid"] }
            .map{|boson| boson["cliqueuuid"] }
            .map{|cliqueuuid| Cliques::getOrNull(cliqueuuid) }
            .compact
    end

    # Bosons::destroy(clique, quark)
    def self.destroy(clique, quark)
        NyxObjects::getSet("13f3499d-fa9c-44bb-91d3-8a3ccffecefb")
            .select{|boson| 
                b1 = (boson["cliqueuuid"] == clique["uuid"])
                b2 = (boson["quarkuuid"] == quark["uuid"])
                b1 and b2
            }
            .first(1)
            .each{|boson| NyxObjects::destroy(boson["uuid"]) }
    end

    # Bosons::linked?(clique, quark)
    def self.linked?(clique, quark)
        NyxObjects::getSet("13f3499d-fa9c-44bb-91d3-8a3ccffecefb")
            .any?{|boson|  
                b1 = (boson["cliqueuuid"] == clique["uuid"])
                b2 = (boson["quarkuuid"] == quark["uuid"])
                b1 and b2
            }
    end
end
