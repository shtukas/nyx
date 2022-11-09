# encoding: UTF-8

class BankLoan1

    # BankLoan1::commit(item)
    def self.commit(item)
        filepath = "#{Config::pathToDataCenter()}/BankLoan1/#{item["account"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # BankLoan1::borrowThisAmount(accountId, value)
    def self.borrowThisAmount(accountId, value)
        filepath = "#{Config::pathToDataCenter()}/BankLoan1/#{accountId}.json"
        if File.exists?(filepath) then
            item = JSON.parse(IO.read(filepath))
        else
            item = {
                "mikuType" => "BankLoan1",
                "account"  => accountId,
                "borrowed" => 0
            }
        end
        item["borrowed"] = item["borrowed"] + value
        BankLoan1::commit(item)
    end

    # BankLoan1::currentlyOwesMoney?(accountId)
    def self.currentlyOwesMoney?(accountId)
        filepath = "#{Config::pathToDataCenter()}/BankLoan1/#{accountId}.json"
        return false if !File.exists?(filepath)
        item = JSON.parse(IO.read(filepath))
        item["borrowed"] > 0
    end

    # BankLoan1::borrowedAmountOrNull(accountId)
    def self.borrowedAmountOrNull(accountId)
        filepath = "#{Config::pathToDataCenter()}/BankLoan1/#{accountId}.json"
        return nil if !File.exists?(filepath)
        item = JSON.parse(IO.read(filepath))
        item["borrowed"]
    end

    # BankLoan1::reinburseThisAmount(accountId, value)
    def self.reinburseThisAmount(accountId, value)
        filepath = "#{Config::pathToDataCenter()}/BankLoan1/#{accountId}.json"
        if File.exists?(filepath) then
            item = JSON.parse(IO.read(filepath))
        else
            item = {
                "mikuType" => "BankLoan1",
                "account"  => accountId,
                "borrowed" => 0
            }
        end
        item["borrowed"] = item["borrowed"] - value
        BankLoan1::commit(item)
    end

    # BankLoan1::interactiveLoanOfferReturnLoanReceiptOrNull(cx22Opt) # null or {accountId, value}
    def self.interactiveLoanOfferReturnLoanReceiptOrNull(cx22Opt)
        input = LucilleCore::askQuestionAnswerAsString("Time loan ? (Enter value in minutes if yes, empty if not) : ")
        return if input == ""
        value = input.to_f
        value = value * 60 # converting to seconds
        cx22 = cx22Opt ? cx22Opt : Cx22::interactivelySelectCx22OrNull()
        return nil if cx22.nil?
        BankLoan1::borrowThisAmount(cx22["uuid"], value)
        Bank::put_direct_no_loan_accountancy(cx22["uuid"], value)
        {
            "mikuType"    => "LoanReceipt1",
            "accountId"   => cx22["uuid"],
            "accountName" => cx22["description"],
            "amount"      => value
        }
    end
end
