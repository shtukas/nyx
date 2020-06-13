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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Links.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/OpenCycles.rb"

# -----------------------------------------------------------------

class Cliques

    # Cliques::makeCliqueInteractivelyOrNull()
    def self.makeCliqueInteractivelyOrNull()
        puts "making a new clique:"
        clique = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721",
            "creationUnixtime" => Time.new.to_f,

            "name"             => LucilleCore::askQuestionAnswerAsString("clique name: ")
        }
        NyxIO::commitToDisk(clique)
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
            return Cliques::makeCliqueInteractivelyOrNull()
        end
        nil
    end

    # Cliques::cliqueDive(clique)
    def self.cliqueDive(clique)
        loop {
            system("clear")
            puts Cliques::cliqueToString(clique).green
            puts "uuid: #{clique["uuid"]}"
            items = []

            Links::getLinkedObjects(clique)
                .sort{|o1, o2| NyxDataCarriers::objectLastActivityUnixtime(o1) <=> NyxDataCarriers::objectLastActivityUnixtime(o2) }
                .each{|object| 
                    items << [NyxDataCarriers::objectToString(object), lambda { NyxDataCarriers::objectDive(object) }] }

            items << nil

            NyxRoles::getRolesForTarget(clique["uuid"])
                .each{|object| items << [NyxRoles::objectToString(object), lambda { NyxRoles::objectDive(object) }] }

            items << nil

            items << ["rename", lambda{ 
                clique["name"] = CatalystCommon::editTextUsingTextmate(clique["name"]).strip
                NyxIO::commitToDisk(clique)
            }]

            items << [
                "quark (add new)", 
                lambda{
                    quark = Quark::issueNewQuarkInteractivelyOrNull()
                    return if quark.nil?
                    link = Links::issueLink(clique, quark)
                    puts JSON.pretty_generate(link)
                }]

            items << ["add cube (from existing)", lambda{ 
                cube = Cubes::selectCubeFromExistingOrNull()
                return if cube.nil?
                Links::issueLink(clique, cube)
            }]

            items << ["add cube (create new)", lambda{

                cube = Cubes::issueQuarkCubeInteractivelyOrNull()
                return if cube.nil?
                puts JSON.pretty_generate(cube)

                puts "Let's attach the cube to the clique"
                link = Links::issueLink(clique, cube)
                puts JSON.pretty_generate(link)

                LucilleCore::pressEnterToContinue()
            }]

            items << [
                "opencycle (register as)", 
                lambda { OpenCycles::issueFromClique(clique) }
            ]

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

    # Cliques::selectCliqueOrMakeNewOneOrNull()
    def self.selectCliqueOrMakeNewOneOrNull()
        puts "-> I am going to make you select one from existing and if that doesn't work, I will make you create a new one"
        LucilleCore::pressEnterToContinue()
        clique = Cliques::selectCliqueFromExistingCliquesOrNull()
        return clique if clique
        Cliques::makeCliqueInteractivelyOrNull()
    end

    # Cliques::getLastActivityUnixtime(clique)
    def self.getLastActivityUnixtime(clique)
        times = [ clique["creationUnixtime"] ] + Links::getLinkedObjects(clique).select{|object| object["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6" }.map{|cube| cube["creationUnixtime"] }
        times.max
    end
end
