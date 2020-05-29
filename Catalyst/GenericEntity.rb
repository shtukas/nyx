
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/GenericEntity.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/A10495.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Multiverse.rb"

# -----------------------------------------------------------------

$GenericEntityQuestSelectionKey = SecureRandom.hex

class GenericEntity

    # A generic Entity is either:
    #    - A10495
    #    - Clique
    #    - Timeline

    # GenericEntity::getSomethingByUuidOrNull(uuid)
    def self.getSomethingByUuidOrNull(uuid)
        target = A10495::getOrNull(uuid)
        return target if target
        clique = Cliques::getOrNull(uuid)
        return clique if clique
        starlightnode = Timelines::getOrNull(uuid)
        retun starlightnode if starlightnode
        nil
    end

    # GenericEntity::somethingToString(something)
    def self.somethingToString(something)
        if something["catalystType"] == "catalyst-type:10014e93" then
            return A10495::targetToString(something)
        end
        if something["catalystType"] == "catalyst-type:clique"  then
            return Cliques::cliqueToString(something)
        end
        if something["catalystType"] == "catalyst-type:timeline"  then
            return Timelines::timelineToString(something)
        end
        raise "GenericEntity::somethingToString, Error: 056686f0"
    end

    # GenericEntity::openSomething(something)
    # open means bypass the menu and metadata and give me access to the data as quickly as possible
    def self.openSomething(something)
        if something["catalystType"] == "catalyst-type:10014e93" then
            target = something
            A10495::openTarget(target)
            return
        end
        if something["catalystType"] == "catalyst-type:clique"  then
            clique = something
            Cliques::openClique(clique)
            return
        end
        if something["catalystType"] == "catalyst-type:timeline"  then
           timeline = something
           Multiverse::openTimeline(timeline)
           return
        end
        raise "GenericEntity::somethingToString, Error: 2f28f27d"
    end

    # GenericEntity::visitSomething(something)
    def self.visitSomething(something)
        if something["catalystType"] == "catalyst-type:10014e93" then
            A10495::visitTarget(something)
            return
        end
        if something["catalystType"] == "catalyst-type:clique"  then
            Cliques::visitClique(something)
            return
        end
        if something["catalystType"] == "catalyst-type:timeline"  then
            Multiverse::visitTimeline(something)
            return
        end
        raise "GenericEntity::somethingToString, Error: cf25ea33"
    end

end

class GenericEntityNavigation

    # GenericEntityNavigation::generalNavigation()
    def self.generalNavigation()
        loop {
            options = [
                "navigate timelines",
                "navigate cliques",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
            return if option.nil?
            if option == "navigate timelines" then
                MultiverseNavigation::generalNavigation()
            end
            if option == "start at cliques" then
                CliquesSelection::generalNavigation()
            end
        }
    end

    # GenericEntityNavigation::visit(something)
    def self.visit(something)
        if something["catalystType"] == "catalyst-type:10014e93" then
            target = something
            return A10495Navigation::visit(target)
        end
        if something["catalystType"] == "catalyst-type:clique"  then
            clique = something
            return CliquesSelection::onASomethingSelectionQuest(clique)
        end
        if something["catalystType"] == "catalyst-type:timeline"  then
            timeline = something
            return MultiverseSelection::onASomethingSelectionQuest(timeline)
        end
        puts something
        raise "GenericEntity::somethingToString, Error: f17aba25"
    end
end

class GenericEntitySearch

    # GenericEntitySearch::selectSomethingOrNull()
    def self.selectSomethingOrNull()
        loop {
            $GenericEntityQuestSelectionKey = SecureRandom.hex
            puts "-> You are on a selection Quest".green
            options = [
                "start at timelines",
                "start at cliques",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
            if option.nil? then
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to quit select something and return nothing ? ") then
                    return nil
                else
                    next
                end
            end
            if option == "start at timelines" then
                something = MultiverseSelection::selectSomethingOrNull()
                if something then
                    return something
                end
            end
            if option == "start at cliques" then
                something = CliquesSelection::selectSomethingOrNull()
                if something then
                    return something
                end
            end
        }
    end

    # GenericEntitySearch::onASomethingSelectionQuest(something)
    def self.onASomethingSelectionQuest(something)
        puts "-> You are on a selection Quest".green
        # We either return null of a something
        if something["catalystType"] == "catalyst-type:10014e93" then
            return A10495Selection::onASomethingSelectionQuest(something)
        end
        if something["catalystType"] == "catalyst-type:clique"  then
            return CliquesSelection::onASomethingSelectionQuest(something)
        end
        if something["catalystType"] == "catalyst-type:timeline"  then
            return MultiverseSelection::onASomethingSelectionQuest(something)
        end
        puts something
        raise "GenericEntity::somethingToString, Error: bc9fd6cb"
    end
end
