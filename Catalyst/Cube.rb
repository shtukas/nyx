
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cube.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Quark.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

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

# -----------------------------------------------------------------

class Cube

    # Cube::makeQuarksInteractively()
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

    # Cube::makeTagsInteractively()
    def self.makeTagsInteractively()
        tags = []
        loop {
            tag = LucilleCore::askQuestionAnswerAsString("tag (empty to exit): ")
            break if tag == ""
            tags << tag
        }
        tags
    end

    # Cube::issueCubeInteractivelyOrNull_v1()
    def self.issueCubeInteractivelyOrNull_v1()
        cube = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,

            "description"      => LucilleCore::askQuestionAnswerAsString("description: "),
            "quarksuuids"      => Cube::makeQuarksInteractively().map{|quark| quark["uuid"] },
            "tags"             => Cube::makeTagsInteractively()
        }
        puts JSON.pretty_generate(cube)
        Nyx::commitToDisk(cube)
        cube
    end

    # Cube::issueCubeInteractivelyOrNull_v2(canStarlightNodeInvite)
    def self.issueCubeInteractivelyOrNull_v2(canStarlightNodeInvite)
        cube = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,

            "description"      => LucilleCore::askQuestionAnswerAsString("description: "),
            "quarksuuids"      => Cube::makeQuarksInteractively().map{|quark| quark["uuid"] },
            "tags"             => Cube::makeTagsInteractively()
        }
        puts JSON.pretty_generate(cube)
        Nyx::commitToDisk(cube)
        if canStarlightNodeInvite and LucilleCore::askQuestionAnswerAsBoolean("Would you like to add this cube to a Starlight node ? ") then
            node = StarlightUserInterface::selectNodeFromExistingOrCreateOneOrNull()
            if node then
                StarlightInventory::issueClaim(node, cube)
            end
        end
        cube
    end

    # Cube::issueCube_v1(quark)
    def self.issueCube_v1(quark)
        cube = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,

            "description"      => quark["description"] ? quark["description"] : "[cube default name / #{SecureRandom.hex(2)}]",
            "quarksuuids"      => [quark["uuid"]],
            "tags"             => []
        }
        Nyx::commitToDisk(cube)
        cube
    end

    # Cube::issueCube_v2(description, quark)
    def self.issueCube_v2(description, quark)
        cube = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,

            "description"      => description,
            "quarksuuids"      => [quark["uuid"]],
            "tags"             => []
        }
        Nyx::commitToDisk(cube)
        cube
    end

    # Cube::issueCube_v3(description)
    def self.issueCube_v3(description)
        cube = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "quarksuuids"      => [],
            "tags"             => []
        }
        Nyx::commitToDisk(cube)
        cube
    end

    # Cube::issueCube_v4(description, quark, tags)
    def self.issueCube_v4(description, quark, tags)
        cube = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,

            "description"      => description,
            "quarksuuids"      => [quark["uuid"]],
            "tags"             => tags
        }
        Nyx::commitToDisk(cube)
        cube
    end

    # Cube::cubesByTag(tag)
    def self.getCubesByTag(tag)
        Cube::cubes()
            .select{|cube| cube["tags"].include?(tag) }
    end

    # Cube::tags()
    def self.tags()
        Cube::cubes()
            .map{|cube| cube["tags"] }
            .flatten
            .uniq
            .sort
    end

    # Cube::cubes()
    def self.cubes()
        Nyx::objects("cube-933c2260-92d1-4578-9aaf-cd6557c664c6")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end

    # Cube::getOrNull(uuid)
    def self.getOrNull(uuid)
        Nyx::getOrNull(uuid)
    end

    # ------------------------------------------------------------

    # Cube::selectCubeFromExistingOrNull()
    def self.selectCubeFromExistingOrNull()
        descriptionXp = lambda { |cube|
            "#{cube["description"]} (#{cube["uuid"][0,4]}) [#{cube["tags"].join(",")}]"
        }
        cubes = Cube::cubes()
        descriptionsxp = cubes.reverse.map{|cube| descriptionXp.call(cube) }
        selectedDescriptionxp = CatalystCommon::chooseALinePecoStyle("select cube (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        cubes.select{|c| descriptionXp.call(c) == selectedDescriptionxp }.first
    end

    # Cube::visitTag(tag)
    def self.visitTag(tag)
        loop {
            system('clear')
            puts "Cubes: Tag Diving: #{tag}"
            items = []
            Cube::cubes()
                .select{|cube| cube["tags"].map{|tag| tag.downcase }.include?(tag.downcase) }
                .each{|cube|
                    items << [ Cube::cubeToString(cube) , lambda { Cube::cubeDive(cube) } ]
                }
            break if items.empty?
            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # Cube::cubeToString(cube)
    def self.cubeToString(cube)
        "[cube] [#{cube["uuid"][0, 4]}] #{cube["description"]} (#{cube["quarksuuids"].size})"
    end

    # Cube::printCubeDetails(cube)
    def self.printCubeDetails(cube)
        puts "Cube:"
        puts "    - uuid: #{cube["uuid"]}"
        puts "    - description: #{cube["description"]}"

        cube["quarksuuids"]
            .each{|quarkuuid|
                quark = Nyx::getOrNull(quarkuuid)
                puts "    - #{Quark::quarkToString(quark)}"
            }
        cube["tags"].each{|item|
            puts "    - [tag] #{item}"
        }

        nodes = StarlightInventory::getNodesForCube(cube)
        nodes.each{|node|
            puts "    - #{StarlightNodes::nodeToString(node)}"
        }
    end

    # Cube::openCube(cube)
    def self.openCube(cube)
        Cube::printCubeDetails(cube)
        puts "    -> Opening..."
        if cube["quarksuuids"].size == 0 then
            if LucilleCore::askQuestionAnswerAsBoolean("I could not find any target for this cube. Dive? ") then
                Cube::cubeDive(cube)
            end
            return
        end
        target = 
            if cube["quarksuuids"].size == 1 then
                Nyx::getOrNull(cube["quarksuuids"].first)
            else
                toString = lambda{|quarkuuid|
                    quark = Nyx::getOrNull(quarkuuid)
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

    # Cube::cubeDive(cube)
    def self.cubeDive(cube)
        loop {
            system("clear")
            puts ""
            cube = Nyx::getOrNull(cube["uuid"]) # useful if we have modified it
            return if cube.nil? # useful if we have just destroyed it

            Cube::printCubeDetails(cube)

            items = []

            cube["quarksuuids"]
                .each{|quarkuuid| 
                    quark = Nyx::getOrNull(quarkuuid)
                    next if quark.nil?
                    items << ["[quark] #{Quark::quarkToString(quark)}", lambda{ Quark::quarkDive(quark) }]
                }

            StarlightInventory::getNodesForCube(cube)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|node| items << [StarlightNodes::nodeToString(node), lambda{ StarlightUserInterface::nodeDive(node) }] }

            items << nil

            if !cube["quarksuuids"].empty? then
                items << ["open", lambda{  Cube::openCube(cube) }]
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
                    Nyx::commitToDisk(cube)
                }]
            items << [
                "Quark (add new)", 
                lambda{
                    quark = Quark::issueNewQuarkInteractivelyOrNull()
                    next if quark.nil?
                    cube["quarksuuids"] << quark["uuid"]
                    Nyx::commitToDisk(cube)
                }]
            items << [
                "Quark (select and remove)", 
                lambda{
                    toStringLambda = lambda { |quark| Quark::quarkToString(quark) }
                    quark = LucilleCore::selectEntityFromListOfEntitiesOrNull("quark", cube["quarksuuids"], toStringLambda)
                    next if quark.nil?
                    cube["quarksuuids"] = cube["quarksuuids"].reject{|quarkuuid| quarkuuid == quark["uuid"] }
                    Nyx::commitToDisk(cube)
                }]
            items << [
                "tags (add new)", 
                lambda{
                    cube["tags"] << LucilleCore::askQuestionAnswerAsString("tag: ")
                    Nyx::commitToDisk(cube)
                }]
            items << [
                "tags (remove)", 
                lambda{
                    tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", cube["tags"])
                    next if tag.nil?
                    cube["tags"] = cube["tags"].reject{|t| t == tag }
                    Nyx::commitToDisk(cube)
                }]
            items << [
                "add to Starlight Node", 
                lambda{
                    node = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                    next if node.nil?
                    StarlightInventory::issueClaim(node, cube)
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
                    Nyx::commitToDisk(claim)
                }]
            items << [
                "destroy cube", 
                lambda{
                    if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                        Nyx::destroy(cube["uuid"])
                        return
                    end
                }]

            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

    # Cube::visitGivenCubes(cubes)
    def self.visitGivenCubes(cubes)
        loop {
            cube = LucilleCore::selectEntityFromListOfEntitiesOrNull("cube", cubes, lambda{|cube| Cube::cubeToString(cube) })
            break if cube.nil?
            Cube::cubeDive(cube)
        }
    end
end

class CubeSearch

    # CubeSearch::searchPatternToTags(searchPattern)
    def self.searchPatternToTags(searchPattern)
        Cube::tags()
            .select{|tag| tag.downcase.include?(searchPattern.downcase) }
    end

    # CubeSearch::searchPatternToCubes(searchPattern)
    def self.searchPatternToCubes(searchPattern)
        Cube::cubes()
            .select{|cube| cube["description"].downcase.include?(searchPattern.downcase) }
    end

    # CubeMakeAndOrSelectQuest::makeAndOrSelectCubeOrNullPatternToCubesDescriptions(searchPattern)
    def self.searchPatternToCubesDescriptions(searchPattern)
        CubeSearch::searchPatternToCubes(searchPattern)
            .map{|cube| cube["description"] }
            .uniq
            .sort
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
                    return [ Cube::cubeToString(cube) , lambda { Cube::cubeDive(cube) } ]
                end
                if object["type"] == "tag" then
                    tag = object["tag"]
                    return [ "tag: #{tag}" , lambda { Cube::visitTag(tag) } ]
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

class CubeUserInterface

    # CubeUserInterface::selectCubeFromExistingCubes()
    def self.selectCubeFromExistingCubes()
        cubestrings = Cube::cubes().map{|cube| Cube::cubeToString(cube) }
        cubestring = CatalystCommon::chooseALinePecoStyle("cube:", [""]+cubestrings)
        Cube::cubes()
            .select{|cube| Cube::cubeToString(cube) == cubestring }
            .first
    end

    # CubeUserInterface::listingAndSelection()
    def self.listingAndSelection()
        cube = CubeUserInterface::selectCubeFromExistingCubes()
        return if cube.nil?
        Cube::cubeDive(cube)
    end

    # CubeUserInterface::navigation()
    def self.navigation()
        fragment = LucilleCore::askQuestionAnswerAsString("search and visit: fragment: ")
        return nil if fragment.nil?
        items = CubeSearch::search(fragment)
        CubeSearch::diveSearchResults(items)
    end

    # CubeUserInterface::main()
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
                Cube::cubes()
                    .each{|cube|
                        uuid = cube["uuid"]
                        tags1 = cube["tags"]
                        tags2 = tags1.map{|tag| renameTagIfNeeded.call(tag, oldname, newname) }
                        if tags1.join(':') != tags2.join(':') then
                            cube["tags"] = tags2
                            Nyx::commitToDisk(cube)
                        end
                    }
            end
            if operation == "cube dive (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                cube = Nyx::getOrNull(uuid)
                if cube then
                    Cube::cubeDive(cube)
                else
                    puts "Could not find cube for uuid (#{uuid})"
                end
            end
            if operation == "repair json (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                cube = Nyx::getOrNull(uuid)
                if cube then
                    cubejson = CatalystCommon::editTextUsingTextmate(JSON.pretty_generate(cube))
                    cube = JSON.parse(cubejson)
                    Nyx::commitToDisk(cube)
                else
                    puts "Could not find cube for uuid (#{uuid})"
                end
            end
            if operation == "make new cube" then
                Cube::issueCubeInteractivelyOrNull_v2(true)
            end
            if operation == "show newly created cubes" then
                cubes = Cube::cubes()
                            .sort{|p1, p2| p1["creationUnixtime"] <=> p2["creationUnixtime"] }
                            .reverse
                            .first(20)
                Cube::visitGivenCubes(cubes)
            end
            if operation == "cube destroy (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                cube = Nyx::getOrNull(uuid)
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

class CubeMakeAndOrSelectQuest

    # CubeMakeAndOrSelectQuest::makeAndOrSelectCubeOrNull()
    def self.makeAndOrSelectCubeOrNull()
        puts "-> You are on a selection Quest [selecting a cube]"
        puts "-> I am going to make you select one from existing and if that doesn't work, I will make you create a new one [with extensions if you want]"
        LucilleCore::pressEnterToContinue()
        cube = Cube::selectCubeFromExistingOrNull()
        return cube if cube
        puts "-> You are on a selection Quest [selecting a cube]"
        if LucilleCore::askQuestionAnswerAsBoolean("-> You have not selected any of the existing, would you like to make one ? ") then
            cube = Cube::issueCubeInteractivelyOrNull_v1()
            return nil if cube.nil?
            puts "-> You are on a selection Quest [selecting a cube]"
            puts "-> You have created '#{node["description"]}'"
            option1 = "quest: return '#{node["description"]}' immediately"
            option2 = "quest: dive first"
            options = [ option1, option2 ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
            if option == option1 then
                return cube
            end
            if option == option2 then
                Cube::cubeDive(cube)
                return cube
            end
        end
    end
end
