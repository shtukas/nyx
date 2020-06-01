
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/PrimaryNetwork.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoint.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

# -----------------------------------------------------------------

class PrimaryNetwork

    # PrimaryNetwork::getSomethingByUuidOrNull(uuid)
    def self.getSomethingByUuidOrNull(uuid)
        target = Nyx::getOrNull(uuid)
        return target if target
        clique = Nyx::getOrNull(uuid)
        return clique if clique
        starlightnode = Nyx::getOrNull(uuid)
        return starlightnode if starlightnode
        nil
    end

    # PrimaryNetwork::somethingToString(something)
    def self.somethingToString(something)
        if something["nyxType"] == "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            return DataPoint::dataPointToString(something)
        end
        if something["nyxType"] == "clique-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            return Cliques::cliqueToString(something)
        end
        if something["nyxType"] == "starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            return StarlightNodes::nodeToString(something)
        end
        raise "PrimaryNetwork::somethingToString, Error: 056686f0"
    end

    # PrimaryNetwork::openSomething(something)
    # open means bypass the menu and metadata and give me access to the data as quickly as possible
    def self.openSomething(something)
        if something["nyxType"] == "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            target = something
            DataPoint::openDataPoint(target)
            return
        end
        if something["nyxType"] == "clique-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            clique = something
            Cliques::openClique(clique)
            return
        end
        if something["nyxType"] == "starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
           node = something
           StarlightUserInterface::nodeDive(node)
           return
        end
        raise "PrimaryNetwork::somethingToString, Error: 2f28f27d"
    end

    # PrimaryNetwork::visitSomething(something)
    def self.visitSomething(something)
        if something["nyxType"] == "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            DataPoint::diveDataPoint(something)
            return
        end
        if something["nyxType"] == "clique-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            Cliques::cliqueDive(something)
            return
        end
        if something["nyxType"] == "starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            StarlightUserInterface::nodeDive(something)
            return
        end
        raise "PrimaryNetwork::somethingToString, Error: cf25ea33"
    end
end

class PrimaryNetworkNavigation

    # PrimaryNetworkNavigation::mainNavigation()
    def self.mainNavigation()
        loop {
            options = [
                "navigate nodes",
                "navigate cliques",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
            return if option.nil?
            if option == "navigate nodes" then
                StarlightUserInterface::navigation()
            end
            if option == "navigate cliques" then
                CliquesNavigation::mainNavigation()
            end
        }
    end

    # PrimaryNetworkNavigation::visit(something)
    def self.visit(something)
        if something["nyxType"] == "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            target = something
            return DataPoint::diveDataPoint(target)
        end
        if something["nyxType"] == "clique-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            clique = something
            return Cliques::cliqueDive(clique)
        end
        if something["nyxType"] == "starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            node = something
            return StarlightUserInterface::nodeDive(node)
        end
        raise "PrimaryNetwork::somethingToString, Error: f17aba25"
    end
end

class PrimaryNetworkMakeAndOrSelectQuest

    # PrimaryNetworkMakeAndOrSelectQuest::makeAndOrSelectSomethingOrNull()
    def self.makeAndOrSelectSomethingOrNull()
        loop {
            puts "-> You are on a selection Quest [making and/or selecting a node or clique]"
            options = [
                "making and/or selecting a node",
                "making and/or selecting a clique",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
            if option.nil? then
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to quit select something and return nothing ? ") then
                    return nil
                else
                    next
                end
            end
            if option == "making and/or selecting a node" then
                something = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                if something then
                    return something
                else 
                    puts "You are on a selection Quest, and chose nodes, but didn't select any. back to square one (you can return null there)"
                    LucilleCore::pressEnterToContinue()
                    next
                end
            end
            if option == "making and/or selecting a clique" then
                something = CliquesMakeAndOrSelectQuest::makeAndOrSelectCliqueOrNull()
                if something then
                    return something
                else 
                    puts "You are on a selection Quest, and chose cliques, but didn't select any. back to square one (you can return null there)"
                    LucilleCore::pressEnterToContinue()
                    next
                end
            end
        }
    end
end
