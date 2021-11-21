
# encoding: UTF-8

# Domains: "(eva)" | "(work)"

class Domain

    # Domain::domains()
    def self.domains()
        ["(eva)", "(work)"]
    end

    # Domain::setStoredDomainWithExpiry(domain, expiryUnixtime)
    def self.setStoredDomainWithExpiry(domain, expiryUnixtime)
        packet = {
            "domain" => domain,
            "expiry" => expiryUnixtime
        }
        KeyValueStore::set(nil, "6992dae8-5b15-4266-a2c2-920358fda286", JSON.generate(packet))
    end

    # Domain::getStoredDomainWithExpiryOrNull()
    def self.getStoredDomainWithExpiryOrNull()
        KeyValueStore::getOrNull(nil, "6992dae8-5b15-4266-a2c2-920358fda286")
    end

    # Domain::getDomain()
    def self.getDomain()
        packet = Domain::getStoredDomainWithExpiryOrNull()
        if packet then
            packet = JSON.parse(packet)
            if Time.new.to_i < packet["expiry"] then
                return packet["domain"]
            end
        end

        return "(eva)" if (Time.new.wday == 6 or Time.new.wday == 0)

        if Time.new.hour < 12 then
            (Bank::valueAtDate("WORK-E4A9-4BCD-9824-1EEC4D648408", Utils::today()) < 3*3600) ? "(work)" : "eva"
        else
            (Bank::valueAtDate("WORK-E4A9-4BCD-9824-1EEC4D648408", Utils::today()) < 6*3600) ? "(work)" : "eva"
        end
    end

    # Domain::domainToBankAccount(domain)
    def self.domainToBankAccount(domain)
        mapping = {
            "(eva)"  => "EVA-97F7F3341-4CD1-8B20-4A2466751408",
            "(work)" => Work::bankaccount(),
        }
        raise "[62e07265-cda5-45e1-9b90-7c88db751a1c: #{domain}]" if !mapping.keys.include?(domain)
        mapping[domain]
    end

    # Domain::interactivelySelectDomain()
    def self.interactivelySelectDomain()
        domain = LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", ["(eva)", "(work)"])
        if !domain.nil? then
            return domain
        end
        Domain::interactivelySelectDomain()
    end

    # Domain::interactivelySelectDomainOrNull()
    def self.interactivelySelectDomainOrNull()
        entity = LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", ["(eva)", "(work)", "(null) # default"])
        if entity == "(null) # default" then
            return nil
        end
        entity
    end

    # Domain::interactivelySelectOrGetCachedDomain(string)
    def self.interactivelySelectOrGetCachedDomain(string)
        domain = KeyValueStore::getOrNull(nil, "a1808e21-5861-452c-8638-f356c4e9a37f:#{string}")
        return domain if domain
        puts "> select domain for: #{string}"
        domain = Domain::interactivelySelectDomain()
        KeyValueStore::set(nil, "a1808e21-5861-452c-8638-f356c4e9a37f:#{string}", domain)
        domain
    end
end