# encoding: UTF-8

class Streaming

    # Streaming::runItem(item, state)
    def self.runItem(item, state)

        if state == "awaiting start" then
            input = LucilleCore::askQuestionAnswerAsString("#{PolyFunctions::toString(item).green} (.. | skip | landing | commands) : ")
            if input == ".." then
                Streaming::runItem(item, "do ..")
            end
            if input == "skip" then
                DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_f + 3600*2)
            end
           if input == "landing" then
                PolyActions::landing(item)
                if Items::getItemOrNull(item["uuid"])
                    Streaming::runItem(item, "awaiting start")
                end
            end
            if input == "commands" then
                puts CatalystListing::listingCommands().yellow
                input = LucilleCore::askQuestionAnswerAsString("> ")
                return if input == ""
                CatalystListing::listingCommandInterpreter(input, ItemStore.new())
            end
        end

        if state == "do .." then
            PolyActions::doubleDot(item)
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
            item = CatalystListing::listingItems().first
            Streaming::runItem(item, "awaiting start")
        }
    end
end
