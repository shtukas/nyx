# encoding: UTF-8

=begin

{
    "uuid"         => String
    "unixtime"     => Float
    "description"  => String
    "catalystType" => "Nx31"

    "payload1" : "YYYY-MM-DD"
    "payload2" :
    "payload3" :

    "date" : payload1
}

=end

class Work

    # Work::bankaccount()
    def self.bankaccount()
        "WORK-E4A9-4BCD-9824-1EEC4D648408"
    end

    # Work::recoveryTime()
    def self.recoveryTime()
        BankExtended::stdRecoveredDailyTimeInHours(Work::bankaccount())
    end

    # Work::issueRunningItem()
    def self.issueRunningItem()
        DetachedRunning::issueNew2("(work)", Time.new.to_i, [Work::bankaccount()])
    end
end
