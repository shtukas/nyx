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

            ms.item("new quark", lambda { Quarks::interactivelyIssueNewElbramQuarkOrNull() })

            puts ""

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::waveLikeNS16s()
    def self.waveLikeNS16s()
        Anniversaries::ns16s() + Waves::ns16s()
    end

    # UIServices::orderQuarkNS17s(ns17s)
    def self.orderQuarkNS17s(ns17s)

        agents = AirTrafficControl::agents()

        agents = agents.map{|agent| 
            agent["ns17s"] = []
            agent
        } # agents with a n empty["ns17s"]

        agents = ns17s.reduce(agents){|ags, ns17|
            # we need to find the correct agent for this ns17, if we do not find it, we put it in the default agent
            agent = ags.select{|a| a["itemsuids"].include?(ns17["uuid"]) }.first
            if agent then
                ags.map{|a|
                    if a["uuid"] == agent["uuid"] then
                        a["ns17s"] << ns17
                    end
                    a
                }
            else
                ags.map{|a|
                    if "3AD70E36-826B-4958-95BF-02E12209C375" == a["uuid"] then
                        a["ns17s"] << ns17
                    end
                    a
                }
            end
        } # agent with populated "ns17s" from ns17s

        agents = agents.map{|agent|
            if !["Sequential", "FirstThreeCompeting", "AllCompetings"].include?(agent["processingStyle"]) then
                puts JSON.pretty_generate(agent)
                raise "5da5d984-7d27-49b1-946f-0780fefa0b71"
            end
            if agent["processingStyle"] == "Sequential" then
                # Nothing to do
            end
            if agent["processingStyle"] == "FirstThreeCompeting" then
                agent["ns17s"] = agent["ns17s"].first(3).sort{|x1, x2| x1["rt"] <=> x2["rt"] } + agent["ns17s"].drop(3)
            end
            if agent["processingStyle"] == "AllCompetings" then
                agent["ns17s"] = agent["ns17s"].sort{|x1, x2| x1["rt"] <=> x2["rt"] }
            end
            agent
        } # agents with ordered ["ns17s"] according to the processing Style

        agents = agents.map{|agent| 
            agent["rt"] = BankExtended::stdRecoveredDailyTimeInHours(agent["uuid"]) 
            agent
        } # agents with a recovery time

        agents = agents.map{|agent| 
            agent["rtx"] = agent["rt"] * agent["timeDilatation"]
            agent
        } # agents with a time dilated recovery time

        agents = agents.sort{|a1, a2| a1["rtx"] <=> a2["rtx"] }

        agents, agentsE = agents.partition{ |agent| !agent["ns17s"].empty? }

        agentToNS17 = lambda {|agent|
            agentNS16 = {
                "uuid"     => agent["uuid"],
                "announce" => "(#{"%5.3f" % agent["rt"]}) #{"[Air Traffic Control] #{agent["name"]}".green} (#{agent["ns17s"].size}) [#{agent["processingStyle"]}, #{agent["timeDilatation"]}]",
                "start"    => lambda { },
                "done"     => lambda { }
            }
            {
                "uuid"        => agentNS16["uuid"],
                "ns16"        => agentNS16,
                "rt"          => agent["rt"]
            }
        }

        agents.first["ns17s"].first(3) + agents.map{|agent| agentToNS17.call(agent) } + agentsE.map{|agent| agentToNS17.call(agent) } +  agents.first["ns17s"].drop(3) + agents.drop(1).map{|agent| agent["ns17s"] }.flatten
    end

    # UIServices::quarksNS16s()
    def self.quarksNS16s()
        UIServices::orderQuarkNS17s(Quarks::ns17s()).map{|ns17| ns17["ns16"] }
    end

    # UIServices::catalystNS16s()
    def self.catalystNS16s()
        isWeekday = ![6, 0].include?(Time.new.wday)
        isWorkTime = ([1,2,3,4,5].include?(Time.new.wday) and (9..16).to_a.include?(Time.new.hour) and !KeyValueStore::flagIsTrue(nil, "a2f220ce-e020-46d9-ba64-3938ca3b69d4:#{Utils::today()}"))
        return DetachedRunning::ns16s() + UIServices::waveLikeNS16s() + (isWorkTime ? WorkInterface::ns16s() : []) + (isWeekday ? [] : UIServices::quarksNS16s())
    end

    # UIServices::catalystDisplayLoop()
    def self.catalystDisplayLoop()

        loop {

            system("clear")

            if !KeyValueStore::flagIsTrue(nil, "ccc82794-58cd-4d32-94db-6918cbe1e0a3:#{Utils::today()}") then
                puts "Calendar review:"
                puts IO.read("/Users/pascal/Galaxy/Documents/Calendar/01 Calendar.txt").strip.green
                if LucilleCore::askQuestionAnswerAsBoolean("done ? : ") then
                    KeyValueStore::setFlagTrue(nil, "ccc82794-58cd-4d32-94db-6918cbe1e0a3:#{Utils::today()}")
                end
                next
            end

            Anniversaries::dailyBriefingIfNotDoneToday()

            vspaceleft = Utils::screenHeight()-4

            priorityFilepath = "/Users/pascal/Desktop/Priority.txt"
            priority = IO.read(priorityFilepath).strip
            priorityhash = Digest::SHA1.file(priorityFilepath).hexdigest

            if priority.size > 0 then
                puts "-- Priority.txt -----------------------"
                text = priority.lines.first(10).join().strip.green
                puts text
                vspaceleft = vspaceleft - Utils::verticalSize(text) - 1
            end

            if ![6, 0].include?(Time.new.wday) then
                puts "-- DocNet Directive -------------------".red
                puts "Until it's done we are completely focusing on DocNet".red
                vspaceleft = vspaceleft - 2
            end

            puts "-- listing ----------------------------"

            items = UIServices::catalystNS16s()
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }

            items.each_with_index{|item, indx|
                announce = "(#{"%3d" % indx}) #{item["announce"]}"
                break if ((indx > 0) and ((vspaceleft - Utils::verticalSize(announce)) < 0))
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
                Quarks::interactivelyIssueNewElbramQuarkOrNull()
            end

            if Interpreting::match("new work", command) then
                system("work new")
            end

            # -- top -----------------------------------------------------------------------------

            if Interpreting::match("[]", command) then
                # This prevents to run a [] order on a file which may have been manually changed after 
                # The display ran. 
                next if Digest::SHA1.file(priorityFilepath).hexdigest != priorityhash
                text = IO.read(priorityFilepath).strip
                if text.size > 0 then
                    text = SectionsType0141::applyNextTransformationToText(text)
                    File.open(priorityFilepath, "w"){|f| f.puts(text)}
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


