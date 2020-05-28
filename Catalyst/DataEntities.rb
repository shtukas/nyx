
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
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Multiverse.rb"

# -----------------------------------------------------------------

class DataEntities

    # DataEntities::getDataEntityByUuidOrNull(uuid)
    def self.getDataEntityByUuidOrNull(uuid)
        target = CatalystStandardTargets::getOrNull(uuid)
        return target if target
        clique = Cliques::getOrNull(uuid)
        return clique if clique
        starlightnode = Timelines::getOrNull(uuid)
        retun starlightnode if starlightnode
        nil
    end

    # DataEntities::dataEntityToString(dataentity)
    def self.dataEntityToString(dataentity)
        if dataentity["catalystType"] == "catalyst-type:10014e93" then
            return CatalystStandardTargets::targetToString(dataentity)
        end
        if dataentity["catalystType"] == "catalyst-type:clique"  then
            return Cliques::cliqueToString(dataentity)
        end
        if dataentity["catalystType"] == "catalyst-type:timeline"  then
            return Timelines::timelineToString(dataentity)
        end
        raise "DataEntities::dataEntityToString, Error: abb2f0dd-5772"
    end

    # DataEntities::dataEntityDive(dataentity)
    def self.dataEntityDive(dataentity)
        if dataentity["catalystType"] == "catalyst-type:10014e93" then
            return CatalystStandardTargets::targetDive(dataentity)
        end
        if dataentity["catalystType"] == "catalyst-type:clique"  then
            return CliquesEvolved::navigateClique(dataentity)
        end
        if dataentity["catalystType"] == "catalyst-type:timeline"  then
            return Multiverse::visitTimeline(dataentity)
        end
        raise "DataEntities::dataEntityToString, Error: 2f28f27d"
    end

    # DataEntities::visitDataEntity(dataentity)
    def self.visitDataEntity(dataentity)
        if dataentity["catalystType"] == "catalyst-type:10014e93" then
            target = dataentity
            CatalystStandardTargets::openTarget(target)
            return
        end
        if dataentity["catalystType"] == "catalyst-type:clique"  then
            point = dataentity
            Cliques::openClique(point)
            return
        end
        if dataentity["catalystType"] == "catalyst-type:timeline"  then
           node = dataentity
           Multiverse::visitTimeline(node)
           return
        end
        raise "DataEntities::dataEntityToString, Error: 2f28f27d"
    end

    # DataEntities::navigateDataEntity(dataentity)
    def self.navigateDataEntity(dataentity)
        if dataentity["catalystType"] == "catalyst-type:10014e93" then
            CatalystStandardTargets::targetDive(dataentity)
            return
        end
        if dataentity["catalystType"] == "catalyst-type:clique"  then
            CliquesEvolved::navigateClique(dataentity)
            return
        end
        if dataentity["catalystType"] == "catalyst-type:timeline"  then
            Multiverse::visitTimeline(dataentity)
            return
        end
        raise "DataEntities::navigateDataEntity, Error: 26ba9943"
    end

end
