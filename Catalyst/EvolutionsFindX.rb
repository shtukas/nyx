
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/EvolutionsFindX.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Bank.rb"
=begin 
    Bank::put(uuid, weight)
    Bank::total(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTargets.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoints.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Multiverse.rb"

# -----------------------------------------------------------------

$EvolutionsFindXSingleton = nil 
    # This is the global variable that contains the most recently selected entity
    # For the moment we limit to data entities

class EvolutionsFindX

    # EvolutionsFindX is very simple. We want to be able to find things and return them.
    # We can return any of: CatalystStandardTarget, DataPoint, StarlightNode
    # EvolutionsFindX::selectOrNull()
    def self.selectOrNull()
        $EvolutionsFindXSingleton = nil
        options = [
            "select starlight node",
            "select datapoint",
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
        return nil if option.nil? 
        if option == "select starlight node" then
            node = StarlightNetwork::selectOrNull()
            if node then
                return node
            end
        end
        if option == "select datapoint" then
            datapoint = DataPointsEvolved::searchDiveAndSelect()
            if datapoint then
                return datapoint
            end
        end
        if LucilleCore::askQuestionAnswerAsBoolean("EvolutionsFindX: Would you like to make a new node and return it ? ", false) then
            return Timelines::makeTimelineInteractivelyOrNull(true)
        end
        if LucilleCore::askQuestionAnswerAsBoolean("EvolutionsFindX: Would you like to make a new datapoint and return it ? ", false) then
            return DataPoints::issueDataPointInteractivelyOrNull(true)
        end
        if LucilleCore::askQuestionAnswerAsBoolean("EvolutionsFindX: No selection. Return null ? ", true) then
            return nil
        end
        EvolutionsFindX::selectOrNull()
    end

    # EvolutionsFindX::navigate()
    def self.navigate()
        options = [
            "select starlight node",
            "select datapoint",
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
        return nil if option.nil? 
        if option == "select starlight node" then
            StarlightNetwork::navigate()
        end
        if option == "select datapoint" then
            DataPointsEvolved::navigate()
        end
    end
end
