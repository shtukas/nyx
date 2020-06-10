# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cliques.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CubesAndCliques.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Nyx.rb"

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
        Nyx::commitToDisk(clique)
        puts JSON.pretty_generate(clique)
        clique
    end

    # Cliques::cliqueToString(clique)
    def self.cliqueToString(clique)
        "[clique] [#{clique["uuid"][0, 4]}] #{clique["name"]}"
    end

    # Cliques::getOrNull(uuid)
    def self.getOrNull(uuid)
        Nyx::getOrNull(uuid)
    end

    # Cliques::cliques()
    def self.cliques()
        Nyx::objects("clique-8826cbad-e54e-4e78-bf7d-28c9c5019721")
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
            puts ""
            puts "uuid: #{clique["uuid"]}"
            puts Cliques::cliqueToString(clique).green
            items = []

            CliqueContent::getCubes(clique)
                .sort{|p1, p2| p1["creationUnixtime"] <=> p2["creationUnixtime"] } # "creationUnixtime" is a common attribute of all data entities
                .each{|cube| items << [Cubes::cubeToString(cube), lambda{ Cubes::cubeDive(cube) }] }

            items << nil

            items << ["rename", lambda{ 
                clique["name"] = CatalystCommon::editTextUsingTextmate(clique["name"]).strip
                Nyx::commitToDisk(clique)
            }]

            items << ["add cube (from existing)", lambda{ 
                cube = Cubes::selectCubeFromExistingOrNull()
                return if cube.nil?
                CliqueContent::issueClaim(clique, cube)
            }]

            items << ["-> cube (new) -> quark (new)", lambda{ 
                puts "Let's make a cube"
                description = LucilleCore::askQuestionAnswerAsString("cube description: ")
                cube = Cubes::issueCube_v3(description)
                puts JSON.pretty_generate(cube)
                puts "Let's attach the cube to the clique"
                claim = CliqueContent::issueClaim(clique, cube)
                puts JSON.pretty_generate(claim)
                puts "Let's make a quark"
                quark = Quark::issueNewQuarkInteractivelyOrNull()
                cube["quarksuuids"] << quark["uuid"]
                puts JSON.pretty_generate(cube)
                Nyx::commitToDisk(cube)
                LucilleCore::pressEnterToContinue()
            }]

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
        puts "-> You are on a selection Quest [selecting an clique]"
        puts "-> I am going to make you select one from existing and if that doesn't work, I will make you create a new one [with extensions if you want]"
        LucilleCore::pressEnterToContinue()
        clique = Cliques::selectCliqueFromExistingCliquesOrNull()
        return clique if clique
        Cliques::makeCliqueInteractivelyOrNull()
    end
end

class CliqueContent

    # CliqueContent::issueClaim(clique, cube)
    def self.issueClaim(clique, cube)
        raise "6df08321" if cube["nyxType"] != "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"
        claim = {
            "nyxType"          => "clique-cube-link-b38137c1-fd43-4035-9f2c-af0fddb18c80",
            "creationUnixtime" => Time.new.to_f,
            "uuid"             => SecureRandom.uuid,

            "cliqueuuid"     => clique["uuid"],
            "cubeuuid"         => cube["uuid"]
        }
        Nyx::commitToDisk(claim)
        claim
    end

    # CliqueContent::claimToString(claim)
    def self.claimToString(claim)
        "[clique-cube-link] #{claim["cliqueuuid"]} -> #{claim["cubeuuid"]}"
    end

    # CliqueContent::getCubes(clique)
    def self.getCubes(clique)
        Nyx::objects("clique-cube-link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .select{|claim| claim["cliqueuuid"] == clique["uuid"] }
            .map{|claim| Cubes::getOrNull(claim["cubeuuid"]) }
            .compact
    end

    # CliqueContent::getCliques(cube)
    def self.getCliques(cube)
        Nyx::objects("clique-cube-link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .select{|claim| claim["cubeuuid"] == cube["uuid"] }
            .map{|claim| Nyx::getOrNull(claim["cliqueuuid"]) }
            .compact
    end

    # CliqueContent::claims()
    def self.claims()
        Nyx::objects("clique-cube-link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end
end

