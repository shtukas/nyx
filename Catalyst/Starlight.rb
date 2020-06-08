# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/QuarksCubesAndOrbitals.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Nyx.rb"

# -----------------------------------------------------------------

class Orbitals

    # Orbitals::makeOrbitalInteractivelyOrNull()
    def self.makeOrbitalInteractivelyOrNull()
        puts "Making a new Orbital..."
        orbital = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "orbital-8826cbad-e54e-4e78-bf7d-28c9c5019721",
            "creationUnixtime" => Time.new.to_f,

            "name"             => LucilleCore::askQuestionAnswerAsString("orbitalname: ")
        }
        Nyx::commitToDisk(orbital)
        puts JSON.pretty_generate(orbital)
        orbital
    end

    # Orbitals::orbitalToString(orbital)
    def self.orbitalToString(orbital)
        "[orbital] [#{orbital["uuid"][0, 4]}] #{orbital["name"]}"
    end

    # Orbitals::getOrNull(uuid)
    def self.getOrNull(uuid)
        Nyx::getOrNull(uuid)
    end

    # Orbitals::orbitals()
    def self.orbitals()
        Nyx::objects("orbital-8826cbad-e54e-4e78-bf7d-28c9c5019721")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end
end

class StarlightPaths

    # StarlightPaths::issuePathInteractivelyOrNull()
    def self.issuePathInteractivelyOrNull()
        path = {
            "nyxType"          => "starlight-vector-3d68c8f4-57ba-4678-a85b-9de995f8667e",
            "creationUnixtime" => Time.new.to_f,
            "uuid"             => SecureRandom.uuid,

            "sourceuuid"       => LucilleCore::askQuestionAnswerAsString("sourceuuid: "),
            "targetuuid"       => LucilleCore::askQuestionAnswerAsString("targetuuid: ")
        }
        Nyx::commitToDisk(path)
        path
    end

    # StarlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(orbital1, orbital2)
    def self.issuePathFromFirstNodeToSecondNodeOrNull(orbital1, orbital2)
        return nil if orbital1["uuid"] == orbital2["uuid"]
        path = {
            "nyxType"          => "starlight-vector-3d68c8f4-57ba-4678-a85b-9de995f8667e",
            "creationUnixtime" => Time.new.to_f,
            "uuid"             => SecureRandom.uuid,
            "sourceuuid"       => orbital1["uuid"],
            "targetuuid"       => orbital2["uuid"]
        }
        Nyx::commitToDisk(path)
        path
    end

    # StarlightPaths::getPathsWithGivenTarget(targetuuid)
    def self.getPathsWithGivenTarget(targetuuid)
        Nyx::objects("starlight-vector-3d68c8f4-57ba-4678-a85b-9de995f8667e")
            .select{|path| path["targetuuid"] == targetuuid }
    end

    # StarlightPaths::getPathsWithGivenSource(sourceuuid)
    def self.getPathsWithGivenSource(sourceuuid)
        Nyx::objects("starlight-vector-3d68c8f4-57ba-4678-a85b-9de995f8667e")
            .select{|path| path["sourceuuid"] == sourceuuid }
    end

    # StarlightPaths::pathToString(path)
    def self.pathToString(path)
        "[stargate] #{path["sourceuuid"]} -> #{path["targetuuid"]}"
    end

    # StarlightPaths::getParents(orbital)
    def self.getParents(orbital)
        StarlightPaths::getPathsWithGivenTarget(orbital["uuid"])
            .map{|path| Nyx::getOrNull(path["sourceuuid"]) }
            .compact
    end

    # StarlightPaths::getChildren(orbital)
    def self.getChildren(orbital)
        StarlightPaths::getPathsWithGivenSource(orbital["uuid"])
            .map{|path| Nyx::getOrNull(path["targetuuid"]) }
            .compact
    end
end

