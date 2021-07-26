# encoding: UTF-8

class Domains

    # Domains::defaul()
    def self.defaul()
        {
            "uuid" => "8310e938-9c61-4e1c-b122-b3d9fecd7a86",
            "name" => "default"
        }
    end

    # Domains::domains()
    def self.domains()
        [
            Domains::defaul(),
            {
                "uuid" => "d414c908-06c3-4959-a762-cc83a9bc6711",
                "name" => "work"
            }
        ]
    end

    # Domains::selectDomainOrNull()
    def self.selectDomainOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", Domains::domains(), lambda{|domain| domain["name"] })
    end

    # Domains::getDomainByUUIDOrNull(uuid)
    def self.getDomainByUUIDOrNull(uuid)
        Domains::domains().select{|domain| domain["uuid"] == uuid }.first
    end

    # Domains::getDomainForId(id)
    def self.getDomainForId(id)
        domainuuid = KeyValueStore::getOrNull(nil, "30ce4dfe-c6d8-4362-a123-2e6d8996d44d:#{id}")
        if domainuuid.nil? then
            Domains::defaul()
        else
            Domains::getDomainByUUIDOrNull(domainuuid) || Domains::defaul()
        end
    end
end
