
# encoding: UTF-8


class DomainsX

    # DomainsX::interactivelySelectDomainX()
    def self.interactivelySelectDomainX()
        domainx = LucilleCore::selectEntityFromListOfEntitiesOrNull("domainx", ["eva", "work"])
        return "eva" if domainx.nil?
        domainx
    end

    # DomainsX::setOverridingFocus(domainx)
    def self.setOverridingFocus(domainx)
        KeyValueStore::set(nil, "c68fc8de-81fd-4e76-b995-e171d0374661:#{Utils::today()}", domainx)
    end

    # DomainsX::unsetOverridingFocus()
    def self.unsetOverridingFocus()
        KeyValueStore::destroy(nil, "c68fc8de-81fd-4e76-b995-e171d0374661:#{Utils::today()}")
    end

    # DomainsX::overridingFocusOrNull()
    def self.overridingFocusOrNull()
        KeyValueStore::getOrNull(nil, "c68fc8de-81fd-4e76-b995-e171d0374661:#{Utils::today()}")
    end

    # DomainsX::focus()
    def self.focus()
        "eva"
    end
end
