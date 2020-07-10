# encoding: UTF-8

# require_relative "Cliques.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require_relative "Bosons.rb"
require_relative "DataPortalUI.rb"
require_relative "TodoRoles.rb"

# -----------------------------------------------------------------

class Cliques

    # Cliques::issueClique(name1)
    def self.issueClique(name1)
        clique = {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5",
            "unixtime"         => Time.new.to_f,
            "name"             => name1
        }
        Cliques::commitToDisk(clique)
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
        "[clique] [#{clique["uuid"][0, 4]}] #{clique["name"]}"
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

    # Cliques::getClickByNameOrNull(name)
    def self.getClickByNameOrNull(name1)
        Cliques::cliques()
            .select{|clique| clique["name"] == name1 }
            .first
    end

    # Cliques::cliqueDive(clique)
    def self.cliqueDive(clique)
        loop {

            clique = NyxObjects::getOrNull(clique["uuid"])

            return if clique.nil? # could have been destroyed in a previous loop

            system("clear")

            Miscellaneous::horizontalRule(false)

            puts Cliques::cliqueToString(clique)
            puts "uuid: #{clique["uuid"]}"

            notetext = Notes::getMostRecentTextForTargetOrNull(clique["uuid"])

            if notetext then
                puts "Note:"
                puts notetext
            end

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule(true)

            menuitems.item(
                "rename", 
                lambda{ 
                    clique["name"] = Miscellaneous::editTextUsingTextmate(clique["name"]).strip
                    Cliques::commitToDisk(clique)
                }
            )

            menuitems.item(
                "textnote (edit)", 
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
                "quarks (select multiple ; send to cliques ; detach from this) # graph maker", 
                lambda {
                    quarks = Bosons::getQuarksForClique(clique)
                                .select{|objs| objs["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f" }
                    selectedQuarks, _ = LucilleCore::selectZeroOrMore("quarks", [], quarks, toStringLambda = lambda{ |quark| Quarks::quarkToString(quark) })
                    return if selected.size == 0
                    puts "Now selecting/making the receiving cliques"
                    LucilleCore::pressEnterToContinue()
                    nextcliques = Cliques::selectZeroOrMoreCliquesExistingOrCreated()
                    puts "Linking quarks to cliques"
                    nextcliques.each{|nextclique|
                        selectedQuarks.each{|quark| Bosons::issue(nextclique, quark) }
                    }
                    puts "Unlinking quarks from (this)"
                    selectedQuarks.each{|quark| Bosons::destroy(clique, quark) }
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

            menuitems.item(
                "/", 
                lambda { DataPortalUI::dataPortalFront() }
            )

            Miscellaneous::horizontalRule(true)

            TodoRoles::getRolesForTarget(clique["uuid"])
                .each{|object| 
                    menuitems.item(
                        TodoRoles::objectToString(object), 
                        lambda { TodoRoles::objectDive(object) }
                    )
                }

            Bosons::getQuarksForClique(clique)
                .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
                .each{|quark|
                    menuitems.item(
                        Quarks::quarkToString(quark), 
                        lambda { Quarks::quarkDive(quark) }
                    )
                }

            Miscellaneous::horizontalRule(true)

            status = menuitems.prompt()
            break if !status
        }
    end

    # Cliques::selectFromExistingCliquesAndDive()
    def self.selectFromExistingCliquesAndDive()
        clique = Cliques::selectCliqueFromExistingCliquesOrNull()
        return if clique.nil?
        Cliques::cliqueDive(clique)
    end

    # Cliques::getLastActivityUnixtime(clique)
    def self.getLastActivityUnixtime(clique)
        times = [ clique["unixtime"] ] + Bosons::getQuarksForClique(clique).map{|object| object["unixtime"] }
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
                    "referencetime" => clique["unixtime"],
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
