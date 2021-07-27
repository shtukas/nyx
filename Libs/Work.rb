
# encoding: UTF-8

# -----------------------------------------------------------------------

class Work

    # ---------------------------------------------------------------------------

    # Work::targetRT()
    def self.targetRT()
        6
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

        nxball = BankExtended::makeNxBall(["WORK-E4A9-4BCD-9824-1EEC4D648408"])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = BankExtended::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Work running for more than an hour")
                end
            }
        }

        loop {
            system("clear")
            puts Work::toString().green
            puts "StructuredTodoText:".green
            puts (StructuredTodoTexts::getNoteOrNull(uuid) || "").green


            puts "note | [] | <datecode> | detach running | exit".yellow

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

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2("(work)", Time.new.to_i, ["WORK-E4A9-4BCD-9824-1EEC4D648408"])
                break
            end
        }

        thr.exit

        BankExtended::closeNxBall(nxball, true)
    end

    # Work::ns16s()
    def self.ns16s()
        return [] if !Work::workShouldBeRunning()
        uuid = "WORK-E4A9-4BCD-9824-1EEC4D648408"
        [
            {
                "uuid"      => uuid,
                "announce"  => Work::toString(),
                "access"    => lambda { Work::access() },
                "done"      => nil,
                "domain"    => Domains::workDomain()
            }
        ]
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
