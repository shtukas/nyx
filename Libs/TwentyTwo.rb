
# encoding: UTF-8


class TwentyTwo

    # TwentyTwo::evaAccount()
    def self.evaAccount()
        "A68BB27C-22D5-4253-A369-E6624982132E"
    end

    # TwentyTwo::workAccount()
    def self.workAccount()
        "BA9DBC71-8CFE-4C15-BF47-2D0C46C4C6CD"
    end

    # TwentyTwo::selectAccountOrNull()
    def self.selectAccountOrNull()
        account = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["eva", "work"])
        return nil if account.nil?
        if account == "eva" then
            return TwentyTwo::evaAccount()
        end
        if account == "work" then
            return TwentyTwo::workAccount()
        end
        raise "[error: CF7BFD8D-73AB-4DC7-AB75-4C0AECFA05B4]"
    end

    # TwentyTwo::selectAccount()
    def self.selectAccount()
        account = TwentyTwo::selectAccountOrNull()
        if account then
            account 
        else
            TwentyTwo::selectAccount()
        end
    end

    # TwentyTwo::getCachedAccountForObject(announce, uuid)
    def self.getCachedAccountForObject(announce, uuid)
        account = KeyValueStore::getOrNull(nil, "95e82e1b-44b0-4857-abe2-e99048ae4ccd:#{uuid}")
        return account if account
        puts "Deciding account for #{announce}"
        account = TwentyTwo::selectAccount()
        KeyValueStore::set(nil, "95e82e1b-44b0-4857-abe2-e99048ae4ccd:#{uuid}", account)
        account
    end

    # TwentyTwo::dx()
    def self.dx()
        [ ["eva", TwentyTwo::evaAccount()], ["work", TwentyTwo::workAccount()] ]
            .map{|pair|
                n, a = pair
                "(#{n}: #{(Bank::valueAtDate(a, Utils::today()).to_f/3600).round(2)} hours, rt: #{BankExtended::stdRecoveredDailyTimeInHours(a).round(2)})"
            }
            .join(" ")
    end

    # TwentyTwo::ns16s()
    def self.ns16s()
        evaRt = BankExtended::stdRecoveredDailyTimeInHours(TwentyTwo::evaAccount())
        workRt = BankExtended::stdRecoveredDailyTimeInHours(TwentyTwo::workAccount())

        [
            [evaRt, Nx50s::ns16s().first(6)],
            [workRt, Mx51s::ns16s().first(6)]
        ]
            .sort{|a1, a2|
                a1[0] <=> a2[0]
            }
            .map{|a|
                a[1]
            }
            .flatten
    end
end
