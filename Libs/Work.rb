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

    # Work::getNxBallOrNull()
    def self.getNxBallOrNull()
        nxball = KeyValueStore::getOrNull(nil, "89f1ba39-2a3d-4a9b-8eba-2a7a10f713b8")
        return nil if nxball.nil?
        JSON.parse(nxball)
    end

    # Work::issueNxBallIfNotOne()
    def self.issueNxBallIfNotOne()
        return if Work::getNxBallOrNull()
        nxball = NxBalls::makeNxBall([Work::bankaccount()])
        KeyValueStore::set(nil, "89f1ba39-2a3d-4a9b-8eba-2a7a10f713b8", JSON.generate(nxball))
    end

    # Work::closeNxBallIfOne()
    def self.closeNxBallIfOne()
        nxball = Work::getNxBallOrNull()
        return if nxball.nil?
        NxBalls::closeNxBall(nxball, true)
        KeyValueStore::destroy(nil, "89f1ba39-2a3d-4a9b-8eba-2a7a10f713b8")
    end

    # Work::updateNxBallOrNothing()
    def self.updateNxBallOrNothing()
        nxball = Work::getNxBallOrNull()
        return if nxball.nil?
        nxball = NxBalls::upgradeNxBall(nxball, false)
        KeyValueStore::set(nil, "89f1ba39-2a3d-4a9b-8eba-2a7a10f713b8", JSON.generate(nxball))
    end

    # Work::isActive()
    def self.isActive()
        !Work::getNxBallOrNull().nil?
    end

    # Work::ns16s()
    def self.ns16s()
        if Domain::getActiveDomain() == "(eva)" and Work::recoveryTime() < 5 then
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
        if Domain::getActiveDomain() == "(work)" and Work::recoveryTime() > 6 then
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

Thread.new {
    sleep 300
    loop {
        Work::updateNxBallOrNothing()
        sleep 300
    }
}
