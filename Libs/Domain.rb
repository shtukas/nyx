
# encoding: UTF-8

# Domains          : "(eva)" | "(work)"
# Extended domains : "(eva)" | "(work)" | "(multiplex)"

class Domain

    # Domain::setActiveExtendedDomain(domain)
    def self.setActiveExtendedDomain(domain)
        KeyValueStore::set(nil, "6992dae8-5b15-4266-a2c2-920358fda283", domain)
    end

    # Domain::getActiveExtendedDomain()
    def self.getActiveExtendedDomain()
        KeyValueStore::getOrNull(nil, "6992dae8-5b15-4266-a2c2-920358fda283") || "(multiplex)"
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
            {
                "announce" => "(multiplex: #{Nx50DoneCounter::numbers().map{|n| n.round(2) }.join(", ")})",
                "metric"   => 0,
                "active"   => true
            },
            {
                "announce" => "(eva: Nx50s: #{count1} items, today: #{h1.round(2)} hours, rt: #{rt1.round(2)})",
                "metric"   => h1,
                "active"   => true
            },
            {
                "announce" => "(work: Nx50s: #{count2} items, today: #{h2.round(2)} hours, rt: #{rt2.round(2)})",
                "metric"   => h2,
                "active"   => ![6, 0].include?(Time.new.wday)
            }
        ]
            .select{|i| i["active"] }
            .sort{|i1, i2| i1["metric"]<=>i2["metric"] }
            .map{|i| i["announce"] }
            .join(" ")
    end

    # Domain::domainsCommandInterpreter(command)
    def self.domainsCommandInterpreter(command)
        if command == "multiplex" then
            Domain::setActiveExtendedDomain("(multiplex)")
        end
        if command == "eva" then
            Domain::setActiveExtendedDomain("(eva)")
        end
        if command == "work" then
            Domain::setActiveExtendedDomain("(work)")
        end
    end

    # Domain::getRealDomain()
    def self.getRealDomain()

        if ["(work)", "(eva)"].include?(Domain::getActiveExtendedDomain()) then
            return Domain::getActiveExtendedDomain()
        end

        if [6, 0].include?(Time.new.wday) then
            return "(eva)"
        end

        if Time.new.hour < 8 then
            return "(eva)"
        end
        
        if Time.new.hour >= 20 then
            return "(eva)"
        end

        today = Time.new.to_s[0, 10]

        v1 = Bank::valueAtDate("EVA-97F7F3341-4CD1-8B20-4A2466751408", today)
        v2 = Bank::valueAtDate("WORK-E4A9-4BCD-9824-1EEC4D648408", today)

        v1 > v2 ? "(work)" : "(eva)"
    end
end