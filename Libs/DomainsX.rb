
# encoding: UTF-8


class DomainsX

    # DomainsX::evaAccount()
    def self.evaAccount()
        "A68BB27C-22D5-4253-A369-E6624982132E"
    end

    # DomainsX::workAccount()
    def self.workAccount()
        "BA9DBC71-8CFE-4C15-BF47-2D0C46C4C6CD"
    end

    # DomainsX::interactivelySelectDomainX()
    def self.interactivelySelectDomainX()
        domainx = LucilleCore::selectEntityFromListOfEntitiesOrNull("domainx", ["eva", "work"])
        return "eva" if domainx.nil?
        domainx
    end

    # DomainsX::domainXToAccountNumber(domainsx)
    def self.domainXToAccountNumber(domainsx)
        if domainsx == "eva" then
            return DomainsX::evaAccount()
        end
        if domainsx == "work" then
            return DomainsX::workAccount()
        end
        raise "[error: 49e106f2-12c5-45e0-9048-956b5d74b186]"
    end

    # DomainsX::selectAccountOrNull()
    def self.selectAccountOrNull()
        account = LucilleCore::selectEntityFromListOfEntitiesOrNull("domainx", ["eva", "work"])
        return nil if account.nil?
        if account == "eva" then
            return DomainsX::evaAccount()
        end
        if account == "work" then
            return DomainsX::workAccount()
        end
        raise "[error: CF7BFD8D-73AB-4DC7-AB75-4C0AECFA05B4]"
    end

    # DomainsX::selectAccount()
    def self.selectAccount()
        account = DomainsX::selectAccountOrNull()
        if account then
            account 
        else
            DomainsX::selectAccount()
        end
    end

    # DomainsX::dominant()
    def self.dominant()
        [
            {
                "name"    => "eva",
                "account" => DomainsX::evaAccount()
            },
            {
                "name"    => "work",
                "account" => DomainsX::workAccount()
            }
        ]
            .sort{|p1, p2| BankExtended::stdRecoveredDailyTimeInHours(p1["account"]) <=> BankExtended::stdRecoveredDailyTimeInHours(p2["account"]) }
            .first["name"]
    end

    # DomainsX::dx()
    def self.dx()
        [ ["eva", DomainsX::evaAccount()], ["work", DomainsX::workAccount()] ]
            .map{|pair|
                n, a = pair
                "(#{n}: #{(Bank::valueAtDate(a, Utils::today()).to_f/3600).round(2)} hours, rt: #{BankExtended::stdRecoveredDailyTimeInHours(a).round(2)})"
            }
            .join(" ")
    end
end
