
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cubes.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Quarks.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Links.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxRoles.rb"

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

    # Cubes::issueCubeWithDescription(description)
    def self.issueCubeWithDescription(description)
        cube = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description
        }
        NyxIO::commitToDisk(cube)
        cube
    end

    # Cubes::issueQuarkCubeInteractivelyOrNull()
    def self.issueQuarkCubeInteractivelyOrNull()
        puts "Let's start by making a quark for the new cube"
        quark = Quark::issueNewQuarkInteractivelyOrNull()
        return if quark.nil?
        puts JSON.pretty_generate(quark)

        description = LucilleCore::askQuestionAnswerAsString("cube description: ")
        cube = Cubes::issueCubeWithDescription(description)
        puts JSON.pretty_generate(cube)

        puts "Let's attach the quark to the cube"
        link = Links::issueLink(cube, quark)
        puts JSON.pretty_generate(link)

        cube
    end

    # Cubes::issueQuarkCubeInteractivelyWithCliqueInviteOrNull()
    def self.issueQuarkCubeInteractivelyWithCliqueInviteOrNull()
        cube = Cubes::issueQuarkCubeInteractivelyOrNull()
        return if cube.nil?
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add this cube to a clique ? ") then
            clique = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
            if clique then
                link = Links::issueLink(clique, cube)
                puts JSON.pretty_generate(link)
            end
        end
        cube
    end

    # Cubes::issueCubeWithDescriptionAndQuark(description, quark)
    def self.issueCubeWithDescriptionAndQuark(description, quark)
        cube = Cubes::issueCubeWithDescription(description)
        Links::issueLink(cube, quark)
        cube
    end

    # Cubes::getCubesByTag(tagPayload)
    def self.getCubesByTag(tagPayload)
        Tags::getTagsByExactPayload(tagPayload)
            .map{|tag| Links::getLinkedObjects(tag) }
            .flatten
            .select{|object| object["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6" }
    end

    # Cubes::cubes()
    def self.cubes()
        NyxIO::objects("cube-933c2260-92d1-4578-9aaf-cd6557c664c6")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end

    # Cubes::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxIO::getOrNull(uuid)
    end

    # Cubes::getCubeQuarks(cube)
    def self.getCubeQuarks(cube)
        Links::getLinkedObjectsOfGivenNyxType(cube, "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2")
    end

    # Cubes::getCubeFirstQuarkOrNull(cube)
    def self.getCubeFirstQuarkOrNull(cube)
        Cubes::getCubeQuarks(cube)
            .sort{|n1, n2| n1["creationUnixtime"] <=> n1["creationUnixtime"] }
            .first
    end

    # Cubes::computeLastActivityUnixtime(cube)
    def self.computeLastActivityUnixtime(cube)
        times = [ cube["creationUnixtime"] ] + Cubes::getCubeQuarks(cube).map{|quark| quark["creationUnixtime"]}
        times.max
    end

    # Cubes::forgetCachedLastActivityUnixtime(cube)
    def self.forgetCachedLastActivityUnixtime(cube)
        storageKey = "c8543fd5-43b3-4f5a-a4d2-802f9ddc4906:#{cube["uuid"]}"
        KeyValueStore::destroy(nil, storageKey)
    end

    # Cubes::getLastActivityUnixtime(cube)
    def self.getLastActivityUnixtime(cube)
        storageKey = "c8543fd5-43b3-4f5a-a4d2-802f9ddc4906:#{cube["uuid"]}"
        unixtime = KeyValueStore::getOrNull(nil, storageKey)
        if unixtime then
            return unixtime.to_f
        end
        unixtime = Cubes::computeLastActivityUnixtime(cube)
        KeyValueStore::set(nil, storageKey, unixtime)
        unixtime
    end

    # ------------------------------------------------------------

    # Cubes::selectCubeFromExistingOrNull()
    def self.selectCubeFromExistingOrNull()
        cubes = Cubes::cubes()
        selected = CatalystCommon::chooseALinePecoStyle("select cube (empty for null)", [""] + cubes.reverse.map{|cube| Cubes::cubeToString(cube) })
        return nil if selected == ""
        cubes.select{|c| selected == Cubes::cubeToString(c) }.first
    end

    # Cubes::getCubeDescriptionOrFirstQuarkToString(cube)
    def self.getCubeDescriptionOrFirstQuarkToString(cube)
        if cube["description"] then
            cube["description"]
        else
            quark = Cubes::getCubeFirstQuarkOrNull(cube)
            if quark then
                Quark::quarkToString(quark)
            else
                "[cube with no description and no quark]"
            end
        end
    end

    # Cubes::cubeToString(cube)
    def self.cubeToString(cube)
        "[cube] [#{cube["uuid"][0, 4]}] #{Cubes::getCubeDescriptionOrFirstQuarkToString(cube)}"
    end

    # Cubes::cubeDive(cube)
    def self.cubeDive(cube)
        loop {
            system("clear")
            cube = NyxIO::getOrNull(cube["uuid"]) # useful if we have modified it
            return if cube.nil? # useful if we have just destroyed it

            puts "Cube:"
            puts "    description: #{Cubes::getCubeDescriptionOrFirstQuarkToString(cube)}".green
            puts "    uuid: #{cube["uuid"]}"

            items = []

            Links::getLinkedObjects(cube)
                .sort{|o1, o2| NyxDataCarriers::objectLastActivityUnixtime(o1) <=> NyxDataCarriers::objectLastActivityUnixtime(o2) }
                .each{|object| items << [NyxDataCarriers::objectToString(object), lambda{ NyxDataCarriers::objectDive(object) }] }

            items << nil

            NyxRoles::getRolesForTarget(cube["uuid"])
                .each{|object| items << [NyxRoles::objectToString(object), lambda{ NyxRoles::objectDive(object) }] }

            items << nil

            items << [
                "cube (edit description)", 
                lambda{
                    description = CatalystCommon::editTextUsingTextmate(cube["description"]).strip
                    if description == "" or description.lines.to_a.size != 1 then
                        puts "Descriptions should be one non empty line"
                        LucilleCore::pressEnterToContinue()
                        return
                    end
                    cube["description"] = description
                    NyxIO::commitToDisk(cube)
                }]
            items << [
                "cube (unset description)", 
                lambda{
                    cube.delete("description")
                    NyxIO::commitToDisk(cube)
                }]
            items << [
                "quark (add new)", 
                lambda{
                    quark = Quark::issueNewQuarkInteractivelyOrNull()
                    return if quark.nil?
                    link = Links::issueLink(cube, quark)
                    puts JSON.pretty_generate(link)
                    Cubes::forgetCachedLastActivityUnixtime(cube)
                }]
            items << [
                "quark (select and remove)", 
                lambda{
                    quark = LucilleCore::selectEntityFromListOfEntitiesOrNull("quark", Cubes::getCubeQuarks(cube), lambda { |quark| Quark::quarkToString(quark) })
                    return if quark.nil?
                    Links::destroyLink(cube, quark)
                }]
            items << [
                "tags (add new)", 
                lambda{
                    puts "TODO: This function is not implemented yet"
                    LucilleCore::pressEnterToContinue()
                }]
            items << [
                "tags (remove)", 
                lambda{
                    puts "TODO: This function is not implemented yet"
                    LucilleCore::pressEnterToContinue()
                }]
            items << [
                "clique (select and link to)", 
                lambda{
                    clique = Cliques::selectCliqueOrMakeNewOneOrNull()
                    next if clique.nil?
                    Links::issueLink(clique, cube)
                }]
            items << [
                "opencycle (register as)", 
                lambda{
                    claim = {
                        "uuid"             => SecureRandom.uuid,
                        "nyxType"          => "open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f",
                        "creationUnixtime" => Time.new.to_f,
                        "quarkuuid"       => cube["uuid"],
                    }
                    puts JSON.pretty_generate(claim)
                    NyxIO::commitToDisk(claim)
                }]
            items << [
                "cube (destroy)", 
                lambda{
                    if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of this thing ? ") then
                        NyxIO::destroy(cube["uuid"])
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
                puts "TODO: This case is not yet implemented"
                LucilleCore::pressEnterToContinue()
                next
                oldname = LucilleCore::askQuestionAnswerAsString("old name (capilisation doesn't matter): ")
                next if oldname.size == 0
                newname = LucilleCore::askQuestionAnswerAsString("new name: ")
                next if newname.size == 0
            end
            if operation == "cube dive (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                cube = NyxIO::getOrNull(uuid)
                if cube then
                    Cubes::cubeDive(cube)
                else
                    puts "Could not find cube for uuid (#{uuid})"
                end
            end
            if operation == "repair json (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                cube = NyxIO::getOrNull(uuid)
                if cube then
                    cubejson = CatalystCommon::editTextUsingTextmate(JSON.pretty_generate(cube))
                    cube = JSON.parse(cubejson)
                    NyxIO::commitToDisk(cube)
                else
                    puts "Could not find cube for uuid (#{uuid})"
                end
            end
            if operation == "make new cube" then
                Cubes::issueQuarkCubeInteractivelyWithCliqueInviteOrNull()
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
                cube = NyxIO::getOrNull(uuid)
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
        Tags::tags()
            .select{|tag| tag["payload"].downcase.include?(searchPattern.downcase)}
            .map{|tag| tag["payload"] }
    end

    # CubeSearch::searchPatternToCubes(searchPattern)
    def self.searchPatternToCubes(searchPattern)
        Cubes::cubes()
            .select{|cube| Cubes::getCubeDescriptionOrFirstQuarkToString(cube).downcase.include?(searchPattern.downcase) }
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
                    tagPayload = object["tag"]
                    return [ "tag: #{tagPayload}" , lambda { Tags::tagPayloadDive(tagPayload) } ]
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
