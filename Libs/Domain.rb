
# encoding: UTF-8

class Domain

    # Domain::setCurrentDomain(domain)
    def self.setCurrentDomain(domain)
        KeyValueStore::set(nil, "6992dae8-5b15-4266-a2c2-920358fda283", domain)
    end

    # Domain::getCurrentDomain(domain)
    def self.getCurrentDomain(domain)
        KeyValueStore::getOrNull(nil, "6992dae8-5b15-4266-a2c2-920358fda283") || "(eva)"
    end

    # Domain::interactivelySelectDomain()
    def self.interactivelySelectDomain()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", ["(eva)", "(work)"]) || "(eva)"
    end

    # Domain::domainsMenuCommands()
    def self.domainsMenuCommands()
        "eva | work (rt: #{Work::recoveryTime().round(2)}) (Nx50s: #{Nx50s::nx50s().count} items)"
    end

    # Domain::domainsCommandInterpreter(command)
    def self.domainsCommandInterpreter(command)
        if command == "work" then
            Domain::setCurrentDomain("(work)")
            Work::issueNxBallIfNotOne()
        end
        if command == "eva" then
            Work::closeNxBallIfOne()
            Domain::setCurrentDomain("(eva)")
        end
    end
end