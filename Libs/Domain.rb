
# encoding: UTF-8

class Domain

    # Domain::setActiveDomain(domain)
    def self.setActiveDomain(domain)
        KeyValueStore::set(nil, "6992dae8-5b15-4266-a2c2-920358fda283", domain)
    end

    # Domain::getActiveDomain()
    def self.getActiveDomain()
        KeyValueStore::getOrNull(nil, "6992dae8-5b15-4266-a2c2-920358fda283") || "(eva)"
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
        rt1 = BankExtended::stdRecoveredDailyTimeInHours("EVA-97F7F3341-4CD1-8B20-4A2466751408")
        "eva (Nx50s: #{count1} items) (rt: #{rt1.round(2)}) | work (Nx50s: #{count2} items) (rt: #{Work::recoveryTime().round(2)})"
    end

    # Domain::domainsCommandInterpreter(command)
    def self.domainsCommandInterpreter(command)
        if command == "work" then
            Domain::setActiveDomain("(work)")
        end
        if command == "eva" then
            Domain::setActiveDomain("(eva)")
        end
    end
end