# encoding: UTF-8

class GuardianOpenCycles

    # We provide
    #    1. A Catalyst object driven by a bank recovering value.
    #    2. A dedicated command line tool.
    #    3. Specific manipulations for on disk mirroring.

    # GuardianOpenCycles::uuid()
    def self.uuid()
        "5c4e1873-d511-474d-8562-073c0f08b536"
    end

    # GuardianOpenCycles::targetTimeInHours()
    def self.targetTimeInHours()
        7
    end

    # GuardianOpenCycles::metric()
    def self.metric()
        uuid = GuardianOpenCycles::uuid()
        return 1 if Runner::isRunning?(uuid)
        recoveredTimeInHours = BankExtended::recoveredDailyTimeInHours(uuid)
        (recoveredTimeInHours < GuardianOpenCycles::targetTimeInHours()) ? 0.70 : 0
    end

    # GuardianOpenCycles::start()
    def self.start()
        Runner::start(GuardianOpenCycles::uuid())
    end

    # GuardianOpenCycles::stop()
    def self.stop()
        timespanInSeconds =  Runner::stop(GuardianOpenCycles::uuid())
        return if timespanInSeconds.nil?
        Bank::put(GuardianOpenCycles::uuid(), timespanInSeconds)
    end

    # GuardianOpenCycles::toString()
    def self.toString()
        uuid = GuardianOpenCycles::uuid()
        ratio = BankExtended::recoveredDailyTimeInHours(GuardianOpenCycles::uuid()).to_f/GuardianOpenCycles::targetTimeInHours()
        runningFor = Runner::isRunning?(uuid) ? " (running for #{((Runner::runTimeInSecondsOrNull(uuid) || 0).to_f/60).round(2)} mins)" : ""
        "Guardian Work (#{"%.2f" % (100*ratio)} %)#{runningFor}"
    end

    # GuardianOpenCycles::catalystObjects()
    def self.catalystObjects()
        uuid = GuardianOpenCycles::uuid()
        object = {
            "uuid"             => uuid,
            "body"             => GuardianOpenCycles::toString(),
            "metric"           => GuardianOpenCycles::metric(),
            "execute"          => lambda { |command| GuardianOpenCycles::program(command) },
            "isRunning"        => Runner::isRunning?(uuid),
            "isRunningForLong" => (Runner::runTimeInSecondsOrNull(uuid) || 0) > 3600
        }
        [ object ]
    end

    # GuardianOpenCycles::program(command)
    def self.program(command)
        if command == "c2c799b1-bcb9-4963-98d5-494a5a76e2e6" then
            uuid = GuardianOpenCycles::uuid()
            Runner::isRunning?(uuid) ? GuardianOpenCycles::stop() : GuardianOpenCycles::start()
            return
        end
        cube = NyxObjects2::getOrNull("0a9ef4e7c31439c9e66a324c75f7beb2")
        Cubes::cubeLanding(cube)
    end
end
