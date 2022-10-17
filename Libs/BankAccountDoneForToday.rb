# encoding: UTF-8

class BankAccountDoneForToday

    # The `thing` that is set `group done for today` is a bank account
    # The drives the Ax39's `should show`

    # BankAccountDoneForToday::setDoneToday(bankaccount)
    def self.setDoneToday(bankaccount)
        filepath = "#{Config::pathToDataCenter()}/bank-account-done-today/#{bankaccount}.data"
        File.open(filepath, "w"){|f| f.write(CommonUtils::today()) }
    end

    # BankAccountDoneForToday::setUnDoneToday(bankaccount)
    def self.setUnDoneToday(bankaccount)
        filepath = "#{Config::pathToDataCenter()}/bank-account-done-today/#{bankaccount}.data"
        LucilleCore::removeFileSystemLocation(filepath)
    end

    # BankAccountDoneForToday::isDoneToday(bankaccount)
    def self.isDoneToday(bankaccount)
        filepath = "#{Config::pathToDataCenter()}/bank-account-done-today/#{bankaccount}.data"
        return false if !File.exists?(filepath)
        IO.read(filepath).strip == CommonUtils::today()
    end
end
