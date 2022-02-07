
# encoding: UTF-8


class DomainsX

    # DomainsX::interactivelySelectDomainX()
    def self.interactivelySelectDomainX()
        domainx = LucilleCore::selectEntityFromListOfEntitiesOrNull("domainx", ["eva", "work"])
        return "eva" if domainx.nil?
        domainx
    end

    # DomainsX::setOverridingFocus(domainx, expiryTime)
    def self.setOverridingFocus(domainx, expiryTime)
        nx14 = {
            "domainx"    => domainx,
            "expiryTime" => expiryTime
        }
        KeyValueStore::set(nil, "c68fc8de-81fd-4e76-b995-e171d0374661:#{Utils::today()}", JSON.generate(nx14))
    end

    # DomainsX::overridingFocusOrNull()
    def self.overridingFocusOrNull()
        nx14 = KeyValueStore::getOrNull(nil, "c68fc8de-81fd-4e76-b995-e171d0374661:#{Utils::today()}")
        return nil if nx14.nil?
        nx14 = JSON.parse(nx14)
        return nil if (Time.new.to_i > nx14["expiryTime"])
        nx14["domainx"]
    end

    # DomainsX::unsetOverridingFocus()
    def self.unsetOverridingFocus()
        KeyValueStore::destroy(nil, "c68fc8de-81fd-4e76-b995-e171d0374661:#{Utils::today()}")
    end

    # DomainsX::focus()
    def self.focus()
        focus = DomainsX::overridingFocusOrNull()
        return focus if focus
        if [1,2,3,4,5].include?(Time.new.wday) and Time.new.hour >= 9 and Time.new.hour < 16 then
            return "work"
        end
        "eva"
    end
end
