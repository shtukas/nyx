
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/SearchX.rb"

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

class SearchX

    # SearchX is very simple. We want to be able to find things and return them.
    # The search should be clever in the sense that we want to be able to modify and add things while searching before returning
    # We can return any of: CatalystStandardTarget, DataPoint, StarlightNode
    # One can specify which type they limit their search to

    # SearchX::selectOrNull(types)
    # types = Array[DataEntityType]
    # DataEntityType = "catalyst-type:catalyst-standard-target" | "catalyst-type:datapoint" | "catalyst-type:starlight-node"
    def self.selectOrNull(types)
        puts "SearchX::selectOrNull() is not yet implemented"
        LucilleCore::pressEnterToContinue()
        nil
    end
end
