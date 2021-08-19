# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class Fitness
    # Fitness::ns16s()
    def self.ns16s()
        ns16s = JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`)
        ns16s.map{|ns16|
            ns16["commands"] = [">>"]
            ns16["interpreter"] = lambda {|command|
                if command == ">>" then
                    system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{ns16["domain"]}") 
                end
            }
            ns16
        }
    end
end

class NS16sOperator

    # NS16sOperator::ns16s()
    def self.ns16s()
        [
            DetachedRunning::ns16s(),
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            Fitness::ns16s(),
            NxOnDate::ns16s(),
            PriorityFile::ns16OrNull("/Users/pascal/Desktop/Priority.txt"),
            Waves::ns16s(),
            Inbox::ns16s(),
            DrivesBackups::ns16s(),
            Nx50s::ns16s(),
            Nx51s::ns16s()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .sort{|i1, i2| i1["metric"] <=> i2["metric"] }
    end
end

class UIServices

    # UIServices::catalystMainInterface()
    def self.catalystMainInterface()

        getNS16s = lambda {
            NS16sOperator::ns16s()
        }

        processNS16s = lambda {|ns16s|

            system("clear")

            vspaceleft = Utils::screenHeight()-10

            puts ""

            commandStrWithPrefix = lambda{|ns16, indx|
                return "" if indx != 0
                return "" if ns16["commands"].nil?
                return "" if ns16["commands"].empty?
                " (commands: #{ns16["commands"].join(", ")})".yellow
            }

            ns16s
                .each_with_index{|ns16, indx|
                    metricStr = "(#{"%6.3f" % ns16["metric"]})".blue
                    posStr = "(#{"%3d" % indx})"
                    announce = "#{metricStr} #{posStr} #{ns16["announce"]}#{commandStrWithPrefix.call(ns16, indx)}"
                    break if ((indx > 0) and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                    puts announce
                    vspaceleft = vspaceleft - Utils::verticalSize(announce)
                }

            puts ""

            puts Interpreters::listingCommands().yellow
            puts Interpreters::mainMenuCommands().yellow
            puts Work::workMenuCommands().yellow

            puts ""

            puts [
                "[info   ]",
                "(inbox: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx60-69315F2A-BE92-4874-85F1-54F140E3B243").round(2)})",
                "(waves: rt: #{BankExtended::stdRecoveredDailyTimeInHours("WAVES-A81E-4726-9F17-B71CAD66D793").round(2)})",
                "(Nx50s: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7").round(2)})",
                "(Nx50s: #{Nx50s::nx50s().size} items, done: today: #{Nx50s::completionLogSize(1)}, week: #{Nx50s::completionLogSize(7)}, month: #{Nx50s::completionLogSize(30)})",
                "(Nx51s: rt: #{BankExtended::stdRecoveredDailyTimeInHours(Work::bankaccount()).round(2)})"
            ].join(" ").yellow

            puts ""

            command = LucilleCore::askQuestionAnswerAsString("> ")

            return if command == ""

            if (i = Interpreting::readAsIntegerOrNull(command)) then
                return if ns16s[i].nil?
                ns16s[i]["selected"].call()
                return
            end

            if ns16s[0] then
                if ns16s[0]["interpreter"] then
                    status = ns16s[0]["interpreter"].call(command)
                    return if status
                end
            end

            Interpreters::listingInterpreter(ns16s, command)
            Interpreters::mainMenuInterpreter(command)
            Work::workMenuInterpreter(command)
        }

        loop {
            processNS16s.call(getNS16s.call())
        }
    end
end
