# encoding: UTF-8

class Cliques

    # Cliques::issueClique(description)
    def self.issueClique(description)
        return if description == "[root]" # enforcing the fact that there is only one [root].
        uuid = SecureRandom.uuid
        clique = {
            "uuid"     => uuid,
            "nyxNxSet" => "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5",
            "unixtime" => Time.new.to_f
        }
        Cliques::commitToDisk(clique)
        descriptionz = DescriptionZ::issue(description)
        Arrows::issue(clique, descriptionz)
        clique
    end

    # Cliques::commitToDisk(clique)
    def self.commitToDisk(clique)
        NyxObjects::put(clique)
    end

    # Cliques::issueCliqueInteractivelyOrNull()
    def self.issueCliqueInteractivelyOrNull()
        puts "making a new clique:"
        name1 = LucilleCore::askQuestionAnswerAsString("clique name: ")
        clique = Cliques::issueClique(name1)
        puts JSON.pretty_generate(clique)
        clique
    end

    # Cliques::cliqueToString(clique)
    def self.cliqueToString(clique)
        namex = Cliques::getCliqueDescriptionOrNull(clique) 
        "[clique] [#{clique["uuid"][0, 4]}] #{namex}"
    end

    # Cliques::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # Cliques::cliques()
    def self.cliques()
        NyxObjects::getSet("4ebd0da9-6fe4-442e-81b9-eda8343fc1e5")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Cliques::landing(clique)
    def self.landing(clique)
        loop {

            clique = Cliques::getOrNull(clique["uuid"])

            return if clique.nil? # could have been destroyed in a previous loop

            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule(false)
            # ----------------------------------------------------------
            # Clique Identity Information

            puts Cliques::cliqueToString(clique)
            puts ""

            puts "uuid: #{clique["uuid"]}"
            description = DescriptionZ::getLastDescriptionForSourceOrNull(clique)
            if description then
                puts "description: #{description}"
            end

            notetext = Notes::getMostRecentTextForSourceOrNull(clique)
            if notetext then
                puts "Note:"
                puts notetext.lines.map{|line| "    #{line}" }.join()
            end

            puts ""

            menuitems.item(
                "rename", 
                lambda{ 
                    description = Cliques::getCliqueDescriptionOrNull(clique)
                    description = Miscellaneous::editTextUsingTextmate(description).strip
                    descriptionz = DescriptionZ::issue(description)
                    Arrows::issue(clique, descriptionz)
                }
            )

            menuitems.item(
                "note (edit)", 
                lambda{ 
                    text = Notes::getMostRecentTextForSourceOrNull(clique) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    note = Notes::issue(text)
                    Arrows::issue(clique, note)
                }
            )

            menuitems.item(
                "clique (destroy)", 
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this clique ? ") then
                        NyxObjects::destroy(clique["uuid"])
                    end
                }
            )

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Contents

            puts "NSDataType2s:"

            # NSDataType2s
            Cliques::getCliqueNSDataType2sInTimeOrder(clique)
                .each{|ns2|
                    menuitems.item(
                        NSDataType2s::ns2ToString(ns2), 
                        lambda { NSDataType2s::landing(ns2) }
                    )
                }

            puts ""
            menuitems.item(
                "add new ns2", 
                lambda{
                    ns2 = NSDataType2s::issueNewNSDataType2Interactively()
                    Arrows::issue(clique, ns2)
                }
            )

            if Cliques::canShowDiveOperations(clique) then
                menuitems.item(
                    "graph maker: select multiple ns2 ; send to existing/new clique ; detach from this",
                    lambda {
                        ns2s = Arrows::getTargetsOfGivenSetsForSource(clique, ["6b240037-8f5f-4f52-841d-12106658171f"])
                        selectedNSDataType2s, _ = LucilleCore::selectZeroOrMore("ns2s", [], ns2s, toStringLambda = lambda{ |ns2| NSDataType2s::ns2ToString(ns2) })
                        return if selectedNSDataType2s.size == 0
                        puts "Now selecting/making the receiving clique"
                        LucilleCore::pressEnterToContinue()
                        c = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
                        return if c.nil?
                        puts "Making the new clique a target of this"
                        Arrows::issue(source, c)
                        puts "Linking ns2s to clique"
                        selectedNSDataType2s.each{|ns2| Arrows::issue(c, ns2) }
                        puts "Unlinking ns2s from (this)"
                        selectedNSDataType2s.each{|ns2| Arrows::remove(clique, ns2) }
                    }
                )
            end

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Navigation

            puts "Navigation:"

            if !Cliques::isRoot?(clique) then
                sources = Cliques::getCliqueNavigationSources(clique)
                if sources.size > 0 then
                    puts ""
                end
                sources.each{|c|
                    menuitems.item(
                        "source: #{Cliques::cliqueToString(c)}", 
                        lambda { Cliques::landing(c) }
                    )
                }
            end
            targets = Cliques::getCliqueNavigationTargets(clique)
            if targets.size > 0 then
                puts ""
            end
            targets.each{|c|
                menuitems.item(
                    "target: #{Cliques::cliqueToString(c)}", 
                    lambda { Cliques::landing(c) }
                )
            }
            puts ""
            if !Cliques::isRoot?(clique) then
                menuitems.item(
                    "add nagigation source", 
                    lambda { 
                        c = Cliques::selectCliqueFromExistingCliquesOrNull()
                        return if c.nil?
                        Arrows::issue(c, clique)
                    }
                )
            end
            menuitems.item(
                "add navigation target", 
                lambda { 
                    c = Cliques::selectCliqueFromExistingCliquesOrNull()
                    return if c.nil?
                    Arrows::issue(clique, c)
                }
            )
            if !Cliques::isRoot?(clique) then
                menuitems.item(
                    "remove navigation source", 
                    lambda { 
                        c = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", Cliques::getCliqueNavigationSources(clique), lambda{|c| Cliques::cliqueToString(c) })
                        return if c.nil?
                        Arrows::remove(c, clique)
                    }
                )
            end
            menuitems.item(
                "remove navigation target", 
                lambda { 
                    c = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", Cliques::getCliqueNavigationTargets(clique), lambda{|c| Cliques::cliqueToString(c) })
                    return if c.nil?
                    Arrows::remove(clique, c)
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

    # Cliques::getCliqueNavigationSources(clique)
    def self.getCliqueNavigationSources(clique)
        Arrows::getSourcesOfGivenSetsForTarget(clique, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
            .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"]}
    end

    # Cliques::getCliqueNavigationTargets(clique)
    def self.getCliqueNavigationTargets(clique)
        Arrows::getTargetsOfGivenSetsForSource(clique, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
        .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"]}
    end

    # Cliques::getCliqueNSDataType2sInTimeOrder(clique)
    def self.getCliqueNSDataType2sInTimeOrder(clique)
        Arrows::getTargetsOfGivenSetsForSource(clique, ["6b240037-8f5f-4f52-841d-12106658171f"])
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # Cliques::getRootClique()
    def self.getRootClique()
        Cliques::cliques()
            .select{|clique| Cliques::getCliqueDescriptionOrNull(clique) == "[root]" }
            .first
    end

    # Cliques::isRoot?(clique)
    def self.isRoot?(clique)
        Cliques::getCliqueDescriptionOrNull(clique) == "[root]"
    end

    # Cliques::canShowDiveOperations(clique)
    def self.canShowDiveOperations(clique)
        !Cliques::isRoot?(clique)
    end

    # Cliques::getCliqueDescriptionOrNull(clique)
    def self.getCliqueDescriptionOrNull(clique)
        DescriptionZ::getLastDescriptionForSourceOrNull(clique)
    end

    # Cliques::getCliqueReferenceDateTime(clique)
    def self.getCliqueReferenceDateTime(clique)
        datetime = DateTimeZ::getLastDateTimeISO8601ForSourceOrNull(clique)
        return datetime if datetime
        Time.at(clique["unixtime"]).utc.iso8601
    end

    # Cliques::getCliqueReferenceUnixtime(clique)
    def self.getCliqueReferenceUnixtime(clique)
        DateTime.parse(Cliques::getCliqueReferenceDateTime(clique)).to_time.to_f
    end

    # Cliques::selectCliqueFromExistingCliquesOrNull()
    def self.selectCliqueFromExistingCliquesOrNull()
        cliquestrings = Cliques::cliques().map{|clique| Cliques::cliqueToString(clique) }
        cliquestring = Miscellaneous::chooseALinePecoStyle("clique:", [""]+cliquestrings)
        return nil if cliquestring == ""
        Cliques::cliques()
            .select{|clique| Cliques::cliqueToString(clique) == cliquestring }
            .first
    end

    # Cliques::selectCliqueFromExistingOrCreateOneOrNull()
    def self.selectCliqueFromExistingOrCreateOneOrNull()
        puts "-> You are selecting a clique (possibly will create one)"
        LucilleCore::pressEnterToContinue()
        clique = Cliques::selectCliqueFromExistingCliquesOrNull()
        return clique if clique
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to make a new clique and return it ? ") then
            return Cliques::issueCliqueInteractivelyOrNull()
        end
        nil
    end

    # Cliques::selectZeroOrMoreCliquesExistingOrCreated()
    def self.selectZeroOrMoreCliquesExistingOrCreated()
        clique = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
        return [] if clique.nil?
        cliques = [ clique ]
        loop {
            break if !LucilleCore::askQuestionAnswerAsBoolean("select more cliques ? ")
            clique = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
            break if clique.nil?
            cliques << clique
        }
        cliques
    end

    # Cliques::getLastActivityUnixtime(clique)
    def self.getLastActivityUnixtime(clique)
        times1 = [ Cliques::getCliqueReferenceUnixtime(clique) ] 
        times2 = Arrows::getTargetsOfGivenSetsForSource(clique, ["6b240037-8f5f-4f52-841d-12106658171f"])
                    .map{|object| object["unixtime"] }
        (times1+times2).max
    end

    # Cliques::cliquesListingAndLanding()
    def self.cliquesListingAndLanding()
        loop {
            ms = LCoreMenuItemsNX1.new()

            Cliques::cliques()
                .sort{|q1, q2| q1["unixtime"]<=>q2["unixtime"] }
                .each{|clique|
                    ms.item(
                        Cliques::cliqueToString(clique), 
                        lambda{ Cliques::landing(clique) }
                    )
                }
            status = ms.prompt()
            break if !status
        }
    end

    # Cliques::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        Cliques::cliques()
            .select{|clique| 
                [ 
                    clique["uuid"].downcase.include?(pattern.downcase),
                    Cliques::cliqueToString(clique).downcase.include?(pattern.downcase)
                ].any?
            }
            .map{|clique|
                {
                    "description"   => Cliques::cliqueToString(clique),
                    "referencetime" => Cliques::getCliqueReferenceUnixtime(clique),
                    "dive"          => lambda{ Cliques::landing(clique) }
                }
            }
    end

    # Cliques::mergeCliques(clique1, clique2)
    def self.mergeCliques(clique1, clique2)
        # We take everything connected to clique2, link that to clique1 and delete clique2
        Arrows::getTargetsOfGivenSetsForSource(clique2, ["6b240037-8f5f-4f52-841d-12106658171f"])
            .each{|ns2| Arrows::issue(clique1, ns2) }
        NyxObjects::destroy(clique2["uuid"])
    end

    # Cliques::interactivelySelectTwoCliquesAndMerge()
    def self.interactivelySelectTwoCliquesAndMerge()
        puts "Select clique #1"
        LucilleCore::pressEnterToContinue()
        clique1 = Cliques::selectCliqueFromExistingCliquesOrNull()

        puts "Select clique #2"
        LucilleCore::pressEnterToContinue()
        clique2 = Cliques::selectCliqueFromExistingCliquesOrNull()

        if clique1["uuid"] == clique2["uuid"] then
            puts "You hace selected the same clique twice. Aborting operation."
            LucilleCore::pressEnterToContinue()
            return
        end

        puts "Merging:"
        puts "    - #{Cliques::cliqueToString(clique1)}"
        puts "    - #{Cliques::cliqueToString(clique2)}"
        LucilleCore::pressEnterToContinue()

        Cliques::mergeCliques(clique1, clique2)
    end

    # Cliques::selectExistingOrNewCliqueFromRootNavigationOrNull(clique = nil)
    def self.selectExistingOrNewCliqueFromRootNavigationOrNull(clique = nil)
        if clique.nil? then
            return Cliques::selectExistingOrNewCliqueFromRootNavigationOrNull(Cliques::getRootClique())
        end
        system("clear")
        puts Cliques::cliqueToString(clique)
        puts ""

        options = []

        options << ["select and return current"]
        Cliques::getCliqueNavigationTargets(clique).each{|c|
            options << ["select and return this target", c]
        }
        Cliques::getCliqueNavigationTargets(clique).each{|c|
            options << ["search into", c]
        }
        options << ["make new target clique for current and return that"]
        options << ["back to source"]
        options << ["try peco style choosing clique by name"]
        options << ["abort search and return null"]

        optionToString = lambda {|option|
            if option.size == 1 then
                return option[0]
            end
            if option[0] == "select and return this target" then
                return "select and return this target: #{Cliques::cliqueToString(option[1])}"
            end
            if option[0] == "search into" then
                return "search into: #{Cliques::cliqueToString(option[1])}"
            end
        }

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options, optionToString)
        if option.nil? then
            return Cliques::selectExistingOrNewCliqueFromRootNavigationOrNull(clique)
        end
        if option[0] == "select and return current" then
            return clique
        end
        if option[0] == "select and return this target" then
            return option[1]
        end
        if option[0] == "search into" then
            resultSearch = Cliques::selectExistingOrNewCliqueFromRootNavigationOrNull(option[1])
            if resultSearch == "back to source" then
                return Cliques::selectExistingOrNewCliqueFromRootNavigationOrNull(clique)
            end
            return resultSearch # which can be a clique or nil
        end
        if option[0] == "make new target clique for current and return that" then
            target = Cliques::issueCliqueInteractivelyOrNull()
            if target.nil? then
                return Cliques::selectExistingOrNewCliqueFromRootNavigationOrNull(clique)
            end
            Arrows::make(clique, target)
            return target
        end
        if option[0] == "back to source" then
            return "back to source"
        end
        if option[0] == "try peco style choosing clique by name" then
            selection = Cliques::selectCliqueFromExistingCliquesOrNull()
            return Cliques::selectExistingOrNewCliqueFromRootNavigationOrNull(clique) if selection.nil?
            return Cliques::selectExistingOrNewCliqueFromRootNavigationOrNull(selection)
        end
        if option[0] == "abort search and return null" then
            return nil
        end
        raise "[43fd640a-b070-46b8] #{JSON.generate(option)}"
    end
end
