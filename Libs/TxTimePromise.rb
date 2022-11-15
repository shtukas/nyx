class TxTimePromise

    # TxTimePromise::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return nil if cx22.nil?
        amount = LucilleCore::askQuestionAnswerAsString("amount (in minutes): ").to_f
        amount = amount * 60
        {
            "uuid"      => SecureRandom.uuid,
            "mikuType"  => "TxTimePromise",
            "unixtime"  => Time.new.to_f,
            "datetime"  => Time.new.utc.iso8601,
            "cx22"      => cx22,
            "amount"    => amount
        }
    end

    # TxTimePromise::toString(item)
    def self.toString(item)
        "(promise: #{item["amount"].to_f/3600} hours, for #{item["cx22"]["description"]})"
    end
end
