# encoding: UTF-8

class Catalyst

    # Catalyst::itemsForListing()
    def self.itemsForListing()
        [
            Zone::items(),
            Anniversaries::itemsForListing(),
            Waves::itemsForListing(),
            TxDateds::itemsForListing(),
            TxPlus::itemsForListing(),
            TxTodos::itemsForListing(),
        ]
            .flatten
    end

    # Catalyst::printListing(floats, section1, section2)
    def self.printListing(floats, section1, section2)
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

        reference = The99Percent::getReference()
        current   = The99Percent::getCurrentCount()
        ratio     = current.to_f/reference["count"]
        puts ""
        puts "👩‍💻 🔥 #{current} #{ratio}, #{reference["count"]} #{reference["datetime"]}"
        vspaceleft = vspaceleft - 2
        if ratio < 0.99 then
            The99Percent::issueNewReference()
            return
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
                    if line.include?("(zone)") then
                        line = line.yellow
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        }

        if section1.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            printSection.call(section1, store)
        end

        if section2.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            printSection.call(section2, store)
        end

        puts ""
        input = LucilleCore::askQuestionAnswerAsString("> ")

        return if input == ""

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
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
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                        .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }

            section2 = Catalyst::itemsForListing()
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                        .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }

            getPositionForItem = lambda {|item|
                position = XCache::getOrNull("3253d3b5-4cbb-4600-b1d1-28a22e46828d:#{item["uuid"]}")
                if position then
                    position.to_f
                else
                    position = Time.new.to_f
                    XCache::set("3253d3b5-4cbb-4600-b1d1-28a22e46828d:#{item["uuid"]}", position)
                    position
                end
            }

            section2.each{|item| getPositionForItem.call(item) } # to start with the natural position

            section2 = section2.sort{|i1, i2| getPositionForItem.call(i1) <=> getPositionForItem.call(i2) }

            section1, section2 = section2.partition{|item| NxBallsService::isActive(item["uuid"]) }

            Catalyst::printListing(floats, section1, section2)
        }
    end
end
