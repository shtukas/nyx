
# encoding: UTF-8

# Domains          : "(eva)" | "(work)"

class Domain

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

        if Bank::valueAtDate("WORK-E4A9-4BCD-9824-1EEC4D648408", Utils::today()) < 6*3600 then
            "(work)"
        else
            "(eva)"
        end
    end

    # Domain::getDomainBankAccount(domain)
    def self.getDomainBankAccount(domain)
        mapping = {
            "(eva)"  => "EVA-97F7F3341-4CD1-8B20-4A2466751408",
            "(work)" => Work::bankaccount(),
        }
        raise "[62e07265-cda5-45e1-9b90-7c88db751a1c: #{domain}]" if !mapping.keys.include?(domain)
        mapping[domain]
    end

    # Domain::interactivelySelectDomain()
    def self.interactivelySelectDomain()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", ["(eva)", "(work)"]) || "(eva)"
    end

    # Domain::domainsMenuCommands()
    def self.domainsMenuCommands()
        today = Time.new.to_s[0, 10]
        h1 = Bank::valueAtDate("EVA-97F7F3341-4CD1-8B20-4A2466751408", today).to_f/3600
        h2 = Bank::valueAtDate("WORK-E4A9-4BCD-9824-1EEC4D648408", today).to_f/3600
        [
            "(Nx50: differential (month): #{Bank::valueOverTimespan("8504debe-2445-4361-a892-daecdc58650d", 86400*30)})",
            "(eva: #{h1.round(2)} hours today)",
            "(work: #{h2.round(2)} hours today)"
        ]
            .join(" ")
    end

    # Domain::domainsCommandInterpreter(command)
    def self.domainsCommandInterpreter(command)
        if command == "eva" then
            Domain::setStoredDomainWithExpiry("(eva)", Time.new.to_i + 3600)
        end
        if command == "work" then
            Domain::setStoredDomainWithExpiry("(work)", Time.new.to_i + 3600)
        end
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