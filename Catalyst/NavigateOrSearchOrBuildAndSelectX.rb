
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/NavigateOrSearchOrBuildAndSelectX.rb"

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

$NavigateOrSearchOrBuildAndSelectXSingleton = nil 
    # This is the global variable that contains the most recently selected entity
    # For the moment we limit to data entities

class NavigateOrSearchOrBuildAndSelectX

    # NavigateOrSearchOrBuildAndSelectX is very simple. We want to be able to find things and return them.
    # The search should be clever in the sense that we want to be able to modify and add things while searching before returning
    # We can return any of: CatalystStandardTarget, DataPoint, StarlightNode
    # One can specify which type they limit their search to

    # NavigateOrSearchOrBuildAndSelectX::selectOrNull(types)
    # types = Array[DataEntityType]
    # DataEntityType = "catalyst-type:catalyst-standard-target" | "catalyst-type:datapoint" | "catalyst-type:starlight-node"
    # NavigateOrSearchOrBuildAndSelectX::selectOrNull(["catalyst-type:catalyst-standard-target", "catalyst-type:datapoint", "catalyst-type:starlight-node"])
    def self.selectOrNull(types)
        loop {
            system("clear")
            puts "Selected: #{$NavigateOrSearchOrBuildAndSelectXSingleton}"
            puts ""
            options = [
                "select starlight node",
                "select datapoint",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
            if option.nil? then
                selected = $NavigateOrSearchOrBuildAndSelectXSingleton
                $NavigateOrSearchOrBuildAndSelectXSingleton = nil
                return selected
            end
            if option == "select starlight node" then
                node = StarlightNodeNavigateOrSearchOrBuildAndSelect::selectNodePossiblyMakeANewOneOrNull(true)
                if node then
                    if LucilleCore::askQuestionAnswerAsBoolean("select '#{StartlightNodes::nodeToString(node)}' for return ? ") then
                        $NavigateOrSearchOrBuildAndSelectXSingleton = node
                    end
                end
            end

            if option == "select datapoint" then
                datapoint = DataPointsNavigateOrSearchOrBuildAndSelect::searchAndSelectOrNull()
                if datapoint then
                    if LucilleCore::askQuestionAnswerAsBoolean("select '#{DataPoints::datapointToString(datapoint)}' for return ? ") then
                        $NavigateOrSearchOrBuildAndSelectXSingleton = datapoint
                    end
                end
            end
        }
    end
end
