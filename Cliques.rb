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
        DescriptionZ::issue(uuid, description)
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

    # Cliques::dive(clique)
    def self.dive(clique)
        loop {

            clique = NyxObjects::getOrNull(clique["uuid"])

            return if clique.nil? # could have been destroyed in a previous loop

            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule(false)
            # ----------------------------------------------------------
            # Clique Identity Information

            puts Cliques::cliqueToString(clique)
            puts "uuid: #{clique["uuid"]}"
            description = DescriptionZ::getLastDescriptionForTargetOrNull(clique["uuid"])
            if description then
                puts "description: #{description}"
            end

            notetext = Notes::getMostRecentTextForTargetOrNull(clique["uuid"])
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
                    DescriptionZ::issue(clique["uuid"], description)
                }
            )

            menuitems.item(
                "note (edit)", 
                lambda{ 
                    text = Notes::getMostRecentTextForTargetOrNull(clique["uuid"]) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    Notes::issue(clique["uuid"], text)
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

            puts "Cubes:"

            # Cubes
            Cliques::getCliqueCubesInTimeOrder(clique)
                .each{|cube|
                    menuitems.item(
                        Cubes::cubeToString(cube), 
                        lambda { Cubes::dive(cube) }
                    )
                }

            puts ""
            menuitems.item(
                "add new cube", 
                lambda{
                    cube = Cubes::issueNewCubeInteractively()
                    Arrows::issue(clique, cube)
                }
            )

            if Cliques::canShowDiveOperations(clique) then
                menuitems.item(
                    "graph maker: select multiple cube ; send to existing/new clique ; detach from this",
                    lambda {
                        cubes = Arrows::getTargetOfGivenSetsForSource(clique, ["6b240037-8f5f-4f52-841d-12106658171f"])
                        selectedCubes, _ = LucilleCore::selectZeroOrMore("cubes", [], cubes, toStringLambda = lambda{ |cube| Cubes::cubeToString(cube) })
                        return if selectedCubes.size == 0
                        puts "Now selecting/making the receiving clique"
                        LucilleCore::pressEnterToContinue()
                        c = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
                        return if c.nil?
                        puts "Making the new clique a target of this"
                        Arrows::issue(source, c)
                        puts "Linking cubes to clique"
                        selectedCubes.each{|cube| Arrows::issue(c, cube) }
                        puts "Unlinking cubes from (this)"
                        selectedCubes.each{|cube| Arrows::removeArrow(clique, cube) }
                    }
                )
            end

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Navigation

            puts "Navigation:"

            if !Cliques::isRoot?(clique) then
                Cliques::getCliqueNavigationSources(clique).each{|c|
                    menuitems.item(
                        "source: #{Cliques::cliqueToString(c)}", 
                        lambda { Cliques::landing(c) }
                    )
                }
            end
            Cliques::getCliqueNavigationTargets(clique).each{|c|
                menuitems.item(
                    "target: #{Cliques::cliqueToString(c)}", 
                    lambda { Cliques::landing(c) }
                )
            }
            puts ""
            if !Cliques::isRoot?(clique) then
                menuitems.item(
                    "select clique for sourcing", 
                    lambda { 
                        c = Cliques::selectCliqueFromExistingCliquesOrNull()
                        return if c.nil?
                        Arrows::issue(c, clique)
                    }
                )
            end
            menuitems.item(
                "select clique for targeting", 
                lambda { 
                    c = Cliques::selectCliqueFromExistingCliquesOrNull()
                    return if c.nil?
                    Arrows::issue(clique, c)
                }
            )
            if !Cliques::isRoot?(clique) then
                menuitems.item(
                    "remove clique from sourcing", 
                    lambda { 
                        c = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", Cliques::getCliqueNavigationSources(clique), lambda{|c| Cliques::cliqueToString(c) })
                        return if c.nil?
                        Arrows::removeArrow(c, clique)
                    }
                )
            end
            menuitems.item(
                "remove clique from targeting", 
                lambda { 
                    c = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", Cliques::getCliqueNavigationTargets(clique), lambda{|c| Cliques::cliqueToString(c) })
                    return if c.nil?
                    Arrows::removeArrow(clique, c)
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

    # Cliques::quickDataAccess(clique)
    def self.quickDataAccess(clique)
        cubes = Cliques::getCliqueCubesInTimeOrder(clique)
        if cubes.size == 0 then
            puts "Could not find cubes for clique: #{Cliques::cliqueToString(clique)}"
            puts "Going to dive into it"
            LucilleCore::pressEnterToContinue()
            Cliques::dive(clique)
            return
        end
        if cubes.size == 1 then
            Cubes::landing(cubes[0])
            return
        end

        loop {
            system("clear")
            puts Cliques::cliqueToString(clique)
            puts ""
            cube = LucilleCore::selectEntityFromListOfEntitiesOrNull("cube", cubes, lambda{|cube| Cubes::cubeToString(cube) })
            break if cube.nil?
            Cubes::landing(cube)
        }
    end

    # Cliques::landing(clique)
    def self.landing(clique)
        loop {
            system("clear")
            puts Cliques::cliqueToString(clique)
            puts ""
            menuitems = LCoreMenuItemsNX1.new()
            menuitems.item(
                "quick data access",
                lambda { Cliques::quickDataAccess(clique) }
            )
            menuitems.item(
                "dive",
                lambda { Cliques::dive(clique) }
            )
            puts ""
            Cliques::getCliqueNavigationSources(clique)
                .each{|c|
                    menuitems.item(
                        "navigation source: #{Cliques::cliqueToString(c)}", 
                        lambda { Cliques::landing(c) }
                    )
                }
            Cliques::getCliqueNavigationTargets(clique)
                .each{|c|
                    menuitems.item(
                        "navigation target: #{Cliques::cliqueToString(c)}", 
                        lambda { Cliques::landing(c) }
                    )
                }
            puts ""
            status = menuitems.prompt()
            break if !status
        }
    end

    # ---------------------------------------------------

    # Cliques::getCliqueNavigationSources(clique)
    def self.getCliqueNavigationSources(clique)
        Arrows::getSourceOfGivenSetsForTarget(clique, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
            .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"]}
    end

    # Cliques::getCliqueNavigationTargets(clique)
    def self.getCliqueNavigationTargets(clique)
        Arrows::getTargetOfGivenSetsForSource(clique, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
        .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"]}
    end

    # Cliques::getCliqueCubesInTimeOrder(clique)
    def self.getCliqueCubesInTimeOrder(clique)
        Arrows::getTargetOfGivenSetsForSource(clique, ["6b240037-8f5f-4f52-841d-12106658171f"])
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
        descriptionzs = DescriptionZ::getDescriptionZsForTargetInTimeOrder(clique["uuid"])
        return nil if descriptionzs.empty?
        descriptionzs.last["description"]
    end

    # Cliques::getCliqueReferenceDateTime(clique)
    def self.getCliqueReferenceDateTime(clique)
        datetimezs = DateTimeZ::getDateTimeZsForTargetInTimeOrder(clique["uuid"])
        return Time.at(clique["unixtime"]).utc.iso8601 if datetimezs.empty?
        datetimezs.last["datetimeISO8601"]
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
        times2 = Arrows::getTargetOfGivenSetsForSource(clique, ["6b240037-8f5f-4f52-841d-12106658171f"])
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
        Arrows::getTargetOfGivenSetsForSource(clique2, ["6b240037-8f5f-4f52-841d-12106658171f"])
            .each{|cube| Arrows::issue(clique1, cube) }
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
end
