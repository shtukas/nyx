
class Anniversaries

    # Anniversaries::dateIsCorrect(date)
    def self.dateIsCorrect(date)
        begin
            Date.parse(date)
            true
        rescue
            false
        end
    end

    # Anniversaries::datePlusNMonthAnniversaryStyle(date: String, shiftInMonths: Integer)
    def self.datePlusNMonthAnniversaryStyle(date, shiftInMonths)
        dateElements = [date[0, 4].to_i, date[5, 2].to_i+shiftInMonths, date[8, 2].to_i]

        while dateElements[1] > 12 do
            dateElements[0] = dateElements[0]+1
            dateElements[1] = dateElements[1] - 12
        end

        date = "#{dateElements[0]}-#{dateElements[1].to_s.rjust(2, "0")}-#{dateElements[2].to_s.rjust(2, "0")}"

        while !Anniversaries::dateIsCorrect(date) do
            date = "#{date[0, 4]}-#{date[5, 2]}-#{(date[8, 2].to_i-1).to_s.rjust(2, "0")}"
        end
        date
    end

    # Anniversaries::computeNextCelebrationDateOrdinal(startdate: String, repeatType: String, lastCelebrationDate: String) # [ date: String, ordinal: Int ]
    def self.computeNextCelebrationDateOrdinal(startdate, repeatType, lastCelebrationDate)
        cursordate = Date.parse(startdate)
        cursorOrdinal = 0
        if repeatType == "weekly" then
            loop {
                if cursordate.to_s > lastCelebrationDate then
                    return [cursordate.to_s, cursorOrdinal]
                end
                cursordate = cursordate + 7
                cursorOrdinal = cursorOrdinal + 1
            }
        end
        if repeatType == "monthly" then
            loop {
                if cursordate.to_s > lastCelebrationDate then
                    return [cursordate.to_s, cursorOrdinal]
                end
                cursorOrdinal = cursorOrdinal + 1
                cursordate = Date.parse(Anniversaries::datePlusNMonthAnniversaryStyle(startdate, cursorOrdinal))
            }
        end
        if repeatType == "yearly" then
            loop {
                if cursordate.to_s > lastCelebrationDate then
                    return [cursordate.to_s, cursorOrdinal]
                end
                cursorOrdinal = cursorOrdinal + 1
                cursordate = "#{startdate[0, 4].to_i+cursorOrdinal}-#{startdate[5, 2]}-#{startdate[8, 2]}"
                while !Anniversaries::dateIsCorrect(cursordate) do
                    cursordate = "#{cursordate[0, 4]}-#{cursordate[5, 2]}-#{(cursordate[8, 2].to_i-1).to_s.rjust(2, "0")}"
                end
            }
        end
    end

    # Anniversaries::runTests()
    def self.runTests()
        raise "72118532-21b3-4897-a6d1-7c21458b4624" if Anniversaries::datePlusNMonthAnniversaryStyle("2020-11-25", 1) != "2020-12-25"
        raise "279b1ee3-728e-4883-9a4d-abf3b9a494d7" if Anniversaries::datePlusNMonthAnniversaryStyle("2020-12-25", 1) != "2021-01-25"
        raise "5507b102-2651-4b57-ba7b-7e6c217bddba" if Anniversaries::datePlusNMonthAnniversaryStyle("2021-01-01", 1) != "2021-02-01"
        raise "38e0536a-7943-4649-a002-6f65e9d88c0a" if Anniversaries::datePlusNMonthAnniversaryStyle("2021-01-31", 1) != "2021-02-28"
        raise "cd8feeec-54bd-4a63-be2c-e279c77390ba" if Anniversaries::datePlusNMonthAnniversaryStyle("2021-01-31", 2) != "2021-03-31"
        raise "d82394e7-708d-49a8-9d65-792a77093ce5" if Anniversaries::datePlusNMonthAnniversaryStyle("2021-01-31", 3) != "2021-04-30"
        raise "8bb58535-b435-4bbe-9ded-76cf5d1ce6ad" if Anniversaries::datePlusNMonthAnniversaryStyle("2024-01-31", 1) != "2024-02-29"
        raise "53ac9950-7df9-481d-a3cf-2ec07f566f89" if Anniversaries::datePlusNMonthAnniversaryStyle("2024-01-31", 2) != "2024-03-31"

        raise "ff1f70da-1342-4a20-91cb-f5a86f66a44c" if Anniversaries::computeNextCelebrationDateOrdinal("2021-02-28", "yearly", "2022-01-01").join(", ") != "2022-02-28, 1"
        raise "ff1f70da-1342-4a20-91cb-f5a86f66a44c" if Anniversaries::computeNextCelebrationDateOrdinal("2024-02-29", "yearly", "2025-01-01").join(", ") != "2025-02-28, 1"
    end

    # ----------------------------------------------------------------------------------

    # Anniversaries::interactivelyIssueNewElbramAnniversaryOrNull()
    def self.interactivelyIssueNewElbramAnniversaryOrNull()

        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/anniversaries/#{LucilleCore::timeStringL22()}.marble"

        Elbrams::issueNewEmptyElbram(filepath)

        Elbrams::set(filepath, "uuid", SecureRandom.uuid)
        Elbrams::set(filepath, "unixtime", Time.new.to_i)
        Elbrams::set(filepath, "domain", "anniversaries")

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        if description == "" then
            FileUtils.rm(filepath)
            return nil
        end
        Elbrams::set(filepath, "description", description)

        Elbrams::set(filepath, "type", "Line")
        Elbrams::set(filepath, "payload", "")

        startdate = LucilleCore::askQuestionAnswerAsString("startdate (empty to abort): ")
        if startdate == "" then
            FileUtils.rm(filepath)
            return nil
        end
        Elbrams::set(filepath, "startdate", anniversary["startdate"])

        repeatType = LucilleCore::selectEntityFromListOfEntitiesOrNull("repeat type", ["weekly", "monthly", "yearly"])
        if repeatType.nil? then
            FileUtils.rm(filepath)
            return nil
        end
        Elbrams::set(filepath, "repeatType", repeatType)

        lastCelebrationDate = LucilleCore::askQuestionAnswerAsString("lastCelebrationDate (default to today): ")
        if lastCelebrationDate == "" then
            lastCelebrationDate = Utils::today()
        end
        Elbrams::set(filepath, "lastCelebrationDate", lastCelebrationDate)

        marble
    end

    # Anniversaries::marbleNextDateOrdinal(marble) # [ date: String, ordinal: Int ]
    def self.marbleNextDateOrdinal(marble)
        filepath = marble.filepath()
        Anniversaries::computeNextCelebrationDateOrdinal(Elbrams::get(filepath, "startdate"), Elbrams::get(filepath, "repeatType"), Elbrams::get(filepath, "lastCelebrationDate"))
    end

    # Anniversaries::toString(marble)
    def self.toString(marble)
        filepath = marble.filepath()
        "[anniversary] [#{Anniversaries::marbleNextDateOrdinal(marble).join(", ")}] #{Elbrams::get(filepath, "description")} (#{Elbrams::get(filepath, "repeatType")} since #{Elbrams::get(filepath, "startdate")})"
    end

    # Anniversaries::ns16s()
    def self.ns16s()
        Elbrams::marblesOfGivenDomainInOrder("anniversaries")
            .select{|marble| Anniversaries::marbleNextDateOrdinal(marble)[0] <= Utils::today() }
            .map{|marble|
                filepath = marble.filepath()
                {
                    "uuid"     => Elbrams::get(filepath, "uuid"),
                    "announce" => Anniversaries::toString(marble),
                    "start"   => lambda{
                        puts Anniversaries::toString(marble).green
                        if LucilleCore::askQuestionAnswerAsBoolean("done ? : ") then
                            Elbrams::set(filepath, "lastCelebrationDate", Time.new.to_s[0, 10])
                        end
                    },
                    "done"   => lambda{
                        puts Anniversaries::toString(marble).green
                        Elbrams::set(filepath, "lastCelebrationDate", Time.new.to_s[0, 10])
                    }
                }
            }
            .sort{|i1, i2| i1["announce"]<=>i2["announce"] }
            .select{|ns16| DoNotShowUntil::isVisible(ns16["uuid"]) }
    end

    # Anniversaries::dailyBriefing()
    def self.dailyBriefing()
        puts "Anniversaries daily briefing:"
        Elbrams::marblesOfGivenDomainInOrder("anniversaries")
            .sort{|i1, i2| Anniversaries::marbleNextDateOrdinal(i1)[0] <=> Anniversaries::marbleNextDateOrdinal(i2)[0] }
            .each{|marble|
                puts Anniversaries::toString(marble)
            }
        LucilleCore::pressEnterToContinue()
    end

    # Anniversaries::dailyBriefingIfNotDoneToday()
    def self.dailyBriefingIfNotDoneToday()
        if !KeyValueStore::flagIsTrue(nil, "9140133b-4189-4c5f-b85f-8b3c9a77e0c2:#{Utils::today()}") then
            Anniversaries::dailyBriefing()
            KeyValueStore::setFlagTrue(nil, "9140133b-4189-4c5f-b85f-8b3c9a77e0c2:#{Utils::today()}")
        end
    end

    # Anniversaries::landing(marble)
    def self.landing(marble)
        filepath = marble.filepath()
        loop {
            return if !marble.isStillAlive()
            puts Anniversaries::toString(marble).green
            mx = LCoreMenuItemsNX1.new()
            mx.item("update start date".yellow, lambda { 
                startdate = LucilleCore::askQuestionAnswerAsString("start date: ")
                return if startdate == ""
                Elbrams::set(filepath, "startdate", startdate)
            })
            mx.item("destroy".yellow, lambda { 
                marble.destroy()
            })
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Anniversaries::anniversariesDive()
    def self.anniversariesDive()
        loop {
            marbles = Elbrams::marblesOfGivenDomainInOrder("anniversaries")
                        .sort{|i1, i2| Anniversaries::marbleNextDateOrdinal(i1)[0] <=> Anniversaries::marbleNextDateOrdinal(i2)[0] }
            marble = LucilleCore::selectEntityFromListOfEntitiesOrNull("marble", marbles, lambda{|m| Anniversaries::toString(m) })
            return if marble.nil?
            Anniversaries::landing(marble)
        }
    end

    # Anniversaries::main()
    def self.main()
        loop {
            puts "Anniversaries (main)"
            mx = LCoreMenuItemsNX1.new()
            mx.item("dive into anniversary marbles".yellow, lambda { 
                Anniversaries::anniversariesDive()
            })
            mx.item("make new anniversary marble".yellow, lambda { 
                Anniversaries::interactivelyIssueNewElbramAnniversaryOrNull()
            })
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end