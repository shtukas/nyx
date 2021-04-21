# encoding: UTF-8

class UIServices

    # UIServices::servicesFront()
    def self.servicesFront()
        loop {

            ms = LCoreMenuItemsNX1.new()

            ms.item("Anniversaries", lambda { Anniversaries::main() })

            ms.item("Waves", lambda { Waves::main() })

            puts ""

            ms.item("new wave", lambda { Waves::issueNewWaveInteractivelyOrNull() })

            ms.item("new quark", lambda { Quarks::interactivelyIssueNewMarbleQuarkOrNull(Quarks::computeLowL22()) })

            puts ""

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::waveLikeNS16s()
    def self.waveLikeNS16s()
        Anniversaries::ns16s() + Waves::ns16s()
    end

    # UIServices::orderNS17s(ns17s, synthetic)
    def self.orderNS17s(ns17s, synthetic)

        pool, rest = [ns17s.take(3), ns17s.drop(3)]

        poolactive, poolnonactive = pool.partition{|ns17| ns17["rt"] > 0}

        poolactivealpha, poolactivebeta = poolactive.partition{|ns17| ns17["rt"] < 2}

        poolactivebeta = poolactivebeta.map{|ns17|
            ns16 = ns17["ns16"]
            ns16["announce"] = ns16["announce"].red
            ns17["ns16"] = ns16
            ns17
        }

        syntheticIsWinning = (poolactivealpha.size > 0 and synthetic["rt"] < poolactivealpha.map{|ns17| ns17["rt"]}.min)

        if poolactivealpha.size > 0 and !syntheticIsWinning then
            return (poolactivealpha + [synthetic]).sort{|o1, o2| o1["rt"] <=> o2["rt"] } + poolactivebeta.sort{|o1, o2| o1["rt"] <=> o2["rt"] } + poolnonactive + rest
        end

        if poolactivealpha.size > 0 and syntheticIsWinning then
            zeros, nonzeros = ns17s.partition{|ns17| ns17["rt"] == 0}
            return zeros.first(3) + [synthetic] + nonzeros.sort{|o1, o2| o1["rt"] <=> o2["rt"] } + zeros.drop(3)
        end

        if poolactivealpha.size == 0 then
            zeros, nonzeros = ns17s.partition{|ns17| ns17["rt"] == 0}
            return zeros.first(3) + [synthetic] + nonzeros.sort{|o1, o2| o1["rt"] <=> o2["rt"] } + zeros.drop(3)
        end

        raise "23479e0d-3d4e-4ca3-a44e-1c0c567ba84c"
    end

    # UIServices::todayNS16sOrNull()
    def self.todayNS16OrNull()
        text = IO.read("/Users/pascal/Desktop/Today.txt").strip
        return nil if text == ""
        text = text.lines.map{|line| "      #{line}" }.join()
        {
            "uuid"     => Digest::SHA1.hexdigest(text),
            "announce" => ("-- Today.txt --------------------------\n" + text).green,
            "start"    => lambda {},
            "done"     => lambda {},
            "isToday.txt" => true
        }
    end

    # UIServices::quarksAndSyntheticNS16s()
    def self.quarksAndSyntheticNS16s()
        makeSyntheticNs17 = lambda {|syntheticRT|
            ns16 = {
                "uuid"     => SecureRandom.hex,
                "announce" => "(#{"%5.3f" % syntheticRT}) #{"(/◕ヮ◕)/".green} Synthetic 🚀 🌝",
                "start"    => lambda { },
                "done"     => lambda { }
            }
            {
                "ns16"      => ns16,
                "rt"        => syntheticRT,
                "synthetic" => true
            }
        }
        syntheticRT = Synthetic::getRecoveryTimeInHours()
        synthetic = makeSyntheticNs17.call(syntheticRT)
        UIServices::orderNS17s(Quarks::ns17s(), synthetic).map{|ns17| ns17["ns16"] }
    end

    # UIServices::catalystNS16s()
    def self.catalystNS16s()
        isWorkTime = ([1,2,3,4,5].include?(Time.new.wday) and (9..16).to_a.include?(Time.new.hour) and !KeyValueStore::flagIsTrue(nil, "a2f220ce-e020-46d9-ba64-3938ca3b69d4:#{Utils::today()}"))
        if isWorkTime then
            return WorkInterface::ns16s() + UIServices::waveLikeNS16s() + [ UIServices::todayNS16OrNull() ].compact + UIServices::quarksAndSyntheticNS16s()
        end
        UIServices::waveLikeNS16s() + [ UIServices::todayNS16OrNull() ].compact  + UIServices::quarksAndSyntheticNS16s()
    end

    # UIServices::catalystDisplayLoop()
    def self.catalystDisplayLoop()

        loop {

            Utils::importFromLucilleInbox()
            Anniversaries::dailyBriefingIfNotDoneToday()

            if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("3e15e448-25e2-4d03-a2b4-e5f23a9af461", 600) then
                puts "MarblesFsck::fsck()"
                MarblesFsck::fsck()
            end

            vspaceleft = Utils::screenHeight()-4

            priority = IO.read("/Users/pascal/Desktop/Priority.txt").strip
            if priority.size > 0 then
                puts "-- Priority.txt -----------------------"
                puts priority.green
                vspaceleft = vspaceleft - Utils::verticalSize(priority) - 1
            end

            puts "-- listing ----------------------------"

            items = UIServices::catalystNS16s()
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }

            items.each_with_index{|item, indx|
                announce = "(#{"%3d" % (indx+1)}) #{item["announce"]}"
                break if (vspaceleft - Utils::verticalSize(announce)) < 0
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }

            puts "listing: .. (access top) | select <n> | start (<n>) | done (<n>) | / | new wave | new quark | new work".yellow
            puts "top    : [] (top next transformation) | ++ by an hour | + <weekday> | + <float> <datecode unit>".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            next if command == ""

            # -- listing -----------------------------------------------------------------------------

            if Interpreting::match("..", command) then
                items[0]["start"].call()
            end

            if Interpreting::match("select *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal-1]
                next if item.nil?
                item["start"].call()
            end

            if Interpreting::match("start", command) then
                items[0]["start"].call()
            end

            if Interpreting::match("start *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                next if item.nil?
                item["start"].call()
            end

            if Interpreting::match("done", command) then
                items[0]["done"].call()
            end

            if Interpreting::match("done *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                next if item.nil?
                item["done"].call()
            end

            if Interpreting::match("/", command) then
                UIServices::servicesFront()
            end

            if Interpreting::match("new wave", command) then
                Waves::issueNewWaveInteractivelyOrNull()
            end

            if Interpreting::match("new quark", command) then
                Quarks::interactivelyIssueNewMarbleQuarkOrNull(Quarks::computeLowL22())
            end

            if Interpreting::match("new work", command) then
                system("work new")
            end

            # -- top -----------------------------------------------------------------------------

            if Interpreting::match("[]", command) then

                filepath = "/Users/pascal/Desktop/Priority.txt"
                text = IO.read(filepath).strip
                if text.size > 0 then
                    text = SectionsType0141::applyNextTransformationToText(text)
                    File.open(filepath, "w"){|f| f.puts(text)}
                    next
                end

                item = items[0]
                if item["isToday.txt"] then

                    filepath = "/Users/pascal/Desktop/Today.txt"
                    text = IO.read(filepath).strip
                    if text.size > 0 then
                        text = SectionsType0141::applyNextTransformationToText(text)
                        File.open(filepath, "w"){|f| f.puts(text)}
                        next
                    end

                end

                next
            end

            if Interpreting::match("++", command) then
                DoNotShowUntil::setUnixtime(items[0]["uuid"], Time.new.to_i+3600)
            end

            if Interpreting::match("+ *", command) then
                _, weekdayname = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{weekdayname}")
                next if unixtime.nil?
                item = items[0]
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end

            if Interpreting::match("+ * *", command) then
                _, amount, unit = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{amount}#{unit}")
                next if unixtime.nil?
                item = items[0]
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end
        }

    end

end


