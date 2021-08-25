# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class Fitness
    # Fitness::ns16s()
    def self.ns16s()
        ns16s = JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`)
        ns16s.map{|ns16|
            ns16["commands"] = [".."]
            ns16["interpreter"] = lambda {|command|
                if command == ".." then
                    system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{ns16["domain"]}") 
                end
            }
            ns16["run"] = lambda {
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{ns16["domain"]}") 
            }
            ns16
        }
    end
end

class UIServices

    # UIServices::mainView(ns16s)
    def self.mainView(ns16s)
        system("clear")

        vspaceleft = Utils::screenHeight()-11

        nxfloats = NxFloats::nxfloats()
        if nxfloats.size > 0 then
            puts ""
            nxfloats.each_with_index{|nxfloat, indx|
                puts "(#{indx.to_s.rjust(3, " ")}) #{NxFloats::toString(nxfloat).gsub("float", "floa").yellow}"
                vspaceleft = vspaceleft - 1
            }
            vspaceleft = vspaceleft - 1
        end

        priority = IO.read("/Users/pascal/Desktop/Priority.txt").strip
        if priority.size > 0 then
            puts ""
            priority = priority.lines.first(10).join()
            puts priority.green
            vspaceleft = vspaceleft - Utils::verticalSize(priority) - 1
        end

        commandStrWithPrefix = lambda{|ns16, indx|
            return "" if indx != 0
            return "" if ns16["commands"].nil?
            return "" if ns16["commands"].empty?
            " (commands: #{ns16["commands"].join(", ")})".yellow
        }

        puts ""

        ns16s
            .each_with_index{|ns16, indx|
                posStr = "(#{"%3d" % indx})"
                announce = "#{posStr} #{ns16["announce"]}#{commandStrWithPrefix.call(ns16, indx)}"
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
            "(waves: rt: #{BankExtended::stdRecoveredDailyTimeInHours("WAVES-A81E-4726-9F17-B71CAD66D793").round(2)})",
            "(Nx25s: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx25s-DE6269A0-B816-4A86-9C8F-FBE332D044C3").round(2)} ; #{Nx50s::nx50s().size} items)",
            "(Nx50s: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7").round(2)} ; #{Nx50s::nx50s().size} items)",
            "(Nx51s: rt: #{BankExtended::stdRecoveredDailyTimeInHours(Work::bankaccount()).round(2)})",
        ].join(" ").yellow

        puts ""

        command = LucilleCore::askQuestionAnswerAsString("> ")

        return if command == ""

        if (i = Interpreting::readAsIntegerOrNull(command)) then
            return if ns16s[i].nil?
            ns16s[i]["run"].call()
            return
        end

        if command == ">>" then
            TaskServer::removeFirstElement()
            return
        end

        if ns16s[0] then
            if ns16s[0]["interpreter"] then
                ns16s[0]["interpreter"].call(command)
                TaskServer::removeFirstElement()
            end
        end

        Interpreters::listingInterpreter(ns16s, command)
        Interpreters::mainMenuInterpreter(command)
        Work::workMenuInterpreter(command)
    end
end
