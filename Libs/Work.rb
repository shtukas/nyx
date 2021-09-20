# encoding: UTF-8

class Work

    # Work::bankaccount()
    def self.bankaccount()
        "WORK-E4A9-4BCD-9824-1EEC4D648408"
    end

    # Work::recoveryTime()
    def self.recoveryTime()
        BankExtended::stdRecoveredDailyTimeInHours(Work::bankaccount())
    end

    # Work::shouldDisplayWorkItems()
    def self.shouldDisplayWorkItems()
        # First check whether there is an explicit Yes (timed) override.
        doWorkUntilUnixtime = KeyValueStore::getOrDefaultValue(nil, "workon-f3d1-4bdc-9605-cda59eee09cd", "0").to_f
        return true if Time.new.to_i < doWorkUntilUnixtime

        # Check whether there is an explicit No (timed) override
        noWorkUntilUnixtime = KeyValueStore::getOrDefaultValue(nil, "workoff-feaf-44f6-8093-800d921ab6a7", "0").to_f
        return false if Time.new.to_i < noWorkUntilUnixtime

        return false if ![1, 2, 3, 4, 5].include?(Time.new.wday)

        return false if Time.new.hour < 9

        BankExtended::stdRecoveredDailyTimeInHours(Work::bankaccount()) < 6
    end

    # Work::workMenuCommands()
    def self.workMenuCommands()
        "[work   ] start work item | work on until | work off until"
    end

    # Work::workMenuInterpreter(command)
    def self.workMenuInterpreter(command)
        if command == "start work item" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            startUnixtime = Time.new.to_i
            bankAccounts = [Work::bankaccount()]
            DetachedRunning::issueNew2(description, startUnixtime, bankAccounts)
            return
        end
        if command == "work on until" then
            n = LucilleCore::askQuestionAnswerAsString("duration in hours: ").to_f
            KeyValueStore::set(nil, "workon-f3d1-4bdc-9605-cda59eee09cd", Time.new.to_i + n*3600)
            KeyValueStore::destroy(nil, "workoff-feaf-44f6-8093-800d921ab6a7")
            return
        end
        if command == "work off until" then
            n = LucilleCore::askQuestionAnswerAsString("pause in hours: ").to_f
            KeyValueStore::set(nil, "workoff-feaf-44f6-8093-800d921ab6a7", Time.new.to_i + n*3600)
            KeyValueStore::destroy(nil, "workon-f3d1-4bdc-9605-cda59eee09cd")
            return
        end
    end
end
