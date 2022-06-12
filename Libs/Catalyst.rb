# encoding: UTF-8

class Catalyst

    # Catalyst::itemsForListing()
    def self.itemsForListing()
        TxTodos::plusGeneration3()
        [
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            Zone::items(),
            Anniversaries::itemsForListing(),
            Waves::itemsForListing(),
            TxDateds::itemsForListing(),
            TxPlus::items(),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
    end

    # Catalyst::printListing(floats, section1, section2, section3, section4)
    def self.printListing(floats, section1, section2, section3, section4)
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

        if Machines::isLucille20() then
            reference = The99Percent::getReference()
            current   = The99Percent::getCurrentCount()
            ratio     = current.to_f/reference["count"]
            puts ""
            puts "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} )"
            vspaceleft = vspaceleft - 2
            if ratio < 0.99 then
                The99Percent::issueNewReference()
                return
            end
        end

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        if floats.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
            floats.each{|item|
                store.register(item, false)
                line = "#{store.prefixString()} [#{Time.at(item["unixtime"]).to_s[0, 10]}] #{LxFunction::function("toString", item)}".yellow
                puts line
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }
        end

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

        printSection = lambda {|section, store, yellowDisplay, prefix|
            section
                .each{|item|
                    store.register(item, true)
                    line = LxFunction::function("toString", item)
                    line = "#{store.prefixString()} #{line}"
                    break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    if prefix then
                        line = "#{prefix}#{line}"
                    end
                    if yellowDisplay then
                        line = line.yellow
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        }

        puts ""
        vspaceleft = vspaceleft - 1

        printSection.call(section1, store, false, nil)
        printSection.call(section2, store, false, nil)
        printSection.call(section4, store, true, " 🐾 ")
        printSection.call(section3, store, true, " ⏱  ")

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

        command, objectOpt = Commands::inputParser(input, store)
        #puts "parser: command:#{command}, objectOpt: #{objectOpt}"

        LxAction::action(command, objectOpt)
    end

    # Catalyst::program2()
    def self.program2()
        initialCodeTrace = CommonUtils::generalCodeTrace()
        loop {

            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            floats = TxFloats::itemsForListing()

            section2 = Catalyst::itemsForListing()

            # section1 : running items
            # section2 : elements without pluses
            # section3 : pluses (active)
            # section4 : pluses (not active, done for the day or overflowing)

            section1, section2 = section2.partition{|item| NxBallsService::isActive(item["uuid"]) }
            section2, section3 = section2.partition{|item| item["mikuType"] != "TxPlus" }
            section4, section3 = section3.partition{|item|
                (lambda {|item|
                    return true if XCache::getFlag("something-is-done-for-today-a849e9355626:#{CommonUtils::today()}:#{item["uuid"]}")
                    return true if BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]) >= 1
                    Bank::combinedValueOnThoseDays(item["uuid"], CommonUtils::dateSinceLastSaturday()) >= 3600*5
                }).call(item)
            }

            section3 = section3.sort{|i1, i2| BankExtended::stdRecoveredDailyTimeInHours(i1["uuid"]) <=> BankExtended::stdRecoveredDailyTimeInHours(i2["uuid"]) }

            Catalyst::printListing(floats, section1, section2, section3, section4)
        }
    end
end
