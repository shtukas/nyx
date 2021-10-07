# encoding: UTF-8

class Domains

    # Domains::items()
    def self.items()
        [
            {
                "filepath"    => "/Users/pascal/Desktop/Eva.txt",
                "domain"      => "eva"
            },
            {
                "filepath"    => "/Users/pascal/Desktop/Work.txt",
                "domain"      => "work"
            }
        ]
    end

    # Domains::getCurrentActiveDomain()
    def self.getCurrentActiveDomain()
        Work::isActiveDomain() ? "work" : "eva"
    end

    # Domains::domains()
    def self.domains()
        Domains::items().map{|item| item["domain"] }
    end

    # Domains::interactivelySelectDomainOrNull()
    def self.interactivelySelectDomainOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("domain: ", Domains::domains())
    end

    # Domains::setDomainForItem(id, domain)
    def self.setDomainForItem(id, domain)
        return if domain.nil?
        KeyValueStore::set("/Users/pascal/Galaxy/DataBank/Catalyst/Domains/KV-Store", id, domain)
        
        # We write the domain alongside the Nx50s for faster ns16 generation (we have a large dataset at the moment)
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "update _items_ set _domain_=? where _uuid_=?", [domain, id]
        db.commit 
        db.close
    end

    # Domains::getDomainForItemOrNull(id)
    def self.getDomainForItemOrNull(id)
        domain = KeyValueStore::getOrNull("/Users/pascal/Galaxy/DataBank/Catalyst/Domains/KV-Store", id)
        return nil if domain.nil?
        return nil if !Domains::domains().include?(domain)
        domain
    end

    # Domains::interactivelyGetDomainForItemOrNull(id, description)
    def self.interactivelyGetDomainForItemOrNull(id, description)
        domain = Domains::getDomainForItemOrNull(id)
        return domain if domain
        domain = Domains::interactivelySelectDomainOrNull()
        if domain then
            Domains::setDomainForItem(id, domain)
        end
        domain
    end
end
