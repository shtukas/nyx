# encoding: UTF-8

class Catalyst

    # Catalyst::primaryCommandProcess()
    def self.primaryCommandProcess()
        puts Commands::commands().yellow
        input = LucilleCore::askQuestionAnswerAsString("> ")
        command, objectOpt = Commands::run(input, nil)
        #puts "parser: command:#{command}, objectOpt: #{objectOpt}"
        LxAction::action(command, objectOpt)
    end

    # Catalyst::topFilepath()
    def self.topFilepath()
        "/Volumes/Keybase (#{ENV['USER']})/private/0x1021/top.txt"
    end

    # Catalyst::getTopOrNull()
    def self.getTopOrNull()
        content = IO.read(Catalyst::topFilepath()).strip
        return nil if content == ""
        text = content.lines.first(10).select{|line| line.strip.size > 0 }.join.strip
        return nil if text == ""
        text
    end

    # Catalyst::section1()
    def self.section1()
        [
            TxProjects::items(),
            NxFrames::items()
        ].flatten
    end

    # Catalyst::section2()
    def self.section2()
        [
            JSON.parse(`#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness ns16s`),
            Anniversaries::section2(),
            Waves::items(),
            TxDateds::section2(),
            NxLines::section2(),
            TxProjects::section2(),
            Streaming::section2(),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
    end

    # Catalyst::program()
    def self.program()

        initialCodeTrace = CommonUtils::generalCodeTrace()
 
        if Machines::isLucille20() then 
            Thread.new {
                loop {
                    sleep 3600
                    system("#{File.dirname(__FILE__)}/operations/vienna-import")
                }
            }
        end

        loop {

            #puts "(code trace)"
            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            #puts "(NxTasks-Inbox)"
            LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Desktop/NxTasks-Inbox").each{|location|
                item = NxTasks::issueFromInboxLocation(location)
                puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)
            }

            SystemEvents::pickupDrops()

            Catalyst::printListing()
        }
    end

    # Catalyst::printListing()
    def self.printListing()
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

        if Machines::isLucille20() then
            reference = The99Percent::getReference()
            current   = The99Percent::getCurrentCount()
            ratio     = current.to_f/reference["count"]
            line      = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} ) [section2: #{(XCache::getOrDefaultValue("6ee981a4-315f-4f82-880f-5806424c904f", "0").to_f).round(2)} days]"
            puts ""
            puts line
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

        running = NxBallsIO::nxballs()
        if running.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            running
                .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] }
                .each{|nxball|
                    store.register(nxball, false)
                    line = "#{store.prefixString()} [running] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                    puts line.green
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        if top = Catalyst::getTopOrNull() then
            puts ""
            puts top.green
            vspaceleft = vspaceleft - (CommonUtils::verticalSize(top) + 1)
        end

        section1 = Catalyst::section1()
        if !section1.empty? then
            puts ""
            vspaceleft = vspaceleft - 1
            Catalyst::section1()
                .each{|item|
                    store.register(item, false)
                    line = "#{store.prefixString()} #{LxFunction.function("toString", item)}"
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        section2 = Catalyst::section2()
        if !section2.empty? then
            puts ""
            vspaceleft = vspaceleft - 1
            section2
                .each{|item|
                    store.register(item, true)
                    line = "#{store.prefixString()} #{LxFunction::function("toString", item)}"
                    break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

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
end
