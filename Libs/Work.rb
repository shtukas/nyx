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

    # Work::shouldBeActive()
    def self.shouldBeActive()
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
        "[work   ] (rt: #{BankExtended::stdRecoveredDailyTimeInHours(Work::bankaccount()).round(2)}) work on | work off"
    end

    # Work::workMenuInterpreter(command)
    def self.workMenuInterpreter(command)
        if command == "work on" then
            Work::issueNxBallIfNotOne()
        end
        if command == "work off" then
            Work::close()
        end
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

    # Work::close()
    def self.close()
        nxball = Work::getNxBallOrNull()
        return if nxball.nil?
        NxBalls::closeNxBall(nxball, true)
        KeyValueStore::destroy(nil, "89f1ba39-2a3d-4a9b-8eba-2a7a10f713b8")
    end

    # Work::isActive()
    def self.isActive()
        !Work::getNxBallOrNull().nil?
    end

    # Work::presenceNS16()
    def self.presenceNS16()
        if Work::shouldBeActive() and !Work::isActive() then
            [
                {
                    "uuid"        => "b0fbec50-7e53-4176-8c7f-fe7f452c1695:#{Utils::today()}",
                    "announce"    => "[work] run to activate".green,
                    "commands"    => [],
                    "run"         => lambda{ Work::issueNxBallIfNotOne() },
                    "interpreter" => nil
                }
            ]
        else
            []
        end
    end

    # Work::interestFoldersNS16s()
    def self.interestFoldersNS16s()

        getFolderUnixtime = lambda{|folderpath|
            filepath = "#{folderpath}/.unixtime-784971ed"
            if !File.exists?(filepath) then
                File.open(filepath, "w") {|f| f.puts(Time.new.to_f)}
            end
            IO.read(filepath).strip.to_f
        }

        rootfolderpath = Utils::locationByUniqueStringOrNull("8ead151f04")
        return [] if rootfolderpath.nil?
        LucilleCore::locationsAtFolder(rootfolderpath)
            .map{|folderpath|
                {
                    "uuid"        => "7b25dff2-b19d-4779-9721-d037d06135a5:#{folderpath}",
                    "announce"    => "[work] (fldr) #{File.basename(folderpath)}",
                    "commands"    => [],
                    "run"         => lambda{ 
                        system("open '#{folderpath}'")
                    },
                    "interpreter"  => nil,
                    "unixtime-bd06fbf9" => getFolderUnixtime.call(folderpath)
                }
            }
    end

    # Work::ns16s()
    def self.ns16s()
        (Nx51s::ns16s()+Work::interestFoldersNS16s())
            .sort{|o1, o2| o1["unixtime-bd06fbf9"] <=> o2["unixtime-bd06fbf9"] }
    end

    # Work::updateNxBallOrNothing()
    def self.updateNxBallOrNothing()
        nxball = Work::getNxBallOrNull()
        return if nxball.nil?
        nxball = NxBalls::upgradeNxBall(nxball, false)
        KeyValueStore::set(nil, "89f1ba39-2a3d-4a9b-8eba-2a7a10f713b8", JSON.generate(nxball))
    end
end

Thread.new {
    sleep 300
    loop {
        Work::updateNxBallOrNothing()
        sleep 300
    }
}
