# encoding: UTF-8

class BankAccountDoneForToday

    # The `thing` that is set `group done for today` is a bank account
    # The drives the Ax39's `should show`

    # BankAccountDoneForToday::setDoneToday(bankaccount)
    def self.setDoneToday(bankaccount)
        XCache::setFlag("5076cc18-5d74-44f6-a6f9-f6f656b7aac4:#{CommonUtils::today()}:#{bankaccount}", true)
        SystemEvents::broadcast({
          "mikuType"    => "bank-account-done-today",
          "bankaccount" => bankaccount,
          "targetdate"  => CommonUtils::today(),
        })
    end

    # BankAccountDoneForToday::setUnDoneToday(bankaccount)
    def self.setUnDoneToday(bankaccount)
        XCache::setFlag("5076cc18-5d74-44f6-a6f9-f6f656b7aac4:#{CommonUtils::today()}:#{bankaccount}", false)
        SystemEvents::broadcast({
          "mikuType"    => "bank-account-set-un-done-today",
          "bankaccount" => bankaccount,
          "targetdate"  => CommonUtils::today(),
        })
    end

    # BankAccountDoneForToday::isDoneToday(bankaccount)
    def self.isDoneToday(bankaccount)
        XCache::getFlag("5076cc18-5d74-44f6-a6f9-f6f656b7aac4:#{CommonUtils::today()}:#{bankaccount}")
    end

    # BankAccountDoneForToday::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "bank-account-done-today" then
            XCache::setFlag("5076cc18-5d74-44f6-a6f9-f6f656b7aac4:#{event["targetdate"]}:#{event["bankaccount"]}", true)
            return
        end
        if event["mikuType"] == "bank-account-set-un-done-today" then
            XCache::setFlag("5076cc18-5d74-44f6-a6f9-f6f656b7aac4:#{event["targetdate"]}:#{event["bankaccount"]}", false)
            return
        end
    end
end
