
# encoding: UTF-8

# -----------------------------------------------------------------------

class Work

    # ---------------------------------------------------------------------------

    # Work::getStartUnixtimeOrNull()
    def self.getStartUnixtimeOrNull()
        # This indicates whether the item is running or not
        unixtime = KeyValueStore::getOrNull(nil, "0f4bd119-714d-442a-bf23-1e29b92e8c1b")
        return nil if unixtime.nil?
        unixtime.to_f
    end

    # Work::isRunning()
    def self.isRunning()
        !Work::getStartUnixtimeOrNull().nil?
    end

    # Work::start()
    def self.start()
        return if Work::isRunning()
        KeyValueStore::set(nil, "0f4bd119-714d-442a-bf23-1e29b92e8c1b", Time.new.to_i)
    end

    # Work::stop()
    def self.stop()
        return if !Work::isRunning()
        timespan = [Time.new.to_i - Work::getStartUnixtimeOrNull(), 3600*2].min
        puts "Adding #{timespan} seconds to Work ( WORK-E4A9-4BCD-9824-1EEC4D648408 )"
        Bank::put("WORK-E4A9-4BCD-9824-1EEC4D648408", timespan)
        KeyValueStore::destroy(nil, "0f4bd119-714d-442a-bf23-1e29b92e8c1b")
    end

    # Work::runningString()
    def self.runningString()
        return "" if !Work::isRunning()
        value = (Time.new.to_i - Work::getStartUnixtimeOrNull()).to_f/3600
        "(running for #{value.round(2)}) hours"
    end

    # ---------------------------------------------------------------------------

    # Work::targetRT()
    def self.targetRT()
        6
    end

    # Work::workIsRunningOrShouldBe()
    def self.workIsRunningOrShouldBe()
        return true if Work::isRunning()
        return false if !DoNotShowUntil::isVisible("WORK-E4A9-4BCD-9824-1EEC4D648408")
        return false if (BankExtended::stdRecoveredDailyTimeInHours("WORK-E4A9-4BCD-9824-1EEC4D648408") > Work::targetRT())
        return false if [0, 6].include?(Time.new.wday)
        return false if Time.new.hour < 9
        return false if Time.new.hour >= 17
        true
    end

    # Work::formatPriorityFile(text)
    def self.formatPriorityFile(text)
        text.lines.first(5).map{|line| "        #{line}" }.join()
    end

    # ---------------------------------------------------------------------------

    # Work::announce()
    def self.announce()
        uuid = "WORK-E4A9-4BCD-9824-1EEC4D648408"
        if Work::isRunning() then
            "[#{"work".green}] (rt: #{"%4.2f" % BankExtended::stdRecoveredDailyTimeInHours(uuid)}) #{Work::runningString()} 👩🏻‍💻"
        else
            "[work] (rt: #{"%4.2f" % BankExtended::stdRecoveredDailyTimeInHours(uuid)}) 👩🏻‍💻"
        end
    end

    # Work::ns16s()
    def self.ns16s()
        return [] if !Work::workIsRunningOrShouldBe()
        uuid = "WORK-E4A9-4BCD-9824-1EEC4D648408"
        [
            {
                "uuid"     => uuid,
                "announce" => Work::announce(),
                "access"   => lambda { 
                    Work::isRunning() ? Work::stop() : Work::start()
                },
                "done"     => lambda {
                    Work::stop()
                },
                "domain"    => Domains::workDomain(),
                "isRunning" => Work::isRunning()
            }
        ]
    end

    # Work::nx19s()
    def self.nx19s()
        [
            {
                "announce" => "work",
                "lambda"   => lambda { Work::isRunning() ? Work::stop() : Work::start() }
            }
        ]
    end
end


Thread.new {
    loop {
        sleep 120
        next if !Work::isRunning()
        if (Time.new.to_f - Work::getStartUnixtimeOrNull()) > 3600 then
            Utils::onScreenNotification("Catalyst", "work overrunning")
        end
    }
}
