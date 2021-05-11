# encoding: UTF-8

$ListedNS16s = nil

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

    # UIServices::combine(agents, ns17s): Array[Agent]
    def self.combine(agents, ns17s)

        # agents with an empty "ns17s" array
        agents = agents.map{|agent| 
            agent["ns17s"] = []
            agent
        }

        # ----------------------------------------------------------

        # agent with populated "ns17s" from ns17s
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
        }

        # ----------------------------------------------------------

        agents = agents.select{ |agent| !agent["ns17s"].empty? }

        # agents with ordered ["ns17s"] according to the processing Style
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
        }

        # agents with ordered ["ns16s"]
        agents = agents.map{|agent|
            agent["ns16s"] = agent["ns17s"].map{|ns17| ns17["ns16"] }
            agent
        }

        # agents with a recovery time
        agents = agents.map{|agent| 
            agent["rt"] = BankExtended::stdRecoveredDailyTimeInHours(agent["uuid"])
            agent
        }

        agents.sort{|a1, a2| a1["rt"] <=> a2["rt"] }
    end

    # UIServices::quarksNS16s()
    def self.quarksNS16s()
        agentToNS16 = lambda {|agent|
            {
                "uuid"     => agent["uuid"],
                "announce" => "(#{"%5.3f" % agent["rt"]}) #{"[Air Traffic Control] #{agent["name"]}".green} (#{agent["ns17s"].size}) [#{agent["processingStyle"]}]",
            }
        }

        agents = UIServices::combine(AirTrafficControl::agents(), Quarks::ns17s())

        agents.first["ns16s"].first(3) + agents.map{|agent| agentToNS16.call(agent) } + agents.first["ns16s"].drop(3)
    end

    # UIServices::priorityFileNS16OrNull(filepath)
    def self.priorityFileNS16OrNull(filepath)
        raise "c2f47ddb-c278-4e03-b350-0a204040b224" if filepath.nil? # can happen because some of those filepath are unique string lookups
        filename = File.basename(filepath)
        contents = IO.read(filepath)
        return nil if contents.strip == ""
        hash1 = Digest::SHA1.file(filepath).hexdigest
        announce = "\n#{contents.strip.lines.map{|line| "      #{line}" }.join().green}"

        {
            "uuid"     => hash1,
            "announce" => announce,
            "access"    => lambda { 
                system("open '#{filepath}'")
            },
            "done"     => lambda { },
            "[]"       => lambda {
                contents = IO.read(filepath)
                return if contents.strip == ""
                hash2 = Digest::SHA1.file(filepath).hexdigest
                return if hash1 != hash2
                contents = SectionsType0141::applyNextTransformationToText(contents)
                File.open(filepath, "w"){|f| f.puts(contents)}
                next
            }
        }
    end

    # UIServices::getDocNetMorningNS16s()
    def self.getDocNetMorningNS16s()
        isWeekday = Utils::isWeekday()
        isDocNetTime = ((Time.new.hour >= 7) and ((isWeekday and Time.new.hour < 10) or (!isWeekday and Time.new.hour < 12)))
        return [] if !isDocNetTime
        [ UIServices::priorityFileNS16OrNull(Utils::locationByUniqueStringOrNull("ab25a8f8-0578")) ].compact
    end

    # UIServices::getPriorityNS16s(index)
    def self.getPriorityNS16s(index)
        [ UIServices::priorityFileNS16OrNull("/Users/pascal/Desktop/Priority (#{index}).txt") ].compact
    end

    # UIServices::catalystNS16s()
    def self.catalystNS16s()
        items = DetachedRunning::ns16s() + Calendar::ns16s() + UIServices::getPriorityNS16s(1) + UIServices::getDocNetMorningNS16s() + UIServices::waveLikeNS16s() + WorkInterface::ns16s() + UIServices::getPriorityNS16s(2) + UIServices::quarksNS16s()
        items.select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # UIServices::catalystDisplayLoop()
    def self.catalystDisplayLoop()

        loop {

            system("clear")

            status = Anniversaries::dailyBriefingIfNotDoneToday()
            next if status

            vspaceleft = Utils::screenHeight()-4

            items = UIServices::catalystNS16s()

            $ListedNS16s = items.clone

            puts ""
            vspaceleft = vspaceleft - 1

            items.each_with_index{|item, indx|
                announce = "(#{"%3d" % indx}) #{item["announce"]}"
                break if ((indx > 0) and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }

            puts "listing: .. (access top) | select <n> | start (<n>) | done (<n>) | / | new wave | new quark | new work item | no work today | new calendar item".yellow
            puts "top    : [] (Priority.txt) | ++ by an hour | + <weekday> | + <float> <datecode unit> | not today".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            next if command == ""

            # -- listing -----------------------------------------------------------------------------

            if Interpreting::match("..", command) then
                item = items[0]
                next if item.nil? 
                next if item["access"].nil?
                item["access"].call()
            end

            if Interpreting::match("select *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                next if item.nil?
                next if item["access"].nil?
                item["access"].call()
            end

            if Interpreting::match("access", command) then
                item = items[0]
                next if item.nil? 
                next if item["access"].nil?
                item["access"].call()
            end

            if Interpreting::match("start *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                next if item.nil?
                next if item["access"].nil?
                item["access"].call()
            end

            if Interpreting::match("done", command) then
                item = items[0]
                next if item.nil? 
                next if item["done"].nil?
                item["done"].call()
            end

            if Interpreting::match("done *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                next if item.nil?
                next if item["done"].nil?
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

            if Interpreting::match("new work item", command) then
                WorkInterface::interactvelyIssueNewItem()
            end

            if Interpreting::match("new calendar item", command) then
                Calendar::interactivelyIssueNewCalendarItem()
            end

            if Interpreting::match("no work today", command) then
                KeyValueStore::setFlagTrue(nil, "865cb030-537a-4af8-b1af-202cff383ea1:#{Utils::today()}")
            end

            # -- top -----------------------------------------------------------------------------

            if Interpreting::match("[]", command) then
                item = items[0]
                next if item.nil? 
                next if item["[]"].nil?
                item["[]"].call()
                next
            end

            if Interpreting::match("not today", command) then
                unixtime = Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone())
                DoNotShowUntil::setUnixtime(items[0]["uuid"], unixtime)
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

Thread.new {
    trace = lambda {|items|
        items.map{|item| item["uuid"] }.sort.join(";")
    }
    loop {
        sleep 60
        items = UIServices::catalystNS16s()
        if trace.call(UIServices::catalystNS16s()) != trace.call($ListedNS16s) then
            Utils::onScreenNotification("Catalyst", "New listing items")
        end
    }
}
