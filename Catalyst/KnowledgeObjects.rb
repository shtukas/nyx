
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/KnowledgeObjects.rb"

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
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cubes.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cliques.rb"

# -----------------------------------------------------------------

class KnowledgeObjects

    # KnowledgeObjects::getObjectOrNull(uuid)
    def self.getObjectOrNull(uuid)
        [ Cubes::getOrNull(uuid), Cliques::getOrNull(uuid) ].compact.first
    end

    # KnowledgeObjects::objectToString(entity)
    def self.objectToString(entity)
        if entity["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            return Cubes::cubeToString(entity)
        end
        if entity["nyxType"] == "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            return Cliques::cliqueToString(entity)
        end
        raise "Error: 056686f0"
    end

    # KnowledgeObjects::openObject(entity)
    def self.openObject(entity)
        if entity["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            cube = entity
            Cubes::openCube(cube)
            return
        end
        if entity["nyxType"] == "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
           clique = entity
           Cliques::cliqueDive(clique)
           return
        end
        raise "Error: 2f28f27d"
    end

    # KnowledgeObjects::objectDive(entity)
    def self.objectDive(entity)
        if entity["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            Cubes::cubeDive(entity)
            return
        end
        if entity["nyxType"] == "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            Cliques::cliqueDive(entity)
            return
        end
        raise "Error: cf25ea33"
    end
end
