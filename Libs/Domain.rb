
# encoding: UTF-8

# Domains          : "(eva)" | "(work)"

class Domain

    # Domain::setStoredDomain(domain)
    def self.setStoredDomain(domain)
        KeyValueStore::set(nil, "6992dae8-5b15-4266-a2c2-920358fda284", JSON.generate([Time.new.to_i, domain]))
    end

    # Domain::getStoredDomainOrNull()
    def self.getStoredDomainOrNull()
        KeyValueStore::getOrNull(nil, "6992dae8-5b15-4266-a2c2-920358fda284")
    end

    # Domain::getProgramaticDomain()
    def self.getProgramaticDomain()
        if [6, 0].include?(Time.new.wday) then
            return "(eva)"
        end
        if Time.new.hour >= 9 and Time.new.hour < 17 then
            return "(work)"
        end
        "(eva)"
    end

    # Domain::getDomain()
    def self.getDomain()
        i = Domain::getStoredDomainOrNull()
        if i then
            i = JSON.parse(i)
            if (Time.new.to_i - i[0]) < 7200 then
                return i[1]
            end
        end
        Domain::getProgramaticDomain()
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
        count1 = Nx50s::nx50s().select{|item| item["domain"] == "(eva)" }.count
        count2 = Nx50s::nx50s().select{|item| item["domain"] == "(work)" }.count
        today = Time.new.to_s[0, 10]
        h1 = Bank::valueAtDate("EVA-97F7F3341-4CD1-8B20-4A2466751408", today).to_f/3600
        h2 = Bank::valueAtDate("WORK-E4A9-4BCD-9824-1EEC4D648408", today).to_f/3600
        rt1 = BankExtended::stdRecoveredDailyTimeInHours("EVA-97F7F3341-4CD1-8B20-4A2466751408")
        rt2 = Work::recoveryTime()
        [
            "(Nx50: done: #{Nx50DoneCounter::rate()}/day)",
            "(eva: Nx50s: #{count1} items, #{h1.round(2)} hours today, rt: #{rt1.round(2)})",
            "(work: Nx50s: #{count2} items, #{h2.round(2)} hours today, rt: #{rt2.round(2)})"
        ]
            .join(" ")
    end

    # Domain::domainsCommandInterpreter(command)
    def self.domainsCommandInterpreter(command)
        if command == "eva" then
            Domain::setStoredDomain("(eva)")
        end
        if command == "work" then
            Domain::setStoredDomain("(work)")
        end
    end


end