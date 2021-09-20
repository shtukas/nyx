# encoding: UTF-8

class Domains

    # Domains::items()
    def self.items()
        [
            {
                "filepath"    => "/Users/pascal/Desktop/Eva.txt",
                "domain"      => "eva",
                "bankaccount" => "EVA-60ACA3A8-E1DB-4029-BE95-5ACBFF10316D",
            },
            {
                "filepath"    => "/Users/pascal/Desktop/Work.txt",
                "domain"      => "work",
                "bankaccount" => nil, # The entire domain is managed by one NxBall, unlike Eva, where elements create their own NxBalls
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

    # Domains::domainBankAccountOrNull(domain)
    def self.domainBankAccountOrNull(domain)
        return nil if domain.nil?
        item = Domains::items().select{|item| item["domain"] == domain}.first
        return nil if item.nil?
        item["bankaccount"]
    end

    # Domains::setDomainForItem(id, domain)
    def self.setDomainForItem(id, domain)
        return if domain.nil?
        KeyValueStore::set("/Users/pascal/Galaxy/DataBank/Catalyst/Domains/KV-Store", id, domain)
        Nx50s::setItemDomain(id, domain) # We write the domain alongside the Nx50s for faster ns16 generation (we have a large dataset at the moment)
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
