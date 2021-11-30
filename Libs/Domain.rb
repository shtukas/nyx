
# encoding: UTF-8

class Domain

    # Domain::domains()
    def self.domains()
        ["(eva)", "(work)", "(jedi)", "(entertainment)"]
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

    # Domain::getStoredDomainOrNull()
    def self.getStoredDomainOrNull()
        packet = Domain::getStoredDomainWithExpiryOrNull()
        return nil if packet.nil?
        packet = JSON.parse(packet)
        return nil if Time.new.to_i > packet["expiry"]
        packet["domain"]
    end

    # Domain::expectation(domain)
    def self.expectation(domain)
        map = {
            "(eva)"           => 1,
            "(work)"          => 6,
            "(jedi)"          => 2,
            "(entertainment)" => 1
        }
        map[domain]
    end

    # Domain::getProgrammaticDomain()
    def self.getProgrammaticDomain()
        (lambda{
            return ["(eva)", "(jedi)", "(entertainment)"] if Time.new.wday == 6
            return ["(eva)", "(jedi)", "(entertainment)"] if Time.new.wday == 0
            Domain::domains()
        }).call()
            .map {|domain|
                {
                    "domain" => domain,
                    "ratio"  => BankExtended::stdRecoveredDailyTimeInHours(Domain::domainToBankAccount(domain)).to_f/Domain::expectation(domain)
                }
            }
            .sort{|p1, p2|
                p1["ratio"] <=> p2["ratio"]
            }
            .first["domain"]
    end

    # Domain::getDomainForListing()
    def self.getDomainForListing()
        domain = Domain::getStoredDomainOrNull()
        return domain if !domain.nil?
        Domain::getProgrammaticDomain()
    end

    # Domain::domainToBankAccount(domain)
    def self.domainToBankAccount(domain)
        mapping = {
            "(eva)"           => "EVA-97F7F3341-4CD1-8B20-4A2466751408",
            "(work)"          => "WORK-E4A9-4BCD-9824-1EEC4D648408",
            "(jedi)"          => "C87787F9-77E9-4518-BC41-DBCFB7775299",
            "(entertainment)" => "C00F4D2B-DE5E-41A5-8791-8F486EC05ED7"
        }
        raise "[62e07265-cda5-45e1-9b90-7c88db751a1c: #{domain}]" if !mapping.keys.include?(domain)
        mapping[domain]
    end

    # Domain::interactivelySelectDomain()
    def self.interactivelySelectDomain()
        domain = LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", Domain::domains())
        if !domain.nil? then
            return domain
        end
        Domain::interactivelySelectDomain()
    end

    # Domain::interactivelySelectDomainOrNull()
    def self.interactivelySelectDomainOrNull()
        entity = LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", Domain::domains() + ["(null) # default"])
        if entity == "(null) # default" then
            return nil
        end
        entity
    end

    # Domain::dx()
    def self.dx()
        domainToString = lambda{|domain|
            domain.gsub("(", "").gsub(")", "")
        }
        Domain::domains()
            .map{|domain|
                account = Domain::domainToBankAccount(domain)
                {
                    "domain" => domain,
                    "rt"     => BankExtended::stdRecoveredDailyTimeInHours(account),
                    "today"  => Bank::valueAtDate(account, Utils::today()).to_f/3600,
                    "ratio"  => BankExtended::stdRecoveredDailyTimeInHours(Domain::domainToBankAccount(domain)).to_f/Domain::expectation(domain)
                }
            }
            .sort{|p1, p2| p1["ratio"]<=>p2["ratio"] }
            .map{|px|
                "(#{domainToString.call(px["domain"])}: #{(100*px["ratio"]).to_i}% of #{Domain::expectation(px["domain"])} hours)"
            }
            .join(" ")
    end
end
