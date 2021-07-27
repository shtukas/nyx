# encoding: UTF-8

class Domains

    # ------------------------------------------------------------
    # Domains 

    # Domains::defaul()
    def self.defaul()
        {
            "uuid" => "8310e938-9c61-4e1c-b122-b3d9fecd7a86",
            "name" => "default"
        }
    end

    # Domains::workDomain()
    def self.workDomain()
        {
            "uuid" => "d414c908-06c3-4959-a762-cc83a9bc6711",
            "name" => "work"
        }
    end

    # Domains::domains()
    def self.domains()
        [ Domains::defaul(), Domains::workDomain() ]
    end

    # Domains::getDomainByUUIDOrNull(uuid)
    def self.getDomainByUUIDOrNull(uuid)
        Domains::domains().select{|domain| domain["uuid"] == uuid }.first
    end

    # ------------------------------------------------------------
    # Mapping

    # Domains::getDomainForItem(itemid)
    def self.getDomainForItem(itemid)
        domainuuid = KeyValueStore::getOrNull(nil, "30ce4dfe-c6d8-4362-a123-2e6d8996d44d:#{itemid}")
        Domains::getDomainByUUIDOrNull(domainuuid) || Domains::defaul()
    end

    # Domains::setDomainForItem(itemid, domainuuid)
    def self.setDomainForItem(itemid, domainuuid)
        KeyValueStore::set(nil, "30ce4dfe-c6d8-4362-a123-2e6d8996d44d:#{itemid}", domainuuid)
    end

    # ------------------------------------------------------------
    # Interactions

    # Domains::selectDomainOrNull()
    def self.selectDomainOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", Domains::domains(), lambda{|domain| domain["name"] })
    end

    # ------------------------------------------------------------
    # Operations

    # Domains::getCurrentDomain()
    def self.getCurrentDomain()
        Work::shouldDisplayWork() ? Domains::workDomain() : Domains::defaul()
    end
end