class OrbitalInventory

    # OrbitalInventory::issueClaim(orbital, cube)
    def self.issueClaim(orbital, cube)
        raise "6df08321" if cube["nyxType"] != "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"
        claim = {
            "nyxType"          => "orbital-inventory-claim-b38137c1-fd43-4035-9f2c-af0fddb18c80",
            "creationUnixtime" => Time.new.to_f,
            "uuid"             => SecureRandom.uuid,

            "orbitaluuid"         => orbital["uuid"],
            "cubeuuid"         => cube["uuid"]
        }
        Nyx::commitToDisk(claim)
        claim
    end

    # OrbitalInventory::claimToString(dataclaim)
    def self.claimToString(dataclaim)
        "[starlight ownership claim] #{dataclaim["orbitaluuid"]} -> #{dataclaim["cubeuuid"]}"
    end

    # OrbitalInventory::getCubes(orbital)
    def self.getCubes(orbital)
        Nyx::objects("orbital-inventory-claim-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .select{|claim| claim["orbitaluuid"] == orbital["uuid"] }
            .map{|claim| Cube::getOrNull(claim["cubeuuid"]) }
            .compact
    end

    # OrbitalInventory::getOrbitals(cube)
    def self.getOrbitals(cube)
        Nyx::objects("orbital-inventory-claim-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .select{|claim| claim["cubeuuid"] == cube["uuid"] }
            .map{|claim| Nyx::getOrNull(claim["orbitaluuid"]) }
            .compact
    end

    # OrbitalInventory::claims()
    def self.claims()
        Nyx::objects("orbital-inventory-claim-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end
end

class StarlightUserInterface

    # StarlightUserInterface::selectOrbitalFromExistingOrbitals()
    def self.selectOrbitalFromExistingOrbitals()
        orbitalstrings = Orbitals::orbitals().map{|orbital| Orbitals::orbitalToString(orbital) }
        orbitalstring = CatalystCommon::chooseALinePecoStyle("orbital:", [""]+orbitalstrings)
        Orbitals::orbitals()
            .select{|orbital| Orbitals::orbitalToString(orbital) == orbitalstring }
            .first
    end

    # StarlightUserInterface::selectOrbitalFromExistingOrCreateOneOrNull()
    def self.selectOrbitalFromExistingOrCreateOneOrNull()
        puts "-> You are selecting a orbital (possibly will create one)"
        LucilleCore::pressEnterToContinue()
        orbital = StarlightUserInterface::selectOrbitalFromExistingOrbitals()
        return orbital if orbital
        if LucilleCore::askQuestionAnswerAsBoolean("Multiverse: You are being selecting an orbital but did not select any of the existing ones. Would you like to make a new orbital and return it ? ") then
            return Orbitals::makeOrbitalInteractivelyOrNull()
        end
        nil
    end

    # StarlightUserInterface::orbitalDive(orbital)
    def self.orbitalDive(orbital)
        loop {
            system("clear")
            puts ""
            puts "uuid: #{orbital["uuid"]}"
            puts Orbitals::orbitalToString(orbital).green
            items = []

            StarlightPaths::getParents(orbital)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["[-> *] #{Orbitals::orbitalToString(n)}", lambda{ StarlightUserInterface::orbitalDive(n) }] }

            StarlightPaths::getChildren(orbital)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["[* ->] #{Orbitals::orbitalToString(n)}", lambda{ StarlightUserInterface::orbitalDive(n) }] }

            items << nil

            OrbitalInventory::getCubes(orbital)
                .sort{|p1, p2| p1["creationUnixtime"] <=> p2["creationUnixtime"] } # "creationUnixtime" is a common attribute of all data entities
                .each{|cube| items << [Cube::cubeToString(cube), lambda{ Cube::cubeDive(cube) }] }

            items << nil

            items << ["rename", lambda{ 
                orbital["name"] = CatalystCommon::editTextUsingTextmate(orbital["name"]).strip
                Nyx::commitToDisk(orbital)
            }]

            items << ["add parent orbital", lambda{ 
                orbital0 = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectOrbitalOrNull()
                return if orbital0.nil?
                path = StarlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(orbital0, orbital)
                return if path.nil?
                puts JSON.pretty_generate(path)
                Nyx::commitToDisk(path)
            }]

            items << ["add child orbital", lambda{ 
                orbital2 = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectOrbitalOrNull()
                path = StarlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(orbital, orbital2)
                return if path.nil?
                puts JSON.pretty_generate(path)
                Nyx::commitToDisk(path)
            }]

            items << ["add cube (from existing)", lambda{ 
                cube = Cube::selectCubeFromExistingOrNull()
                return if cube.nil?
                OrbitalInventory::issueClaim(orbital, cube)
            }]

            items << ["-> cube (new) -> quark (new)", lambda{ 
                puts "Let's make a cube"
                description = LucilleCore::askQuestionAnswerAsString("cube description: ")
                cube = Cube::issueCube_v3(description)
                puts JSON.pretty_generate(cube)
                puts "Let's attach the cube to the orbital"
                claim = OrbitalInventory::issueClaim(orbital, cube)
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

    # StarlightUserInterface::listingAndSelection()
    def self.listingAndSelection()
        orbital = StarlightUserInterface::selectOrbitalFromExistingOrbitals()
        return if orbital.nil?
        StarlightUserInterface::orbitalDive(orbital)
    end

    # StarlightUserInterface::starlightNavigationAtOrbital(orbital)
    def self.starlightNavigationAtOrbital(orbital)
        loop {
            system("clear")
            puts ""
            puts "uuid: #{orbital["uuid"]}"
            puts Orbitals::orbitalToString(orbital).green
            items = []

            StarlightPaths::getParents(orbital)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["[network parent] #{Orbitals::orbitalToString(n)}", lambda{ StarlightUserInterface::starlightNavigationAtOrbital(n) }] }

            items << nil

            StarlightPaths::getChildren(orbital)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["[network child] #{Orbitals::orbitalToString(n)}", lambda{ StarlightUserInterface::starlightNavigationAtOrbital(n) }] }

            items << nil

            items << ["dive orbital", lambda{ 
                StarlightUserInterface::orbitalDive(orbital)
            }]

            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

    # StarlightUserInterface::navigation()
    def self.navigation()
        loop {
            system("clear")
            puts ""
            orbitals = Orbitals::orbitals()
                        .select{|orbital| StarlightPaths::getPathsWithGivenTarget(orbital["uuid"]).empty? }
            orbital = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", orbitals, lambda{|orbital| Orbitals::orbitalToString(orbital) })
            return if orbital.nil?
            StarlightUserInterface::starlightNavigationAtOrbital(orbital)
        }
    end

    # StarlightUserInterface::main()
    def self.main()
        loop {
            system("clear")
            puts "Starlight Management (root)"
            operations = [
                "make orbital",
                "make starlight path"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "make orbital" then
                orbital = Orbitals::makeOrbitalInteractivelyOrNull()
                puts JSON.pretty_generate(orbital)
                Nyx::commitToDisk(orbital)
            end
            if operation == "make starlight path" then
                orbital1 = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectOrbitalOrNull()
                next if orbital1.nil?
                orbital2 = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectOrbitalOrNull()
                next if orbital2.nil?
                path = StarlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(orbital1, orbital2)
                next if path.nil?
                puts JSON.pretty_generate(path)
                Nyx::commitToDisk(path)
            end
        }
    end
end

class StarlightMakeAndOrSelectNodeQuest

    # StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectOrbitalOrNull()
    def self.makeAndOrSelectOrbitalOrNull()
        puts "-> You are on a selection Quest [selecting an orbital]"
        puts "-> I am going to make you select one from existing and if that doesn't work, I will make you create a new one [with extensions if you want]"
        LucilleCore::pressEnterToContinue()
        orbital = StarlightUserInterface::selectOrbitalFromExistingOrbitals()
        return orbital if orbital
        puts "-> You are on a selection Quest [selecting an orbital]"
        if LucilleCore::askQuestionAnswerAsBoolean("-> ...but did not select anything. Do you want to create one ? ") then
            orbital = Orbitals::makeOrbitalInteractivelyOrNull()
            return nil if orbital.nil?
            puts "-> You are on a selection Quest [selecting an orbital]"
            puts "-> You have created '#{orbital["name"]}'"
            loop {
                option1 = "quest: return '#{orbital["name"]}' immediately"
                option2 = "quest: dive first"
                options = [ option1, option2 ]
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
                if option == option1 then
                    return orbital
                end
                if option == option2 then
                    StarlightUserInterface::orbitalDive(orbital)
                end
            }
        end
        nil
    end
end

