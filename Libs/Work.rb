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

    # Work::workMenuCommands()
    def self.workMenuCommands()
        "(rt: #{BankExtended::stdRecoveredDailyTimeInHours(Work::bankaccount()).round(2)}) work on | work off"
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

    # Work::runFolder(folderpath)
    def self.runFolder(folderpath)
        uuid = "7b25dff2-b19d-4779-9721-d037d06135a5:#{folderpath}"
        nxball = NxBalls::makeNxBall([uuid])
        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end
            }
        }
        system("clear")
        puts "[work] (fldr) #{File.basename(folderpath)}".green
        system("open '#{folderpath}'")
        LucilleCore::pressEnterToContinue("Press [enter] to exit folder visit")
        thr.exit
        NxBalls::closeNxBall(nxball, true)
    end

    # Work::interestFoldersNS16s(domain)
    def self.interestFoldersNS16s(domain)

        return [] if domain != "(work)" 

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
                uuid = "7b25dff2-b19d-4779-9721-d037d06135a5:#{folderpath}"
                rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
                announce = "[fldr] (#{"%4.2f" % rt}) #{File.basename(folderpath)}".gsub("(0.00)", "      ")
                {
                    "uuid"         => uuid,
                    "announce"     => announce,
                    "commands"     => [],
                    "run"          => lambda{ Work::runFolder(folderpath) },
                    "interpreter"  => nil,
                    "unixtime-bd06fbf9" => getFolderUnixtime.call(folderpath)
                }
            }
            .sort{|q1, q2| q1["unixtime-bd06fbf9"] <=> q2["unixtime-bd06fbf9"] }
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
