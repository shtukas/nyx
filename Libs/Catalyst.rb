# encoding: UTF-8

class Catalyst

    # Catalyst::itemsForListing()
    def self.itemsForListing()
        [
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            Anniversaries::itemsForListing(),
            Waves::itemsForListing(),
            TxDateds::itemsForListing(),
            NxShip::itemsForListing(),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
    end

    # Catalyst::printListing(section1, section2, section3)
    def self.printListing(section1, section2, section3)
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

        if Machines::isLucille20() then
            packet = XCache::getOrNull("numbers-cfa0a4bfba8e") # {"line": String, "ratio": Float}
            if packet then
                packet = JSON.parse(packet)
                puts ""
                puts packet["line"]
                vspaceleft = vspaceleft - 2
                if packet["ratio"] < 0.99 then
                    The99Percent::issueNewReference()
                    return
                end
            end
        end

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        puts ""
        vspaceleft = vspaceleft - 1
        NxFrames::itemsForListing()
            .each{|item|
                store.register(item, false)
                line = "#{store.prefixString()} #{NxFrames::toString(item)}"
                break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                if NxBallsService::isActive(item["uuid"]) then
                    line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                end
                puts line.yellow
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }

        running = NxBallsIO::getItems().select{|nxball| !section1.map{|item| item["uuid"] }.include?(nxball["uuid"]) }
        if running.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            running
                .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] } # || 0 because we had some running while updating this
                .each{|nxball|
                    store.register(nxball, true)
                    line = "#{store.prefixString()} [running] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                    puts line.green
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        printSection = lambda {|section, store|
            section
                .each{|item|
                    store.register(item, true)
                    line = LxFunction::function("toString", item)
                    line = "#{store.prefixString()} #{line}"
                    break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        }

        puts ""
        vspaceleft = vspaceleft - 1
        printSection.call(section1, store)
        printSection.call(section2, store)
        printSection.call(section3, store)

        puts ""
        input = LucilleCore::askQuestionAnswerAsString("> ")

        return if input == ""

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                NxBallsService::close(item["uuid"], true)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        Commands::run(input, store)
    end

    # Catalyst::program2()
    def self.program2()

        initialCodeTrace = CommonUtils::generalCodeTrace()
 
        if Machines::isLucille20() then
            Thread.new {
                loop {
                    sleep 120
                    reference = The99Percent::getReference()
                    current   = The99Percent::getCurrentCount()
                    ratio     = current.to_f/reference["count"]
                    line      = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} )"
                    packet    = {"line" => line, "ratio" => ratio}
                    XCache::set("numbers-cfa0a4bfba8e", JSON.generate(packet))
                }
            }
        end
 
        loop {

            puts "(code trace)"
            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            LucilleCore::locationsAtFolder("/Users/pascal/Desktop/Ships").each{|location|
                item = NxShip::locationToZero(location)
                puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)
            }

            puts "(items for listing)"
            section2 = Catalyst::itemsForListing()

            # section1  : running items
            # section2  : non zeroes: waves, ondates, frames
            # section3  : zeroes (active)

            section1, section2 = section2.partition{|item| NxBallsService::isActive(item["uuid"]) }

            section2, section3 = section2.partition{|item| item["mikuType"] != "NxShip" }

            Catalyst::printListing(section1, section2, section3)
        }
    end
end
