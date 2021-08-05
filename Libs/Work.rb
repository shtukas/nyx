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

    # Work::isInTimeInterval(x, n1, n2)
    def self.isInTimeInterval(x, n1, n2)
        (x >= n1) and (x < n2)
    end

    # Work::shouldBeWorking()
    def self.shouldBeWorking()

        isInTimeInterval = lambda{|x, n1, n2|
            (x >= n1) and (x < n2)
        }

        noWorkUntilUnixtime = KeyValueStore::getOrDefaultValue(nil, "a0ab6691-feaf-44f6-8093-800d921ab6a7", "0").to_f
        return false if Time.new.to_i < noWorkUntilUnixtime

        return false if [0, 6].include?(Time.new.wday)
        isInTimeInterval.call(Time.new.hour, 8, 12) or isInTimeInterval.call(Time.new.hour, 14, 17)
    end
end
