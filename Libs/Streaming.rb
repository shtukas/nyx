# encoding: UTF-8

class Streaming

    # Streaming::runItem(item, state)
    def self.runItem(item, state)

        return if Phage::getObjectOrNull(item["uuid"]).nil?

        if state == "awaiting start" then
            input = LucilleCore::askQuestionAnswerAsString("[#{state}] #{PolyFunctions::toString(item).green} (.. | start | done | time | skip | landing | commands) : ")
            if input == "" then
                Streaming::runItem(item, state)
            end
            if input == ".." then
                PolyActions::doubleDot(item)
            end
            if input == "start" then
                PolyActions::start(item)
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
            if input == "commands" then
                puts CatalystListing::listingCommands().yellow
                input = LucilleCore::askQuestionAnswerAsString("> ")
                return if input == ""
                CatalystListing::listingCommandInterpreter(input, ItemStore.new())
                Streaming::runItem(item, "awaiting start")
            end
        end

        if state == "running" then
            input = LucilleCore::askQuestionAnswerAsString("[#{state}] #{PolyFunctions::toString(item).green} (access | done | stop | (stop+) skip | landing | commands) : ")
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
                PolyActions::stop(item)
                Streaming::runItem(item, "stopped")
            end
            if input == "skip" then
                PolyActions::stop(item)
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
            input = LucilleCore::askQuestionAnswerAsString("[#{state}] #{PolyFunctions::toString(item).green} (.. | start | done | skip | landing | commands) : ")
            if input == "" then
                Streaming::runItem(item, state)
            end
            if input == ".." then
                PolyActions::doubleDot(item)
                Streaming::runItem(item, "running")
            end
            if input == "start" then
                PolyActions::start(item, false)
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

            SystemEvents::processIncomingEventsFromLine(true)

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/NxTodos-BufferIn")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTodos::bufferInImport(location)
                    puts "Picked up from NxTodos-BufferIn: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            if NxBallsIO::nxballs().size > 0 then
                CatalystListing::displayListing()
                next
            end

            system("clear")
            CatalystListing::listingItems().each{|item|
                Streaming::runItem(item, "awaiting start")
            }
        }
    end
end
