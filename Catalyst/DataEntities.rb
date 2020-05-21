
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataEntities.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTargets.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoints.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

# -----------------------------------------------------------------

class DataEntities

    # This is a copy of the DataEntities.txt
    
    # A Data Entity is any if the four type of elements
    #     1. CatalystStandardTarget ( "catalyst-type:catalyst-standard-target" )
    #     2. DataPoint ( "catalyst-type:datapoint" )
    #     3. Starlight Node ( "catalyst-type:starlight-node" )

    # DataEntities::getDataEntityByUuidOrNull(uuid)
    def self.getDataEntityByUuidOrNull(uuid)
        target = CatalystStandardTargets::getOrNull(uuid)
        return target if target
        datapoint = DataPoints::getOrNull(uuid)
        return datapoint if datapoint
        starlightnode = StartlightNodes::getOrNull(uuid)
        retun starlightnode if starlightnode
        nil
    end

    # DataEntities::dataEntityToString(dataentity)
    def self.dataEntityToString(dataentity)
        puts JSON.generate([dataentity])
        if dataentity["catalystType"] == "catalyst-type:catalyst-standard-target" then
            return CatalystStandardTargets::targetToString(dataentity)
        end
        if dataentity["catalystType"] == "catalyst-type:datapoint"  then
            return DataPoints::datapointToString(dataentity)
        end
        if dataentity["catalystType"] == "catalyst-type:starlight-node"  then
            return StartlightNodes::nodeToString(dataentity)
        end
        raise "DataEntities::dataEntityToString, Error: abb2f0dd-5772"
    end

    # DataEntities::dataEntityDive(dataentity)
    def self.dataEntityDive(dataentity)
        if dataentity["catalystType"] == "catalyst-type:catalyst-standard-target" then
            return CatalystStandardTargets::targetDive(dataentity)
        end
        if dataentity["catalystType"] == "catalyst-type:datapoint"  then
            return DataPoints::pointDive(dataentity)
        end
        if dataentity["catalystType"] == "catalyst-type:starlight-node"  then
            return StartlightNodes::nodeDive(dataentity)
        end
        raise "DataEntities::dataEntityToString, Error: 2f28f27d"
    end
end
