
# encoding: UTF-8

# -----------------------------------------------------------------------

class Work

    # ---------------------------------------------------------------------------

    # Work::getStartUnixtimeOrNull()
    def self.getStartUnixtimeOrNull()
        unixtime = KeyValueStore::getOrNull(nil, "843d19ab-4c64-4186-a455-b09e441e13a7")
        return nil if unixtime.nil?
        unixtime.to_i
    end

    # Work::isRunning()
    def self.isRunning()
        !Work::getStartUnixtimeOrNull().nil?
    end

    # Work::start()
    def self.start()
        return if Work::isRunning()
        KeyValueStore::set(nil, "843d19ab-4c64-4186-a455-b09e441e13a7", Time.new.to_f)
    end

    # Work::stop()
    def self.stop()
        return if !Work::isRunning()
        unixtime = Work::getStartUnixtimeOrNull()
        return if unixtime.nil? # that condition never becomes true after the previous line.
        timespan = [ Time.new.to_f - unixtime, 3600*2 ].min
        puts "Adding #{timespan} seconds to WORK-E4A9-4BCD-9824-1EEC4D648408"
        Bank::put("WORK-E4A9-4BCD-9824-1EEC4D648408", timespan)
        KeyValueStore::destroy(nil, "843d19ab-4c64-4186-a455-b09e441e13a7")
    end

    # Work::workShouldBeRunning()
    def self.workShouldBeRunning()
        return false if !DoNotShowUntil::isVisible("WORK-E4A9-4BCD-9824-1EEC4D648408")
        return false if (BankExtended::stdRecoveredDailyTimeInHours("WORK-E4A9-4BCD-9824-1EEC4D648408") > Work::targetRT())
        return false if [0, 6].include?(Time.new.wday)
        return false if Time.new.hour < 9
        return false if Time.new.hour >= 17
        true
    end

    # ---------------------------------------------------------------------------

    # Work::targetRT()
    def self.targetRT()
        6
    end

    # Work::formatPriorityFile(text)
    def self.formatPriorityFile(text)
        text.lines.first(5).map{|line| "        #{line}" }.join()
    end

    # ---------------------------------------------------------------------------

    # Work::toString()
    def self.toString()
        "[work] (rt: #{"%4.2f" % BankExtended::stdRecoveredDailyTimeInHours("WORK-E4A9-4BCD-9824-1EEC4D648408")}) 👩🏻‍💻"
    end

    # Work::access()
    def self.access()

        uuid = "WORK-E4A9-4BCD-9824-1EEC4D648408"

        loop {
            system("clear")
            puts Work::toString().green
            puts "StructuredTodoText:".green
            puts (StructuredTodoTexts::getNoteOrNull(uuid) || "").green


            puts "note | [] | <datecode> | start | stop | exit".yellow
            puts UIServices::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")
            break if command == "exit"

            if Interpreting::match("note", command) then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(uuid) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(uuid)
                next
            end

            if command == "++" then
                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                break
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("start", command) then
                Work::start()
                next
            end

            if Interpreting::match("stop", command) then
                Work::stop()
                break
            end

            UIServices::mainMenuInterpreter(command)
        }
    end

    # Work::ns16s()
    def self.ns16s()
        objects = []

        if Work::workShouldBeRunning() and !Work::isRunning() then
            objects << {
                "uuid"      => "7fa74573-7b04-46c7-9253-4f6358f03529",
                "announce"  => "> outstanding work ; activate to start",
                "access"    => lambda { Work::start() },
                "done"      => nil,
                "domain"    => nil
            }
        end

        if Work::isRunning() then
            objects << {
                "uuid"     => "WORK-E4A9-4BCD-9824-1EEC4D648408",
                "announce" => "#{Work::toString()} (running: )".green,
                "access"   => lambda { Work::access() },
                "done"     => nil,
                "domain"   => Domains::workDomain(),
                "isRunningWorkC7DB" => true
            }
        end

        objects
    end

    # Work::nx19s()
    def self.nx19s()
        [
            {
                "announce" => "work",
                "lambda"   => lambda { Work::access() }
            }
        ]
    end
end

Thread.new {
    loop {
        sleep 120

        if (Time.new.to_i - (Work::getStartUnixtimeOrNull() || Time.new.to_i)) >= 3600 then
            Utils::onScreenNotification("Catalyst", "Work running for more than an hour")
        end
    }
}
