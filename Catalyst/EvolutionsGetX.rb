
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/EvolutionsGetX.rb"

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
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

# -----------------------------------------------------------------

$EvolutionsGetXSingleton = nil 
    # This is the global variable that contains the most recently selected entity
    # For the moment we limit to data entities

class EvolutionsGetX

    # EvolutionsGetX is very simple. We want to be able to find things and return them.
    # The search should be clever in the sense that we want to be able to modify and add things while searching before returning
    # We can return any of: CatalystStandardTarget, DataPoint, StarlightNode
    # One can specify which type they limit their search to

    # EvolutionsGetX::selectOrNull(types)
    # types = Array[DataEntityType]
    # DataEntityType = "catalyst-type:catalyst-standard-target" | "catalyst-type:datapoint" | "catalyst-type:starlight-node"
    # EvolutionsGetX::selectOrNull(["catalyst-type:catalyst-standard-target", "catalyst-type:datapoint", "catalyst-type:starlight-node"])
    def self.selectOrNull(types)
        $EvolutionsGetXSingleton = nil
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
        if LucilleCore::askQuestionAnswerAsBoolean("EvolutionsGetX: Would you like to make a new node and return it ? ", false) then
            return StartlightNodes::makeNodeInteractivelyOrNull(true)
        end
        if LucilleCore::askQuestionAnswerAsBoolean("EvolutionsGetX: Would you like to make a new datapoint and return it ? ", false) then
            return DataPoints::issueDataPointInteractivelyOrNull(true)
        end
        if LucilleCore::askQuestionAnswerAsBoolean("EvolutionsGetX: No selection. Return null ? ", true) then
            return nil
        end
        EvolutionsGetX::selectOrNull(types)
    end
end
