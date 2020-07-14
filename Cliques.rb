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

    # Cliques::cliqueDive(clique)
    def self.cliqueDive(clique)
        loop {

            clique = NyxObjects::getOrNull(clique["uuid"])

            return if clique.nil? # could have been destroyed in a previous loop

            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule(false)
            # ----------------------------------------------------------
            # Clique Identity Information

            puts "Clique:"

            DescriptionZ::getForTargetUUIDInTimeOrder(clique["uuid"])
                .last(1)
                .each{|descriptionz|
                    puts "    description: #{descriptionz["description"]}"
                }

            puts "    uuid: #{clique["uuid"]}"

            notetext = Notes::getMostRecentTextForTargetOrNull(clique["uuid"])

            if notetext then
                puts "Note:"
                puts notetext.lines.map{|line| "    #{line}" }.join()
            end

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Contents

            puts "Contents"

            # Quarks
            Bosons::getQuarksForClique(clique)
                .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
                .each{|quark|
                    menuitems.item(
                        Quarks::quarkToString(quark), 
                        lambda { Quarks::quarkDive(quark) }
                    )
                }

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Navigation

            puts "Navigation:"

            if !Cliques::isRoot?(clique) then

                puts "Sources:"
                TaxonomyArrows::getSourcesForTarget(clique).each{|c|
                    # Targets can be anything but for the moment they are just cliques
                    menuitems.item(
                        Cliques::cliqueToString(c), 
                        lambda { Cliques::cliqueDive(c) }
                    )
                }

            end

            puts "Targets:"
            TaxonomyArrows::getTargetsForSource(clique).each{|c|
                # Targets can be anything but for the moment they are just cliques
                menuitems.item(
                    Cliques::cliqueToString(c), 
                    lambda { Cliques::cliqueDive(c) }
                )
            }

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Operations

            puts "Clique Operations:"

            if Cliques::canShowDiveOperations(clique) then

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
                    "quark (add new)", 
                    lambda{
                        quark = Quarks::issueNewQuarkInteractivelyOrNull()
                        return if quark.nil?
                        Bosons::issue(clique, quark)
                        Quarks::issueZeroOrMoreQuarkTagsForQuarkInteractively(quark)
                    }
                )

                menuitems.item(
                    "graph maker: select multiple quark ; send to existing/new clique ; detach from this",
                    lambda {
                        quarks = Bosons::getQuarksForClique(clique)
                        selectedQuarks, _ = LucilleCore::selectZeroOrMore("quarks", [], quarks, toStringLambda = lambda{ |quark| Quarks::quarkToString(quark) })
                        return if selectedQuarks.size == 0
                        puts "Now selecting/making the receiving clique"
                        LucilleCore::pressEnterToContinue()
                        c = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
                        return if c.nil?
                        puts "Making the new clique a target of this"
                        TaxonomyArrows::issue(source, c)
                        puts "Linking quarks to clique"
                        selectedQuarks.each{|quark| Bosons::issue(c, quark) }
                        puts "Unlinking quarks from (this)"
                        selectedQuarks.each{|quark| Bosons::destroy(clique, quark) }
                    }
                )

                menuitems.item(
                    "select clique for targeting", 
                    lambda { 
                        c = Cliques::selectCliqueFromExistingCliquesOrNull()
                        return if c.nil?
                        TaxonomyArrows::issue(clique, c)
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

            end

            menuitems.item(
                "/", 
                lambda { DataPortalUI::dataPortalFront() }
            )

            Miscellaneous::horizontalRule(true)

            status = menuitems.prompt()
            break if !status
        }
    end

    # Cliques::cliqueNavigationView(clique)
    def self.cliqueNavigationView(clique)
        loop {

            clique = NyxObjects::getOrNull(clique["uuid"])

            return if clique.nil? # could have been destroyed in a previous loop

            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule(false)
            # ----------------------------------------------------------
            # Clique Identity Information

            puts "uuid: #{clique["uuid"]}"

            DescriptionZ::getForTargetUUIDInTimeOrder(clique["uuid"])
                .last(1)
                .each{|descriptionz|
                    puts "description: #{descriptionz["description"]}"
                }

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Navigation

            puts "Navigation:"

            if !Cliques::isRoot?(clique) then

                puts ""
                puts "Sources:"
                TaxonomyArrows::getSourcesForTarget(clique)
                    .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"]}
                    .each{|c|
                        # Targets can be anything but for the moment they are just cliques
                        menuitems.item(
                            Cliques::cliqueToString(c), 
                            lambda { Cliques::cliqueNavigationView(c) }
                        )
                    }

            end

            puts ""
            puts "Targets:"
            TaxonomyArrows::getTargetsForSource(clique)
                .sort{|c1, c2| c1["unixtime"] <=> c2["unixtime"]}
                .each{|c|
                    # Targets can be anything but for the moment they are just cliques
                    menuitems.item(
                        Cliques::cliqueToString(c), 
                        lambda { Cliques::cliqueNavigationView(c) }
                    )
                }

            Miscellaneous::horizontalRule(true)

            TaxonomyArrows::getSourcesForTarget(clique).each{|c|
                # Targets can be anything but for the moment they are just cliques
                menuitems.item(
                    "Dive into clique", 
                    lambda { Cliques::cliqueDive(clique) }
                )
            }


            Miscellaneous::horizontalRule(true)

            status = menuitems.prompt()
            break if !status
        }
    end

    # ---------------------------------------------------

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
        descriptionzs = DescriptionZ::getForTargetUUIDInTimeOrder(clique["uuid"])
        return nil if descriptionzs.empty?
        descriptionzs.last["description"]
    end

    # Cliques::getCliqueReferenceDateTime(clique)
    def self.getCliqueReferenceDateTime(clique)
        datetimezs = DateTimeZ::getForTargetUUIDInTimeOrder(clique["uuid"])
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

    # Cliques::selectFromExistingCliquesAndDive()
    def self.selectFromExistingCliquesAndDive()
        clique = Cliques::selectCliqueFromExistingCliquesOrNull()
        return if clique.nil?
        Cliques::cliqueDive(clique)
    end

    # Cliques::getLastActivityUnixtime(clique)
    def self.getLastActivityUnixtime(clique)
        times = [ Cliques::getCliqueReferenceUnixtime(clique) ] + Bosons::getQuarksForClique(clique).map{|object| object["unixtime"] }
        times.max
    end

    # Cliques::cliquesListingAndDive()
    def self.cliquesListingAndDive()
        loop {
            ms = LCoreMenuItemsNX1.new()

            Cliques::cliques()
                .sort{|q1, q2| q1["unixtime"]<=>q2["unixtime"] }
                .each{|clique|
                    ms.item(
                        Cliques::cliqueToString(clique), 
                        lambda{ Cliques::cliqueDive(clique) }
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
                    "dive"          => lambda{ Cliques::cliqueDive(clique) }
                }
            }
    end

    # Cliques::mergeCliques(clique1, clique2)
    def self.mergeCliques(clique1, clique2)
        # We take everything connected to clique2, link that to clique1 and delete clique2
        Bosons::getQuarksForClique(clique2)
            .each{|quark| Bosons::issue(clique1, quark) }
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
