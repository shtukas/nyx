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

    # Work::isInTimeInterval(x, n1, n2)
    def self.isInTimeInterval(x, n1, n2)
        (x >= n1) and (x < n2)
    end

    # Work::isWorkMode()
    def self.isWorkMode()

        isInTimeInterval = lambda{|x, n1, n2|
            (x >= n1) and (x < n2)
        }

        # First check whether there is an explicit Yes override.
        return true if KeyValueStore::flagIsTrue(nil, "5749f425-f3d1-4bdc-9605-cda59eee09cd")

        # Check whether there is a timed No override
        noWorkUntilUnixtime = KeyValueStore::getOrDefaultValue(nil, "a0ab6691-feaf-44f6-8093-800d921ab6a7", "0").to_f
        return false if Time.new.to_i < noWorkUntilUnixtime

        # Standard work hours
        return false if [0, 6].include?(Time.new.wday)
        isInTimeInterval.call(Time.new.hour, 8, 12) or isInTimeInterval.call(Time.new.hour, 14, 17)
    end

    # Work::workMenuCommands()
    def self.workMenuCommands()
        "[work   ] set directives | set ordinals | work on | work off | work off until"
    end

    # Work::workMenuInterpreter(command)
    def self.workMenuInterpreter(command)
        if Interpreting::match("set directives", command) then
            loop {
                nx51 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx51", Nx51s::nx51sPerOrdinal(), lambda{|nx51| Nx51s::toString(nx51) })
                break if nx51.nil?
                directive = Nx51RunDirectives::interactivelyBuildDirectiveOrNull()
                next if directive.nil?
                Nx51RunDirectives::setDirective(nx51["uuid"], directive)
            }
            return
        end
        if Interpreting::match("set ordinals", command) then
            loop {
                nx51 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx51", Nx51s::nx51sPerOrdinal(), lambda{|nx51| Nx51s::toString(nx51) })
                break if nx51.nil?
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                nx51["ordinal"] = ordinal
                Nx51s::commitNx51ToDisk(nx51)
            }
            return
        end
        if command == "work on" then
            KeyValueStore::setFlagTrue(nil, "5749f425-f3d1-4bdc-9605-cda59eee09cd")
            return
        end
        if command == "work off" then
            KeyValueStore::setFlagFalse(nil, "5749f425-f3d1-4bdc-9605-cda59eee09cd")
            return
        end
        if command == "work off until" then
            n = LucilleCore::askQuestionAnswerAsString("pause in hours: ").to_f
            KeyValueStore::set(nil, "a0ab6691-feaf-44f6-8093-800d921ab6a7", Time.new.to_i + n*3600)
            return
        end
    end
end
