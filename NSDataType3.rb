# encoding: UTF-8

class NSDataType3

    # NSDataType3::issueNSDataType3(description)
    def self.issueNSDataType3(description)
        return if description == "[root]" # enforcing the fact that there is only one [root].
        uuid = SecureRandom.uuid
        ns3 = {
            "uuid"     => uuid,
            "nyxNxSet" => "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5",
            "unixtime" => Time.new.to_f
        }
        NSDataType3::commitToDisk(ns3)
        descriptionz = DescriptionZ::issue(description)
        Arrows::issue(ns3, descriptionz)
        ns3
    end

    # NSDataType3::commitToDisk(ns3)
    def self.commitToDisk(ns3)
        NyxObjects::put(ns3)
    end

    # NSDataType3::issueNSDataType3InteractivelyOrNull()
    def self.issueNSDataType3InteractivelyOrNull()
        puts "making a new ns3:"
        name1 = LucilleCore::askQuestionAnswerAsString("ns3 name: ")
        ns3 = NSDataType3::issueNSDataType3(name1)
        puts JSON.pretty_generate(ns3)
        ns3
    end

    # NSDataType3::ns3ToString(ns3)
    def self.ns3ToString(ns3)
        namex = NSDataType3::getNSDataType3DescriptionOrNull(ns3) 
        "[ns3] [#{ns3["uuid"][0, 4]}] #{namex}"
    end

    # NSDataType3::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataType3::ns3s()
    def self.ns3s()
        NyxObjects::getSet("4ebd0da9-6fe4-442e-81b9-eda8343fc1e5")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # NSDataType3::landing(ns3)
    def self.landing(ns3)
        loop {

            ns3 = NSDataType3::getOrNull(ns3["uuid"])

            return if ns3.nil? # could have been destroyed in a previous loop

            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule(false)
            # ----------------------------------------------------------
            # NSDataType3 Identity Information

            puts NSDataType3::ns3ToString(ns3)
            puts ""

            puts "uuid: #{ns3["uuid"]}"
            description = DescriptionZ::getLastDescriptionForSourceOrNull(ns3)
            if description then
                puts "description: #{description}"
            end

            notetext = Notes::getMostRecentTextForSourceOrNull(ns3)
            if notetext then
                puts "Note:"
                puts notetext.lines.map{|line| "    #{line}" }.join()
            end

            puts ""

            menuitems.item(
                "rename", 
                lambda{ 
                    description = NSDataType3::getNSDataType3DescriptionOrNull(ns3)
                    description = Miscellaneous::editTextUsingTextmate(description).strip
                    descriptionz = DescriptionZ::issue(description)
                    Arrows::issue(ns3, descriptionz)
                }
            )

            menuitems.item(
                "note (edit)", 
                lambda{ 
                    text = Notes::getMostRecentTextForSourceOrNull(ns3) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    note = Notes::issue(text)
                    Arrows::issue(ns3, note)
                }
            )

            menuitems.item(
                "ns3 (destroy)", 
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this ns3 ? ") then
                        NyxObjects::destroy(ns3["uuid"])
                    end
                }
            )

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Contents

            puts "NSDataType2:"

            # NSDataType2
            NSDataType3::getNSDataType3NSDataType2InTimeOrder(ns3)
                .each{|ns2|
                    menuitems.item(
                        NSDataType2::ns2ToString(ns2), 
                        lambda { NSDataType2::landing(ns2) }
                    )
                }

            puts ""
            menuitems.item(
                "add new ns2", 
                lambda{
                    ns2 = NSDataType2::issueNewNSDataType2Interactively()
                    Arrows::issue(ns3, ns2)
                }
            )

            if NSDataType3::canShowDiveOperations(ns3) then
                menuitems.item(
                    "graph maker: select multiple ns2 ; send to existing/new ns3 ; detach from this",
                    lambda {
                        ns2s = Arrows::getTargetsOfGivenSetsForSource(ns3, ["6b240037-8f5f-4f52-841d-12106658171f"])
                        selectedNSDataType2, _ = LucilleCore::selectZeroOrMore("ns2s", [], ns2s, toStringLambda = lambda{ |ns2| NSDataType2::ns2ToString(ns2) })
                        return if selectedNSDataType2.size == 0
                        puts "Now selecting/making the receiving ns3"
                        LucilleCore::pressEnterToContinue()
                        c = NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull()
                        return if c.nil?
                        puts "Making the new ns3 a target of this"
                        Arrows::issue(source, c)
                        puts "Linking ns2s to ns3"
                        selectedNSDataType2.each{|ns2| Arrows::issue(c, ns2) }
                        puts "Unlinking ns2s from (this)"
                        selectedNSDataType2.each{|ns2| Arrows::remove(ns3, ns2) }
                    }
                )
            end

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Navigation

            puts "Navigation:"

            if !NSDataType3::isRoot?(ns3) then
                sources = NSDataType3::getNSDataType3NavigationSources(ns3)
                if sources.size > 0 then
                    puts ""
                end
                sources.each{|c|
                    menuitems.item(
                        "source: #{NSDataType3::ns3ToString(c)}", 
                        lambda { NSDataType3::landing(c) }
                    )
                }
            end
            targets = NSDataType3::getNSDataType3NavigationTargets(ns3)
            if targets.size > 0 then
                puts ""
            end
            targets.each{|c|
                menuitems.item(
                    "target: #{NSDataType3::ns3ToString(c)}", 
                    lambda { NSDataType3::landing(c) }
                )
            }
            puts ""
            if !NSDataType3::isRoot?(ns3) then
                menuitems.item(
                    "add nagigation source", 
                    lambda { 
                        c = NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull()
                        return if c.nil?
                        Arrows::issue(c, ns3)
                    }
                )
            end
            menuitems.item(
                "add navigation target", 
                lambda { 
                    c = NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull()
                    return if c.nil?
                    Arrows::issue(ns3, c)
                }
            )
            if !NSDataType3::isRoot?(ns3) then
                menuitems.item(
                    "remove navigation source", 
                    lambda { 
                        c = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns3", NSDataType3::getNSDataType3NavigationSources(ns3), lambda{|c| NSDataType3::ns3ToString(c) })
                        return if c.nil?
                        Arrows::remove(c, ns3)
                    }
                )
            end
            menuitems.item(
                "remove navigation target", 
                lambda { 
                    c = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns3", NSDataType3::getNSDataType3NavigationTargets(ns3), lambda{|c| NSDataType3::ns3ToString(c) })
                    return if c.nil?
                    Arrows::remove(ns3, c)
                }
            )
            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Operations

            menuitems.item(
                "/", 
                lambda { DataPortalUI::dataPortalFront() }
            )

            Miscellaneous::horizontalRule(true)

            status = menuitems.prompt()
            break if !status
        }
    end

    # ---------------------------------------------------

    # NSDataType3::getNSDataType3NavigationSources(ns3)
    def self.getNSDataType3NavigationSources(ns3)
        Arrows::getSourcesOfGivenSetsForTarget(ns3, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
            .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"]}
    end

    # NSDataType3::getNSDataType3NavigationTargets(ns3)
    def self.getNSDataType3NavigationTargets(ns3)
        Arrows::getTargetsOfGivenSetsForSource(ns3, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
        .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"]}
    end

    # NSDataType3::getNSDataType3NSDataType2InTimeOrder(ns3)
    def self.getNSDataType3NSDataType2InTimeOrder(ns3)
        Arrows::getTargetsOfGivenSetsForSource(ns3, ["6b240037-8f5f-4f52-841d-12106658171f"])
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # NSDataType3::getRootNSDataType3()
    def self.getRootNSDataType3()
        NSDataType3::ns3s()
            .select{|ns3| NSDataType3::getNSDataType3DescriptionOrNull(ns3) == "[root]" }
            .first
    end

    # NSDataType3::getAwaitingCurationNSDataType3()
    def self.getAwaitingCurationNSDataType3()
        NSDataType3::ns3s()
            .select{|ns3| NSDataType3::getNSDataType3DescriptionOrNull(ns3) == "[AwaitingCuration]" }
            .first
    end

    # NSDataType3::isRoot?(ns3)
    def self.isRoot?(ns3)
        NSDataType3::getNSDataType3DescriptionOrNull(ns3) == "[root]"
    end

    # NSDataType3::canShowDiveOperations(ns3)
    def self.canShowDiveOperations(ns3)
        !NSDataType3::isRoot?(ns3)
    end

    # NSDataType3::getNSDataType3DescriptionOrNull(ns3)
    def self.getNSDataType3DescriptionOrNull(ns3)
        DescriptionZ::getLastDescriptionForSourceOrNull(ns3)
    end

    # NSDataType3::getNSDataType3ReferenceDateTime(ns3)
    def self.getNSDataType3ReferenceDateTime(ns3)
        datetime = DateTimeZ::getLastDateTimeISO8601ForSourceOrNull(ns3)
        return datetime if datetime
        Time.at(ns3["unixtime"]).utc.iso8601
    end

    # NSDataType3::getNSDataType3ReferenceUnixtime(ns3)
    def self.getNSDataType3ReferenceUnixtime(ns3)
        DateTime.parse(NSDataType3::getNSDataType3ReferenceDateTime(ns3)).to_time.to_f
    end

    # NSDataType3::getLastActivityUnixtime(ns3)
    def self.getLastActivityUnixtime(ns3)
        times1 = [ NSDataType3::getNSDataType3ReferenceUnixtime(ns3) ] 
        times2 = Arrows::getTargetsOfGivenSetsForSource(ns3, ["6b240037-8f5f-4f52-841d-12106658171f"])
                    .map{|object| object["unixtime"] }
        (times1+times2).max
    end

    # NSDataType3::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataType3::ns3s()
            .select{|ns3| 
                [ 
                    ns3["uuid"].downcase.include?(pattern.downcase),
                    NSDataType3::ns3ToString(ns3).downcase.include?(pattern.downcase)
                ].any?
            }
            .map{|ns3|
                {
                    "description"   => NSDataType3::ns3ToString(ns3),
                    "referencetime" => NSDataType3::getNSDataType3ReferenceUnixtime(ns3),
                    "dive"          => lambda{ NSDataType3::landing(ns3) }
                }
            }
    end

    # NSDataType3::mergeNSDataType3s(ns31, ns32)
    def self.mergeNSDataType3s(ns31, ns32)
        # We take everything connected to ns32, link that to ns31 and delete ns32
        Arrows::getTargetsOfGivenSetsForSource(ns32, ["6b240037-8f5f-4f52-841d-12106658171f"])
            .each{|ns2| Arrows::issue(ns31, ns2) }
        NyxObjects::destroy(ns32["uuid"])
    end

    # NSDataType3::interactivelySelectTwoNSDataType3sAndMerge()
    def self.interactivelySelectTwoNSDataType3sAndMerge()
        puts "Select ns3 #1"
        LucilleCore::pressEnterToContinue()
        ns31 = NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull()

        puts "Select ns3 #2"
        LucilleCore::pressEnterToContinue()
        ns32 = NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull()

        if ns31["uuid"] == ns32["uuid"] then
            puts "You hace selected the same ns3 twice. Aborting operation."
            LucilleCore::pressEnterToContinue()
            return
        end

        puts "Merging:"
        puts "    - #{NSDataType3::ns3ToString(ns31)}"
        puts "    - #{NSDataType3::ns3ToString(ns32)}"
        LucilleCore::pressEnterToContinue()

        NSDataType3::mergeNSDataType3s(ns31, ns32)
    end

    # NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull(ns3 = nil)
    def self.selectExistingOrNewNSDataType3FromRootNavigationOrNull(ns3 = nil)
        if ns3.nil? then
            return NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull(NSDataType3::getRootNSDataType3())
        end
        system("clear")
        puts NSDataType3::ns3ToString(ns3)
        puts ""

        options = []

        options << ["select and return current"]
        NSDataType3::getNSDataType3NavigationTargets(ns3).each{|c|
            options << ["select and return this target", c]
        }
        NSDataType3::getNSDataType3NavigationTargets(ns3).each{|c|
            options << ["search into", c]
        }
        options << ["make new target ns3 for current and move to that"]
        options << ["back to source"]
        options << ["abort search and return null"]

        optionToString = lambda {|option|
            if option.size == 1 then
                return option[0]
            end
            if option[0] == "select and return this target" then
                return "select and return this target: #{NSDataType3::ns3ToString(option[1])}"
            end
            if option[0] == "search into" then
                return "search into: #{NSDataType3::ns3ToString(option[1])}"
            end
        }

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options, optionToString)
        if option.nil? then
            return NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull(ns3)
        end
        if option[0] == "select and return current" then
            return ns3
        end
        if option[0] == "select and return this target" then
            return option[1]
        end
        if option[0] == "search into" then
            resultSearch = NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull(option[1])
            if resultSearch == "back to source" then
                return NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull(ns3)
            end
            return resultSearch # which can be a ns3 or nil
        end
        if option[0] == "make new target ns3 for current and move to that" then
            target = NSDataType3::issueNSDataType3InteractivelyOrNull()
            if target.nil? then
                return NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull(ns3)
            end
            Arrows::make(ns3, target)
            return NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull(target)
        end
        if option[0] == "back to source" then
            return "back to source"
        end
        if option[0] == "abort search and return null" then
            return nil
        end
        raise "[43fd640a-b070-46b8] #{JSON.generate(option)}"
    end
end
