
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/DataNetwork/Cubes.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/DataNetwork/Quark.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/DataNetwork/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/DataNetwork/Links.rb"

# -----------------------------------------------------------------

class Cubes

    # Cubes::makeQuarksInteractively()
    def self.makeQuarksInteractively()
        quarks = []
        loop {
            target = Quark::issueNewQuarkInteractivelyOrNull()
            break if target.nil?
            puts JSON.pretty_generate(target)
            quarks << target
        }
        quarks
    end

    # Cubes::makeTagsInteractively()
    def self.makeTagsInteractively()
        tags = []
        loop {
            tag = LucilleCore::askQuestionAnswerAsString("tag (empty to exit): ")
            break if tag == ""
            tags << tag
        }
        tags
    end

    # Cubes::issueCubeInteractivelyOrNull_v1()
    def self.issueCubeInteractivelyOrNull_v1()
        cube = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,

            "description"      => LucilleCore::askQuestionAnswerAsString("description: "),
            "quarksuuids"      => Cubes::makeQuarksInteractively().map{|quark| quark["uuid"] },
            "tags"             => Cubes::makeTagsInteractively()
        }
        puts JSON.pretty_generate(cube)
        DataNetwork::commitToDisk(cube)
        cube
    end

    # Cubes::issueCubeInteractivelyOrNull_v2(canCliqueInvite)
    def self.issueCubeInteractivelyOrNull_v2(canCliqueInvite)
        cube = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,

            "description"      => LucilleCore::askQuestionAnswerAsString("description: "),
            "quarksuuids"      => Cubes::makeQuarksInteractively().map{|quark| quark["uuid"] },
            "tags"             => Cubes::makeTagsInteractively()
        }
        puts JSON.pretty_generate(cube)
        DataNetwork::commitToDisk(cube)
        if canCliqueInvite and LucilleCore::askQuestionAnswerAsBoolean("Would you like to add this cube to an clique ? ") then
            clique = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
            if clique then
                Links::issue(clique, cube)
            end
        end
        cube
    end

    # Cubes::issueCube_v1(quark)
    def self.issueCube_v1(quark)
        cube = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,

            "description"      => quark["description"] ? quark["description"] : "[cube default name / #{SecureRandom.hex(2)}]",
            "quarksuuids"      => [quark["uuid"]],
            "tags"             => []
        }
        DataNetwork::commitToDisk(cube)
        cube
    end

    # Cubes::issueCube_v2(description, quark)
    def self.issueCube_v2(description, quark)
        cube = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,

            "description"      => description,
            "quarksuuids"      => [quark["uuid"]],
            "tags"             => []
        }
        DataNetwork::commitToDisk(cube)
        cube
    end

    # Cubes::issueCube_v3(description)
    def self.issueCube_v3(description)
        cube = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "quarksuuids"      => [],
            "tags"             => []
        }
        DataNetwork::commitToDisk(cube)
        cube
    end

    # Cubes::issueCube_v4(description, quark, tags)
    def self.issueCube_v4(description, quark, tags)
        cube = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,

            "description"      => description,
            "quarksuuids"      => [quark["uuid"]],
            "tags"             => tags
        }
        DataNetwork::commitToDisk(cube)
        cube
    end

    # Cubes::getCubesByTag(tag)
    def self.getCubesByTag(tag)
        Cubes::cubes()
            .select{|cube| cube["tags"].include?(tag) }
    end

    # Cubes::tags()
    def self.tags()
        Cubes::cubes()
            .map{|cube| cube["tags"] }
            .flatten
            .uniq
            .sort
    end

    # Cubes::cubes()
    def self.cubes()
        DataNetwork::objects("cube-933c2260-92d1-4578-9aaf-cd6557c664c6")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end

    # Cubes::getOrNull(uuid)
    def self.getOrNull(uuid)
        DataNetwork::getOrNull(uuid)
    end

    # ------------------------------------------------------------

    # Cubes::selectCubeFromExistingOrNull()
    def self.selectCubeFromExistingOrNull()
        descriptionXp = lambda { |cube|
            "#{cube["description"]} (#{cube["uuid"][0,4]}) [#{cube["tags"].join(",")}]"
        }
        cubes = Cubes::cubes()
        descriptionsxp = cubes.reverse.map{|cube| descriptionXp.call(cube) }
        selectedDescriptionxp = CatalystCommon::chooseALinePecoStyle("select cube (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        cubes.select{|c| descriptionXp.call(c) == selectedDescriptionxp }.first
    end

    # Cubes::visitTag(tag)
    def self.visitTag(tag)
        loop {
            system('clear')
            puts "Cubes: Tag Diving: #{tag}"
            items = []
            Cubes::cubes()
                .select{|cube| cube["tags"].map{|tag| tag.downcase }.include?(tag.downcase) }
                .each{|cube|
                    items << [ Cubes::cubeToString(cube) , lambda { Cubes::cubeDive(cube) } ]
                }
            break if items.empty?
            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # Cubes::cubeToString(cube)
    def self.cubeToString(cube)
        "[cube] [#{cube["uuid"][0, 4]}] #{cube["description"]} (#{cube["quarksuuids"].size})"
    end

    # Cubes::openCube(cube)
    def self.openCube(cube)
        puts "Cube:"
        puts "    - uuid: #{cube["uuid"]}"
        puts "    - description: #{cube["description"]}"

        cube["quarksuuids"]
            .each{|quarkuuid|
                quark = DataNetwork::getOrNull(quarkuuid)
                puts "    - #{Quark::quarkToString(quark)}"
            }
        cube["tags"].each{|item|
            puts "    - [tag] #{item}"
        }

        cliques = Links::getLinkedObjects(cube)
        cliques.each{|clique|
            puts "    - #{Cliques::cliqueToString(clique)}"
        }
        puts "    -> Opening..."
        if cube["quarksuuids"].size == 0 then
            if LucilleCore::askQuestionAnswerAsBoolean("I could not find any target for this cube. Dive? ") then
                Cubes::cubeDive(cube)
            end
            return
        end
        target = 
            if cube["quarksuuids"].size == 1 then
                DataNetwork::getOrNull(cube["quarksuuids"].first)
            else
                toString = lambda{|quarkuuid|
                    quark = DataNetwork::getOrNull(quarkuuid)
                    return "[null quark]"
                    Quark::quarkToString(quark)
                }
                LucilleCore::selectEntityFromListOfEntitiesOrNull("quark", cube["quarksuuids"], toString)
            end
        if target.nil? then
            puts "No target was selected for this cube. Aborting opening."
            LucilleCore::pressEnterToContinue()
            return
        end
        puts JSON.pretty_generate(target)
        Quark::openQuark(target)
    end

    # Cubes::cubeDive(cube)
    def self.cubeDive(cube)
        loop {
            system("clear")
            puts ""
            cube = DataNetwork::getOrNull(cube["uuid"]) # useful if we have modified it
            return if cube.nil? # useful if we have just destroyed it

            puts "Cube:"
            puts "    uuid: #{cube["uuid"]}"
            puts "    description: #{cube["description"]}".green

            items = []

            Links::getLinkedObjects(cube)
                .each{|clique|
                    items << [Cliques::cliqueToString(clique), lambda{ Cliques::cliqueDive(clique) }]
                }

            cube["quarksuuids"]
                .each{|quarkuuid| 
                    quark = DataNetwork::getOrNull(quarkuuid)
                    next if quark.nil?
                    items << [Quark::quarkToString(quark), lambda{ Quark::diveQuark(quark) }]
                }

            cube["tags"]
                .each{|tag| 
                    items << ["[tag] #{tag}", lambda{ Cubes::visitTag(tag) }]
                }

            items << nil

            if !cube["quarksuuids"].empty? then
                items << ["open", lambda{  Cubes::openCube(cube) }]
            end
            
            items << [
                "edit description", 
                lambda{
                    description = CatalystCommon::editTextUsingTextmate(cube["description"]).strip
                    if description == "" or description.lines.to_a.size != 1 then
                        puts "Descriptions should be one non empty line"
                        LucilleCore::pressEnterToContinue()
                        return
                    end
                    cube["description"] = description
                    DataNetwork::commitToDisk(cube)
                }]
            items << [
                "quark (add new)", 
                lambda{
                    quark = Quark::issueNewQuarkInteractivelyOrNull()
                    next if quark.nil?
                    cube["quarksuuids"] << quark["uuid"]
                    DataNetwork::commitToDisk(cube)
                }]
            items << [
                "quark (select and remove)", 
                lambda{
                    toStringLambda = lambda { |quark| Quark::quarkToString(quark) }
                    quark = LucilleCore::selectEntityFromListOfEntitiesOrNull("quark", cube["quarksuuids"], toStringLambda)
                    next if quark.nil?
                    cube["quarksuuids"] = cube["quarksuuids"].reject{|quarkuuid| quarkuuid == quark["uuid"] }
                    DataNetwork::commitToDisk(cube)
                }]
            items << [
                "tags (add new)", 
                lambda{
                    cube["tags"] << LucilleCore::askQuestionAnswerAsString("tag: ")
                    DataNetwork::commitToDisk(cube)
                }]
            items << [
                "tags (remove)", 
                lambda{
                    tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", cube["tags"])
                    next if tag.nil?
                    cube["tags"] = cube["tags"].reject{|t| t == tag }
                    DataNetwork::commitToDisk(cube)
                }]
            items << [
                "clique (select and add to)", 
                lambda{
                    clique = Cliques::selectCliqueOrMakeNewOneOrNull()
                    next if clique.nil?
                    Links::issue(clique, cube)
                }]
            items << [
                "register as open cycle", 
                lambda{
                    claim = {
                        "uuid"             => SecureRandom.uuid,
                        "nyxType"          => "open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f",
                        "creationUnixtime" => Time.new.to_f,
                        "quarkuuid"       => cube["uuid"],
                    }
                    puts JSON.pretty_generate(claim)
                    DataNetwork::commitToDisk(claim)
                }]
            items << [
                "cube (destroy)", 
                lambda{
                    if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                        DataNetwork::destroy(cube["uuid"])
                    end
                }]

            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

    # Cubes::visitGivenCubes(cubes)
    def self.visitGivenCubes(cubes)
        loop {
            cube = LucilleCore::selectEntityFromListOfEntitiesOrNull("cube", cubes, lambda{|cube| Cubes::cubeToString(cube) })
            break if cube.nil?
            Cubes::cubeDive(cube)
        }
    end

    # Cubes::selectCubeFromGivenCubes(cubes)
    def self.selectCubeFromGivenCubes(cubes)
        cubestrings = cubes.map{|cube| Cubes::cubeToString(cube) }
        cubestring = CatalystCommon::chooseALinePecoStyle("cube:", [""]+cubestrings)
        Cubes::cubes()
            .select{|cube| Cubes::cubeToString(cube) == cubestring }
            .first
    end

    # Cubes::selectFromExistingCubedAndDive()
    def self.selectFromExistingCubedAndDive()
        cube = Cubes::selectCubeFromGivenCubes(Cubes::cubes())
        return if cube.nil?
        Cubes::cubeDive(cube)
    end

    # Cubes::tagsThenCubesThenCubeThenDive()
    def self.tagsThenCubesThenCubeThenDive()
        loop {
            tags = Cubes::tags().sort.map{|tag| tag }
            tag = CatalystCommon::chooseALinePecoStyle("cube:", [""]+tags)
            break if tag == ""
            loop {
                system("system")
                cubes = Cubes::getCubesByTag(tag)
                cube = Cubes::selectCubeFromGivenCubes(cubes)
                break if cube.nil?
                Cubes::cubeDive(cube)
            }
        }
    end

    # Cubes::navigation()
    def self.navigation()
        fragment = LucilleCore::askQuestionAnswerAsString("search and visit: fragment: ")
        return nil if fragment.nil?
        items = CubeSearch::search(fragment)
        CubeSearch::diveSearchResults(items)
    end

    # Cubes::main()
    def self.main()
        loop {
            system("clear")
            puts "Cubes"
            operations = [
                "show newly created cubes",
                "cube dive (uuid)",
                "make new cube",
                "rename tag",
                "repair json (uuid)",
                "cube destroy (uuid)",
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "rename tag" then
                oldname = LucilleCore::askQuestionAnswerAsString("old name (capilisation doesn't matter): ")
                next if oldname.size == 0
                newname = LucilleCore::askQuestionAnswerAsString("new name: ")
                next if newname.size == 0
                renameTagIfNeeded = lambda {|tag, oldname, newname|
                    if tag.downcase == oldname.downcase then
                        tag = newname
                    end
                    tag
                }
                Cubes::cubes()
                    .each{|cube|
                        uuid = cube["uuid"]
                        tags1 = cube["tags"]
                        tags2 = tags1.map{|tag| renameTagIfNeeded.call(tag, oldname, newname) }
                        if tags1.join(':') != tags2.join(':') then
                            cube["tags"] = tags2
                            DataNetwork::commitToDisk(cube)
                        end
                    }
            end
            if operation == "cube dive (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                cube = DataNetwork::getOrNull(uuid)
                if cube then
                    Cubes::cubeDive(cube)
                else
                    puts "Could not find cube for uuid (#{uuid})"
                end
            end
            if operation == "repair json (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                cube = DataNetwork::getOrNull(uuid)
                if cube then
                    cubejson = CatalystCommon::editTextUsingTextmate(JSON.pretty_generate(cube))
                    cube = JSON.parse(cubejson)
                    DataNetwork::commitToDisk(cube)
                else
                    puts "Could not find cube for uuid (#{uuid})"
                end
            end
            if operation == "make new cube" then
                Cubes::issueCubeInteractivelyOrNull_v2(true)
            end
            if operation == "show newly created cubes" then
                cubes = Cubes::cubes()
                            .sort{|p1, p2| p1["creationUnixtime"] <=> p2["creationUnixtime"] }
                            .reverse
                            .first(20)
                Cubes::visitGivenCubes(cubes)
            end
            if operation == "cube destroy (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                cube = DataNetwork::getOrNull(uuid)
                next if cube.nil?
                if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                    puts "Well, this operation has not been implemented yet"
                    LucilleCore::pressEnterToContinue()
                    return
                end
            end
        }
    end
end

class CubeSearch

    # CubeSearch::searchPatternToTags(searchPattern)
    def self.searchPatternToTags(searchPattern)
        Cubes::tags()
            .select{|tag| tag.downcase.include?(searchPattern.downcase) }
    end

    # CubeSearch::searchPatternToCubes(searchPattern)
    def self.searchPatternToCubes(searchPattern)
        Cubes::cubes()
            .select{|cube| cube["description"].downcase.include?(searchPattern.downcase) }
    end

    # CubeSearch::search(fragment)
    # Objects returned by the function: they are essentially search results.
    # {
    #     "type" => "cube",
    #     "cube" => cube
    # }
    # {
    #     "type" => "tag",
    #     "tag" => tag
    # }
    def self.search(fragment)
        objs1 = CubeSearch::searchPatternToCubes(fragment)
                    .map{|cube| 
                        {
                            "type" => "cube",
                            "cube" => cube
                        }
                    }
        objs2 = CubeSearch::searchPatternToTags(fragment)
                    .map{|tag|
                        {
                            "type" => "tag",
                            "tag" => tag
                        }
                    }
        objs1 + objs2
    end

    # CubeSearch::diveSearchResults(items)
    def self.diveSearchResults(items)
        loop {
            itemsObjectToMenuItemOrNull = lambda {|object|
                if object["type"] == "cube" then
                    cube = object["cube"]
                    return [ Cubes::cubeToString(cube) , lambda { Cubes::cubeDive(cube) } ]
                end
                if object["type"] == "tag" then
                    tag = object["tag"]
                    return [ "tag: #{tag}" , lambda { Cubes::visitTag(tag) } ]
                end
                nil
            }
            items2 = items
                        .map{|object| itemsObjectToMenuItemOrNull.call(object) }
                        .compact
            status = LucilleCore::menuItemsWithLambdas(items2)
            break if !status
        }
    end
end
