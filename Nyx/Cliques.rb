# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cliques.rb"

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

require 'colorize'

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Bosons.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/OpenCycles.rb"

# -----------------------------------------------------------------

class Cliques

    # Cliques::issueClique(name1)
    def self.issueClique(name1)
        clique = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721",
            "creationUnixtime" => Time.new.to_f,
            "name"             => name1
        }
        NyxIO::commitToDisk(clique)
        clique
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
        NyxIO::getOrNull(uuid)
    end

    # Cliques::cliques()
    def self.cliques()
        NyxIO::objects("clique-8826cbad-e54e-4e78-bf7d-28c9c5019721")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end

    # Cliques::getCliqueBosonLinkedObjects(clique)
    def self.getCliqueBosonLinkedObjects(clique)
        Bosons2::getLinkedObjects(clique)
    end

    # Cliques::selectCliqueFromExistingCliquesOrNull()
    def self.selectCliqueFromExistingCliquesOrNull()
        cliquestrings = Cliques::cliques().map{|clique| Cliques::cliqueToString(clique) }
        cliquestring = CatalystCommon::chooseALinePecoStyle("clique:", [""]+cliquestrings)
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

            clique = NyxIO::getOrNull(clique["uuid"])

            return if clique.nil? # could have been destroyed in a previous loop

            system("clear")
            puts Cliques::cliqueToString(clique).green
            puts "uuid: #{clique["uuid"]}"
            items = []

            items << ["rename", lambda{ 
                clique["name"] = CatalystCommon::editTextUsingTextmate(clique["name"]).strip
                NyxIO::commitToDisk(clique)
            }]

            items << [
                "quark (add new)", 
                lambda{
                    quark = Quarks::issueNewQuarkInteractivelyOrNull()
                    return if quark.nil?
                    link = Bosons2::link(clique, quark)
                    puts JSON.pretty_generate(link)
                    Quarks::issueZeroOrMoreTagsForQuarkInteractively(quark)
                }]

            items << [
                "opencycle (register as)", 
                lambda { OpenCycles::issueFromClique(clique) }
            ]

            items << [
                "quarks (select multiple ; send to cliques ; detach from this) # graph maker", 
                lambda {
                    quarks = Cliques::getCliqueBosonLinkedObjects(clique).select{|objs| objs["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" }
                    selectedQuarks, _ = LucilleCore::selectZeroOrMore("quarks", [], quarks, toStringLambda = lambda{ |quark| Quarks::quarkToString(quark) })
                    return if selected.size == 0
                    puts "Now selecting/making the receiving cliques"
                    LucilleCore::pressEnterToContinue()
                    nextcliques = Cliques::selectZeroOrMoreCliquesExistingOrCreated()
                    puts "Linking quarks to cliques"
                    nextcliques.each{|nextclique|
                        selectedQuarks.each{|quark| 
                            Bosons2::link(nextclique, quark)
                        }
                    }
                    puts "Unlinking quarks from (this)"
                    selectedQuarks.each{|quark| 
                        Bosons2::unlink(clique, quark)
                    }
                }
            ]

            items << [
                "clique (destroy)", 
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this clique ? ") then
                        NyxIO::destroy(clique["uuid"])
                    end
                }
            ]

            items << nil

            NyxRoles::getRolesForTarget(clique["uuid"])
                .each{|object| items << [NyxRoles::objectToString(object), lambda { NyxRoles::objectDive(object) }] }

            items << nil

            Cliques::getCliqueBosonLinkedObjects(clique)
                .sort{|o1, o2| NyxDataCarriers::objectLastActivityUnixtime(o1) <=> NyxDataCarriers::objectLastActivityUnixtime(o2) }
                .each{|object|
                    object = NyxDataCarriers::applyQuarkToCubeUpgradeIfRelevant(object)
                    items << [NyxDataCarriers::objectToString(object), lambda { NyxDataCarriers::objectDive(object) }]
                }

            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
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
        times = [ clique["creationUnixtime"] ] + Bosons2::getLinkedObjects(clique).select{|object| object["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6" }.map{|cube| cube["creationUnixtime"] }
        times.max
    end

    # Cliques::cliquesListingAndDive()
    def self.cliquesListingAndDive()
        loop {
            items = []
            Cliques::cliques()
                .sort{|q1, q2| q1["creationUnixtime"]<=>q2["creationUnixtime"] }
                .each{|clique|
                    items << [ Cliques::cliqueToString(clique), lambda{ Cliques::cliqueDive(clique) }]
                }
            status = LucilleCore::menuItemsWithLambdas(items)
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
                    "referencetime" => clique["creationUnixtime"],
                    "dive"          => lambda{ Cliques::cliqueDive(clique) }
                }
            }
    end

    # Cliques::mergeCliques(clique1, clique2)
    def self.mergeCliques(clique1, clique2)
        # We take everything connected to clique2, link that to clique1 and delete clique2
        Bosons2::getLinkedObjects(clique2)
            .each{|object|
                Bosons2::link(clique1, object)
            }
        NyxIO::destroy(clique2["uuid"])
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
