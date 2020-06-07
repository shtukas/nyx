
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/QuarksCubesAndOrbitals.rb"

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

class QuarksCubesAndOrbitals

    # QuarksCubesAndOrbitals::getObjectByUuidOrNull(uuid)
    def self.getObjectByUuidOrNull(uuid)
        target = Nyx::getOrNull(uuid)
        return target if target
        cube = Nyx::getOrNull(uuid)
        return cube if cube
        orbital = Nyx::getOrNull(uuid)
        return orbital if orbital
        nil
    end

    # QuarksCubesAndOrbitals::objectToString(entity)
    def self.objectToString(entity)
        if entity["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            return Quark::quarkToString(entity)
        end
        if entity["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            return Cube::cubeToString(entity)
        end
        if entity["nyxType"] == "orbital-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            return Orbitals::orbitalToString(entity)
        end
        raise "QuarksCubesAndOrbitals::objectToString, Error: 056686f0"
    end

    # QuarksCubesAndOrbitals::openObject(entity)
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
        if entity["nyxType"] == "orbital-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
           orbital = entity
           StarlightUserInterface::orbitalDive(orbital)
           return
        end
        raise "QuarksCubesAndOrbitals::objectToString, Error: 2f28f27d"
    end

    # QuarksCubesAndOrbitals::objectDive(entity)
    def self.objectDive(entity)
        if entity["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            Quark::quarkDive(entity)
            return
        end
        if entity["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            Cube::cubeDive(entity)
            return
        end
        if entity["nyxType"] == "orbital-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            StarlightUserInterface::orbitalDive(entity)
            return
        end
        raise "QuarksCubesAndOrbitals::objectToString, Error: cf25ea33"
    end
end

class QuarksCubesAndOrbitalsNavigation

    # QuarksCubesAndOrbitalsNavigation::navigation()
    def self.navigation()
        loop {
            options = [
                "navigate orbitals",
                "navigate cubes",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
            return if option.nil?
            if option == "navigate orbitals" then
                StarlightUserInterface::navigation()
            end
            if option == "navigate cubes" then
                CubeUserInterface::navigation()
            end
        }
    end

    # QuarksCubesAndOrbitalsNavigation::visit(entity)
    def self.visit(entity)
        if entity["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            target = entity
            return Quark::quarkDive(target)
        end
        if entity["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            cube = entity
            return Cube::cubeDive(cube)
        end
        if entity["nyxType"] == "orbital-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            orbital = entity
            return StarlightUserInterface::orbitalDive(orbital)
        end
        raise "QuarksCubesAndOrbitals::objectToString, Error: f17aba25"
    end
end

class QuarksCubesAndOrbitalsMakeAndOrSelectQuest

    # QuarksCubesAndOrbitalsMakeAndOrSelectQuest::makeAndOrSelectSomethingOrNull()
    def self.makeAndOrSelectSomethingOrNull()
        loop {
            puts "-> You are on a selection Quest [making and/or selecting an orbital or cube]"
            options = [
                "making and/or selecting an orbital",
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
            if option == "making and/or selecting an orbital" then
                entity = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectOrbitalOrNull()
                if entity then
                    return entity
                else 
                    puts "You are on a selection Quest, and chose orbitals, but didn't select any. back to square one (you can return null there)"
                    LucilleCore::pressEnterToContinue()
                    next
                end
            end
            if option == "making and/or selecting a cube" then
                entity = CubeMakeAndOrSelectQuest::makeAndOrSelectCubeOrNull()
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
