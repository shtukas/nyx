# encoding: UTF-8

$SyntheticIsFront  = false # Ugly global variable because I don't want to change the NS16 interface. 
$LowOrbitalIsFront = false # Well, since the first one was already there.

class UIServices

    # UIServices::servicesFront()
    def self.servicesFront()
        loop {

            ms = LCoreMenuItemsNX1.new()

            ms.item("Anniversaries", lambda { Anniversaries::main() })

            ms.item("Waves", lambda { Waves::main() })

            puts ""

            ms.item("new wave", lambda { Waves::issueNewWaveInteractivelyOrNull() })

            ms.item("new quark", lambda { Quarks::interactivelyIssueNewMarbleQuarkOrNull() })

            puts ""

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::waveLikeNS16s()
    def self.waveLikeNS16s()
        Anniversaries::ns16s() + Waves::ns16s()
    end

    # UIServices::orderNS17s(ns17s)
    def self.orderNS17s(ns17s)

        makeSyntheticControlNS17 = lambda {
            uuid = "5eb5553d-1884-439d-8b71-fa5344b0f4c7"
            rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
            ns16 = {
                "uuid"     => uuid,
                "announce" => "(#{"%5.3f" % rt}) #{"SYNTHETIC CONTROL".green} ☀️",
                "start"    => lambda { },
                "done"     => lambda { }               
            }
            {
                "uuid"        => ns16["uuid"],
                "ns16"        => ns16,
                "rt"          => rt,
                "isSynthetic" => true
            }
        }

        makeLowOrbitalControlNS17 = lambda {
            uuid = "4d9b5fff-cdf4-43be-ad87-3d1da1291fd1"
            rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
            ns16 = {
                "uuid"     => uuid,
                "announce" => "(#{"%5.3f" % rt}) #{"LOW ORBITAL CONTROL".green} 🛰",
                "start"    => lambda { },
                "done"     => lambda { }               
            }
            {
                "uuid"        => ns16["uuid"],
                "ns16"        => ns16,
                "rt"          => rt,
                "isLowOrbital" => true
            }
        }

        $SyntheticIsFront  = false
        $LowOrbitalIsFront = false

        synthetic = makeSyntheticControlNS17.call()
        orbital   = makeLowOrbitalControlNS17.call()

        theFew  = ns17s.first(3).select{|ns17| ns17["rt"] > 0 } + [synthetic, !LowOrbitals::ns17s().empty? ? orbital : nil].compact  # natural ordering
        theRest = ns17s.first(3).select{|ns17| ns17["rt"] == 0 } + ns17s.drop(3)                                                     # natural ordering

        theFew  = theFew.sort{|o1, o2| o1["rt"] <=> o2["rt"] }         # rt ordering
        
        if theFew[0]["isSynthetic"] then
            $SyntheticIsFront = true
            theRest0, theRest1 = theRest.partition { |ns17| ns17["rt"] == 0 } 
            theRest1 = theRest1.sort{|o1, o2| o1["rt"] <=> o2["rt"] }  # rt ordering
            theRest = theRest1 + theRest0
            return theRest.take(3) + theFew + theRest.drop(3)
        end
        
        if theFew[0]["isLowOrbital"] then
            $LowOrbitalIsFront = true
            los = LowOrbitals::ns17s()
            return los.take(3) + theFew + los.drop(3) + theRest
        end

        theFew + theRest
    end

    # UIServices::quarksNS16s()
    def self.quarksNS16s()
        UIServices::orderNS17s(Quarks::ns17s()).map{|ns17| ns17["ns16"] }
    end

    # UIServices::catalystNS16s()
    def self.catalystNS16s()
        isWorkTime = ([1,2,3,4,5].include?(Time.new.wday) and (9..16).to_a.include?(Time.new.hour) and !KeyValueStore::flagIsTrue(nil, "a2f220ce-e020-46d9-ba64-3938ca3b69d4:#{Utils::today()}"))
        if isWorkTime then
            return UIServices::waveLikeNS16s() + WorkInterface::ns16s() + UIServices::quarksNS16s()
        end
        UIServices::waveLikeNS16s() + UIServices::quarksNS16s()
    end

    # UIServices::catalystDisplayLoop()
    def self.catalystDisplayLoop()

        loop {

            Anniversaries::dailyBriefingIfNotDoneToday()

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
                announce = "(#{"%3d" % indx}) #{item["announce"]}"
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
                item = items[ordinal]
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
                Quarks::interactivelyIssueNewMarbleQuarkOrNull()
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

            if Interpreting::match("exit", command) then
                break
            end
        }
    end
end


