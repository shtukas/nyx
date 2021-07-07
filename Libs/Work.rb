
# encoding: UTF-8

# -----------------------------------------------------------------------

class Work

    # ---------------------------------------------------------------------------

    # Work::start()
    def self.start()
        KeyValueStore::set(nil, "0f4bd119-714d-442a-bf23-1e29b92e8c1b", Time.new.to_i)
    end

    # Work::stop()
    def self.stop()
        KeyValueStore::destroy(nil, "0f4bd119-714d-442a-bf23-1e29b92e8c1b")
    end

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

    # ---------------------------------------------------------------------------

    # Work::isWorkTime()
    def self.isWorkTime()
        b1 = (8 <= Time.new.hour  and Time.new.hour < 17)
        b2 = [1,2,3,4,5].include?(Time.new.wday)
        b1 and b2
    end

    # Work::citcuitBreaker()
    def self.citcuitBreaker()
        Bank::valueOverTimespan("WORK-E4A9-4BCD-9824-1EEC4D648408", 3600*4) > 3600*3
    end

    # Work::shouldDisplayWork()
    def self.shouldDisplayWork()
        return false if (KeyValueStore::getOrNull(nil, "ce621184-51d7-456a-8ad1-20e7d9acb350:#{Utils::today()}") == "ns:false")
        return false if !DoNotShowUntil::isVisible("WORK-E4A9-4BCD-9824-1EEC4D648408")
        return false if Work::citcuitBreaker()
        Work::isWorkTime()
    end

    # Work::addLeftPadding(text)
    def self.addLeftPadding(text)
        text.lines.map{|line| "        #{line}" }.join()
    end

    # ---------------------------------------------------------------------------

    # Work::announce()
    def self.announce()
        uuid = "WORK-E4A9-4BCD-9824-1EEC4D648408"
        if Work::isRunning() then
            [
                "[#{"work".green}] (rt: #{"%4.2f" % BankExtended::stdRecoveredDailyTimeInHours(uuid)}) (running) 👩🏻‍💻",
                "\n",
                Work::addLeftPadding(IO.read("/Users/pascal/Desktop/Priority Work.txt")).green
            ].join()
        else
            "[work] (rt: #{"%4.2f" % BankExtended::stdRecoveredDailyTimeInHours(uuid)}) 👩🏻‍💻"
        end
    end

    # Work::ns16s()
    def self.ns16s()
        return [] if !Work::shouldDisplayWork()
        uuid = "WORK-E4A9-4BCD-9824-1EEC4D648408"
        [
            {
                "uuid"     => uuid,
                "announce" => Work::announce(),
                "access"   => lambda { 
                    if !Work::isRunning() then
                        Work::start()
                    end
                },
                "done"     => lambda {
                    if Work::isRunning() then
                        startUnixtime = Work::getStartUnixtimeOrNull()
                        timespan = [Time.new.to_i - startUnixtime, 3600*2].min
                        puts "Adding #{timespan} seconds to Work ( WORK-E4A9-4BCD-9824-1EEC4D648408 )"
                        Bank::put("WORK-E4A9-4BCD-9824-1EEC4D648408", timespan)
                        Work::stop()
                    end
                }
            }
        ]
    end
end
