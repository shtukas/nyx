
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/QuarksCubesAndStarlightNodes.rb"

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
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cube.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

# -----------------------------------------------------------------

class QuarksCubesAndStarlightNodes

    # QuarksCubesAndStarlightNodes::getObjectByUuidOrNull(uuid)
    def self.getObjectByUuidOrNull(uuid)
        target = Nyx::getOrNull(uuid)
        return target if target
        cube = Nyx::getOrNull(uuid)
        return cube if cube
        starlightnode = Nyx::getOrNull(uuid)
        return starlightnode if starlightnode
        nil
    end

    # QuarksCubesAndStarlightNodes::objectToString(entity)
    def self.objectToString(entity)
        if entity["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            return Quark::quarkToString(entity)
        end
        if entity["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            return Cube::cubeToString(entity)
        end
        if entity["nyxType"] == "starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            return StarlightNodes::nodeToString(entity)
        end
        raise "QuarksCubesAndStarlightNodes::objectToString, Error: 056686f0"
    end

    # QuarksCubesAndStarlightNodes::openObject(entity)
    # open means bypass the menu and metadata and give me access to the data as quickly as possible
    def self.openObject(entity)
        if entity["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            target = entity
            Quark::openQuark(target)
            return
        end
        if entity["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            cube = entity
            Cube::openCube(cube)
            return
        end
        if entity["nyxType"] == "starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
           node = entity
           StarlightUserInterface::nodeDive(node)
           return
        end
        raise "QuarksCubesAndStarlightNodes::objectToString, Error: 2f28f27d"
    end

    # QuarksCubesAndStarlightNodes::objectDive(entity)
    def self.objectDive(entity)
        if entity["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            Quark::quarkDive(entity)
            return
        end
        if entity["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            Cube::cubeDive(entity)
            return
        end
        if entity["nyxType"] == "starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            StarlightUserInterface::nodeDive(entity)
            return
        end
        raise "QuarksCubesAndStarlightNodes::objectToString, Error: cf25ea33"
    end
end

class QuarksCubesAndStarlightNodesNavigation

    # QuarksCubesAndStarlightNodesNavigation::mainNavigation()
    def self.mainNavigation()
        loop {
            options = [
                "navigate nodes",
                "navigate cubes",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
            return if option.nil?
            if option == "navigate nodes" then
                StarlightUserInterface::navigation()
            end
            if option == "navigate cubes" then
                CubesNavigation::mainNavigation()
            end
        }
    end

    # QuarksCubesAndStarlightNodesNavigation::visit(entity)
    def self.visit(entity)
        if entity["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            target = entity
            return Quark::quarkDive(target)
        end
        if entity["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            cube = entity
            return Cube::cubeDive(cube)
        end
        if entity["nyxType"] == "starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            node = entity
            return StarlightUserInterface::nodeDive(node)
        end
        raise "QuarksCubesAndStarlightNodes::objectToString, Error: f17aba25"
    end
end

class QuarksCubesAndStarlightNodesMakeAndOrSelectQuest

    # QuarksCubesAndStarlightNodesMakeAndOrSelectQuest::makeAndOrSelectSomethingOrNull()
    def self.makeAndOrSelectSomethingOrNull()
        loop {
            puts "-> You are on a selection Quest [making and/or selecting a node or cube]"
            options = [
                "making and/or selecting a node",
                "making and/or selecting a cube",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
            if option.nil? then
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to quit select entity and return nothing ? ") then
                    return nil
                else
                    next
                end
            end
            if option == "making and/or selecting a node" then
                entity = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                if entity then
                    return entity
                else 
                    puts "You are on a selection Quest, and chose nodes, but didn't select any. back to square one (you can return null there)"
                    LucilleCore::pressEnterToContinue()
                    next
                end
            end
            if option == "making and/or selecting a cube" then
                entity = CubesMakeAndOrSelectQuest::makeAndOrSelectCubeOrNull()
                if entity then
                    return entity
                else 
                    puts "You are on a selection Quest, and chose cubes, but didn't select any. back to square one (you can return null there)"
                    LucilleCore::pressEnterToContinue()
                    next
                end
            end
        }
    end
end
