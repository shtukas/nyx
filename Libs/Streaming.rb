# encoding: UTF-8

class Streaming

    # Streaming::states()
    def self.states()
        ["awaiting start", "running", "stopped"]
    end

    # Streaming::statesPadding()
    def self.statesPadding()
        Streaming::states().map{|state| state.size }.max
    end

    # Streaming::stateToString(state)
    def self.stateToString(state)
        "#{state.ljust(Streaming::statesPadding())}"
    end

    # Streaming::runItem(item, state)
    def self.runItem(item, state)

        return if PolyFunctions::getCatalystItemOrNull(item["uuid"]).nil?

        if state == "awaiting start" then
            input = LucilleCore::askQuestionAnswerAsString("[#{Streaming::stateToString(state)}] #{PolyFunctions::toString(item).green} (.. | start | done | time | skip | +(datecode) | landing | exit | commands) : ")
            if input == "" then
                Streaming::runItem(item, state)
            end

            if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end

            if input == ".." then
                PolyActions::doubleDot(item)
            end
            if input == "start" then
                Streaming::runItem(item, "running")
            end
            if input == "done" then
                PolyActions::done(item, false)
            end
            if input == "time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
                PolyActions::giveTime(item, timeInHours*3600)
                Streaming::runItem(item, "awaiting start")
            end
            if input == "skip" then
                DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_f + 3600*2)
            end
            if input == "landing" then
                PolyActions::landing(item)
                Streaming::runItem(item, "awaiting start")
            end
            if input == "exit" then
                return "exit"
            end
            if input == "commands" then
                puts CatalystListing::listingCommands().yellow
                input = LucilleCore::askQuestionAnswerAsString("> ")
                return if input == ""
                CatalystListing::listingCommandInterpreter(input, ItemStore.new())
                Streaming::runItem(item, "awaiting start")
            end
        end

        if state == "running" then
            input = LucilleCore::askQuestionAnswerAsString("[#{Streaming::stateToString(state)}] #{PolyFunctions::toString(item).green} (access | done | stop | (stop+) skip | landing | commands) : ")
            if input == "" then
                Streaming::runItem(item, state)
            end

            if input == "access" then
                PolyActions::access(item)
                Streaming::runItem(item, "running")
            end
            if input == "done" then
                PolyActions::done(item, false)
            end
            if input == "stop" then
                Streaming::runItem(item, "stopped")
            end
            if input == "skip" then
                DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_f + 3600*2)
            end
           if input == "landing" then
                PolyActions::landing(item)
                Streaming::runItem(item, "running")
            end
            if input == "commands" then
                puts CatalystListing::listingCommands().yellow
                input = LucilleCore::askQuestionAnswerAsString("> ")
                return if input == ""
                CatalystListing::listingCommandInterpreter(input, ItemStore.new())
                Streaming::runItem(item, "running")
            end
        end

        if state == "stopped" then
            input = LucilleCore::askQuestionAnswerAsString("[#{Streaming::stateToString(state)}] #{PolyFunctions::toString(item).green} (.. | start | done | skip | +(datecode) | landing | commands) : ")
            if input == "" then
                Streaming::runItem(item, state)
            end

            if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end

            if input == ".." then
                PolyActions::doubleDot(item)
                Streaming::runItem(item, "running")
            end
            if input == "start" then
                Streaming::runItem(item, "running")
            end
            if input == "done" then
                PolyActions::done(item, false)
            end
            if input == "skip" then
                DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_f + 3600*2)
            end
           if input == "landing" then
                PolyActions::landing(item)
                Streaming::runItem(item, "stopped")
            end
            if input == "commands" then
                puts CatalystListing::listingCommands().yellow
                input = LucilleCore::askQuestionAnswerAsString("> ")
                return if input == ""
                CatalystListing::listingCommandInterpreter(input, ItemStore.new())
                Streaming::runItem(item, "stopped")
            end
        end
    end

    # Streaming::streaming()
    def self.streaming()

        initialCodeTrace = CommonUtils::generalCodeTrace()

        loop {

            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/NxTodos-BufferIn")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTodos::bufferInImport(location)
                    puts "Picked up from NxTodos-BufferIn: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            system("clear")

            status = Streaming::runItem(CatalystListing::listingItemsInPriorityOrderDesc().first, "awaiting start")
            if status == "exit" then
                return
            end
        }
    end
end
