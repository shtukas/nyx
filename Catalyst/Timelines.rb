# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Timelines.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CubesAndTimelines.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Nyx.rb"

# -----------------------------------------------------------------

class Timelines

    # Timelines::makeTimelineInteractivelyOrNull()
    def self.makeTimelineInteractivelyOrNull()
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

    # Timelines::timelineToString(timeline)
    def self.timelineToString(timeline)
        "[timeline] [#{timeline["uuid"][0, 4]}] #{timeline["name"]}"
    end

    # Timelines::getOrNull(uuid)
    def self.getOrNull(uuid)
        Nyx::getOrNull(uuid)
    end

    # Timelines::timelines()
    def self.timelines()
        Nyx::objects("timeline-8826cbad-e54e-4e78-bf7d-28c9c5019721")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end

    # Timelines::selectTimelineFromExistingTimelinesOrNull()
    def self.selectTimelineFromExistingTimelinesOrNull()
        timelinestrings = Timelines::timelines().map{|timeline| Timelines::timelineToString(timeline) }
        timelinestring = CatalystCommon::chooseALinePecoStyle("timeline:", [""]+timelinestrings)
        return nil if timelinestring == ""
        Timelines::timelines()
            .select{|timeline| Timelines::timelineToString(timeline) == timelinestring }
            .first
    end

    # Timelines::selectTimelineFromExistingOrCreateOneOrNull()
    def self.selectTimelineFromExistingOrCreateOneOrNull()
        puts "-> You are selecting a timeline (possibly will create one)"
        LucilleCore::pressEnterToContinue()
        timeline = Timelines::selectTimelineFromExistingTimelinesOrNull()
        return timeline if timeline
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to make a new timeline and return it ? ") then
            return Timelines::makeTimelineInteractivelyOrNull()
        end
        nil
    end

    # Timelines::timelineDive(timeline)
    def self.timelineDive(timeline)
        loop {
            system("clear")
            puts ""
            puts "uuid: #{timeline["uuid"]}"
            puts Timelines::timelineToString(timeline).green
            items = []

            TimelineContent::getCubes(timeline)
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
                TimelineContent::issueClaim(timeline, cube)
            }]

            items << ["-> cube (new) -> quark (new)", lambda{ 
                puts "Let's make a cube"
                description = LucilleCore::askQuestionAnswerAsString("cube description: ")
                cube = Cubes::issueCube_v3(description)
                puts JSON.pretty_generate(cube)
                puts "Let's attach the cube to the timeline"
                claim = TimelineContent::issueClaim(timeline, cube)
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

    # Timelines::selectFromExistingTimelinesAndDive()
    def self.selectFromExistingTimelinesAndDive()
        timeline = Timelines::selectTimelineFromExistingTimelinesOrNull()
        return if timeline.nil?
        Timelines::timelineDive(timeline)
    end

    # Timelines::selectTimelineOrMakeNewOneOrNull()
    def self.selectTimelineOrMakeNewOneOrNull()
        puts "-> You are on a selection Quest [selecting an timeline]"
        puts "-> I am going to make you select one from existing and if that doesn't work, I will make you create a new one [with extensions if you want]"
        LucilleCore::pressEnterToContinue()
        timeline = Timelines::selectTimelineFromExistingTimelinesOrNull()
        return timeline if timeline
        Timelines::makeTimelineInteractivelyOrNull()
    end
end

class TimelineContent

    # TimelineContent::issueClaim(timeline, cube)
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

    # TimelineContent::claimToString(claim)
    def self.claimToString(claim)
        "[timeline-cube-link] #{claim["timelineuuid"]} -> #{claim["cubeuuid"]}"
    end

    # TimelineContent::getCubes(timeline)
    def self.getCubes(timeline)
        Nyx::objects("timeline-cube-link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .select{|claim| claim["timelineuuid"] == timeline["uuid"] }
            .map{|claim| Cubes::getOrNull(claim["cubeuuid"]) }
            .compact
    end

    # TimelineContent::getTimelines(cube)
    def self.getTimelines(cube)
        Nyx::objects("timeline-cube-link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .select{|claim| claim["cubeuuid"] == cube["uuid"] }
            .map{|claim| Nyx::getOrNull(claim["timelineuuid"]) }
            .compact
    end

    # TimelineContent::claims()
    def self.claims()
        Nyx::objects("timeline-cube-link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end
end

