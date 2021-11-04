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

    # Work::isActive()
    def self.isActive()
        Domain::getActiveDomain() == "(work)"
    end

    # Work::ns16s()
    def self.ns16s()
        if !Work::isActive() and Work::recoveryTime() < 4 then
            return [
                {
                    "uuid"        => "76121744-af0d-499d-8724-fd7e2ecd7d0c",
                    "announce"    => "Should be working 🧑🏻‍💻",
                    "commands"    => [],
                    "run"         => lambda {
                        Domain::setActiveDomain("(work)")
                    }
                }
            ]
        end
        if Work::isActive() and Work::recoveryTime() > 5 then
            return [
                {
                    "uuid"        => "76121744-af0d-499d-8724-fd7e2ecd7d0c",
                    "announce"    => "Should be (eva)ing 👩",
                    "commands"    => [],
                    "run"         => lambda {
                        Domain::setActiveDomain("(eva)")
                    }
                }
            ]
        end
        []
    end
end
