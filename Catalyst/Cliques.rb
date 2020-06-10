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
        puts "making a new timeline:"
        timeline = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "timeline-8826cbad-e54e-4e78-bf7d-28c9c5019721",
            "creationUnixtime" => Time.new.to_f,

            "name"             => LucilleCore::askQuestionAnswerAsString("timeline name: ")
        }
        Nyx::commitToDisk(timeline)
        puts JSON.pretty_generate(timeline)
        timeline
    end

    # Cliques::timelineToString(timeline)
    def self.timelineToString(timeline)
        "[timeline] [#{timeline["uuid"][0, 4]}] #{timeline["name"]}"
    end

    # Cliques::getOrNull(uuid)
    def self.getOrNull(uuid)
        Nyx::getOrNull(uuid)
    end

    # Cliques::timelines()
    def self.timelines()
        Nyx::objects("timeline-8826cbad-e54e-4e78-bf7d-28c9c5019721")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end

    # Cliques::selectCliqueFromExistingCliquesOrNull()
    def self.selectCliqueFromExistingCliquesOrNull()
        timelinestrings = Cliques::timelines().map{|timeline| Cliques::timelineToString(timeline) }
        timelinestring = CatalystCommon::chooseALinePecoStyle("timeline:", [""]+timelinestrings)
        return nil if timelinestring == ""
        Cliques::timelines()
            .select{|timeline| Cliques::timelineToString(timeline) == timelinestring }
            .first
    end

    # Cliques::selectCliqueFromExistingOrCreateOneOrNull()
    def self.selectCliqueFromExistingOrCreateOneOrNull()
        puts "-> You are selecting a timeline (possibly will create one)"
        LucilleCore::pressEnterToContinue()
        timeline = Cliques::selectCliqueFromExistingCliquesOrNull()
        return timeline if timeline
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to make a new timeline and return it ? ") then
            return Cliques::makeCliqueInteractivelyOrNull()
        end
        nil
    end

    # Cliques::timelineDive(timeline)
    def self.timelineDive(timeline)
        loop {
            system("clear")
            puts ""
            puts "uuid: #{timeline["uuid"]}"
            puts Cliques::timelineToString(timeline).green
            items = []

            CliqueContent::getCubes(timeline)
                .sort{|p1, p2| p1["creationUnixtime"] <=> p2["creationUnixtime"] } # "creationUnixtime" is a common attribute of all data entities
                .each{|cube| items << [Cubes::cubeToString(cube), lambda{ Cubes::cubeDive(cube) }] }

            items << nil

            items << ["rename", lambda{ 
                timeline["name"] = CatalystCommon::editTextUsingTextmate(timeline["name"]).strip
                Nyx::commitToDisk(timeline)
            }]

            items << ["add cube (from existing)", lambda{ 
                cube = Cubes::selectCubeFromExistingOrNull()
                return if cube.nil?
                CliqueContent::issueClaim(timeline, cube)
            }]

            items << ["-> cube (new) -> quark (new)", lambda{ 
                puts "Let's make a cube"
                description = LucilleCore::askQuestionAnswerAsString("cube description: ")
                cube = Cubes::issueCube_v3(description)
                puts JSON.pretty_generate(cube)
                puts "Let's attach the cube to the timeline"
                claim = CliqueContent::issueClaim(timeline, cube)
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
        timeline = Cliques::selectCliqueFromExistingCliquesOrNull()
        return if timeline.nil?
        Cliques::timelineDive(timeline)
    end

    # Cliques::selectCliqueOrMakeNewOneOrNull()
    def self.selectCliqueOrMakeNewOneOrNull()
        puts "-> You are on a selection Quest [selecting an timeline]"
        puts "-> I am going to make you select one from existing and if that doesn't work, I will make you create a new one [with extensions if you want]"
        LucilleCore::pressEnterToContinue()
        timeline = Cliques::selectCliqueFromExistingCliquesOrNull()
        return timeline if timeline
        Cliques::makeCliqueInteractivelyOrNull()
    end
end

class CliqueContent

    # CliqueContent::issueClaim(timeline, cube)
    def self.issueClaim(timeline, cube)
        raise "6df08321" if cube["nyxType"] != "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"
        claim = {
            "nyxType"          => "timeline-cube-link-b38137c1-fd43-4035-9f2c-af0fddb18c80",
            "creationUnixtime" => Time.new.to_f,
            "uuid"             => SecureRandom.uuid,

            "timelineuuid"     => timeline["uuid"],
            "cubeuuid"         => cube["uuid"]
        }
        Nyx::commitToDisk(claim)
        claim
    end

    # CliqueContent::claimToString(claim)
    def self.claimToString(claim)
        "[timeline-cube-link] #{claim["timelineuuid"]} -> #{claim["cubeuuid"]}"
    end

    # CliqueContent::getCubes(timeline)
    def self.getCubes(timeline)
        Nyx::objects("timeline-cube-link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .select{|claim| claim["timelineuuid"] == timeline["uuid"] }
            .map{|claim| Cubes::getOrNull(claim["cubeuuid"]) }
            .compact
    end

    # CliqueContent::getCliques(cube)
    def self.getCliques(cube)
        Nyx::objects("timeline-cube-link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .select{|claim| claim["cubeuuid"] == cube["uuid"] }
            .map{|claim| Nyx::getOrNull(claim["timelineuuid"]) }
            .compact
    end

    # CliqueContent::claims()
    def self.claims()
        Nyx::objects("timeline-cube-link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end
end

