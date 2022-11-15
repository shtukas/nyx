
class TxTimePromise

    # TxTimePromise::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return nil if cx22.nil?
        amount = LucilleCore::askQuestionAnswerAsString("amount (in minutes): ").to_f
        amount = amount * 60
        item = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "TxTimePromise",
            "unixtime" => Time.new.to_f,
            "datetime" => Time.new.utc.iso8601,
            "cx22"     => cx22,
            "amount"   => amount
        }
        # We no need to issue that time, we will issue anegative amount when the item is being closed.
        puts "Issuing promise, adding #{item["amount"]} seconds to '#{item["cx22"]["description"]}'"
        Bank::put(item["cx22"]["description"], -item["amount"])
        item 
    end

    # TxTimePromise::toString(item)
    def self.toString(item)
        "(promise: #{(item["amount"].to_f/3600).round(2)} hours, for #{item["cx22"]["description"]})"
    end

    # TxTimePromise::closePromise(item)
    def self.closePromise(item)
        puts "Closing promise, removing #{item["amount"]} seconds from '#{item["cx22"]["description"]}'"
        Bank::put(item["cx22"]["description"], -item["amount"])
    end
end
