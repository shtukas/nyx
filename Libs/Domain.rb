
# encoding: UTF-8

class Domain

    # Domain::domains()
    def self.domains()
        ["(eva)", "(work)", "(jedi)"]
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

        compete = lambda{|domains|
            domains
                .map{|domain|
                    account = Domain::domainToBankAccount(domain)
                    {
                        "domain" => domain,
                        "value"  => Bank::valueAtDate(account, Utils::today())
                    }
                }
                .sort{|i1, i2|
                    i1["value"] <=> i2["value"]
                }
                .first["domain"]
        }

        if Time.new.wday == 6 then
            return compete.call(["(eva)", "(jedi)"])
        end

        if Time.new.wday == 0 then
            return compete.call(["(eva)", "(jedi)"])
        end

        if Time.new.hour >= 9 and Time.new.hour < 17 then
            return "(work)"
        end
        
        "(eva)"
    end

    # Domain::domainToBankAccount(domain)
    def self.domainToBankAccount(domain)
        mapping = {
            "(eva)"  => "EVA-97F7F3341-4CD1-8B20-4A2466751408",
            "(work)" => "WORK-E4A9-4BCD-9824-1EEC4D648408",
            "(jedi)" => "C87787F9-77E9-4518-BC41-DBCFB7775299",
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
        Domain::domains()
            .map{|domain|
                {
                    "domain" => domain,
                    "rt" => BankExtended::stdRecoveredDailyTimeInHours(Domain::domainToBankAccount(domain))
                }
            }
            .sort{|p1, p2| p1["rt"]<=>p2["rt"] }
            .map{|px|
                domain = px["domain"].gsub("(", "").gsub(")", "")
                rt = px["rt"]
                "(#{domain}: rt: #{rt.round(2)})"
            }
            .join(" ")
    end
end
