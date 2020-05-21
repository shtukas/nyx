# encoding: UTF-8

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTargets.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoints.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

# ------------------------------------------------------------------------

class NSXStructureBuilder

    # NSXStructureBuilder::makeStandardTarget()
    def self.makeStandardTarget()
        CatalystStandardTargets::issueNewTargetInteractivelyOrNull()
    end

    # NSXStructureBuilder::startlightNodeBuildAround(node)
    def self.startlightNodeBuildAround(node)

        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to determine startlight parents for '#{StartlightNodes::nodeToString(node)}' ? ") then
            loop {
                puts "Selecting new parent..."
                parent = StartlightNodes::selectNodePossiblyMakeANewOneOrNull()
                if parent.nil? then
                    puts "Did not determine a parent for '#{StartlightNodes::nodeToString(node)}'. Aborting parent determination."
                    break
                end
                StartlightPaths::makePathFromFirstNodeToSecondNode(parent, node)
                break if !LucilleCore::askQuestionAnswerAsBoolean("Would you like to determine a new startlight parents for '#{StartlightNodes::nodeToString(node)}' ? ")
            }
            puts "Completed determining parents for '#{StartlightNodes::nodeToString(node)}'"
        end

        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to build starlight children for '#{StartlightNodes::nodeToString(node)}' ? ") then
            loop {
                puts "Making new child..."
                child = StartlightNodes::makeNodeInteractivelyOrNull()
                if child.nil? then
                    puts "Did not make a child for '#{StartlightNodes::nodeToString(node)}'. Aborting child building."
                    break
                end
                StartlightPaths::makePathFromFirstNodeToSecondNode(node, child)
                break if !LucilleCore::askQuestionAnswerAsBoolean("Would you like to build a new startlight child for '#{StartlightNodes::nodeToString(node)}' ? ")
            }
            puts "Completed building children for '#{StartlightNodes::nodeToString(node)}'"
        end

        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to build datapoints for '#{StartlightNodes::nodeToString(node)}' ? ") then
            loop {
                puts "Making new datapoint..."
                datapoint = DataPoints::issueDataPointInteractivelyOrNull()
                if datapoint.nil? then
                    puts "Did not make a datapoint for '#{StartlightNodes::nodeToString(node)}'. Aborting datapoint building."
                    break
                end
                StarlightOwnershipClaims::issueClaimGivenNodeAndDataPoint(node, datapoint)
                break if !LucilleCore::askQuestionAnswerAsBoolean("Would you like to build a new datapoint for '#{StartlightNodes::nodeToString(node)}' ? ")
            }
        end

        node
    end

    # NSXStructureBuilder::newOrExistingStartLightNodeBuildAroundReturnNode()
    def self.newOrExistingStartLightNodeBuildAroundReturnNode()
        node = StartlightNodes::selectNodePossiblyMakeANewOneOrNull()
        if node.nil? then
            puts "Could not determine a Startlight node. Aborting build sequence."
            return
        end
        node = NSXStructureBuilder::startlightNodeBuildAround(node)
        node
    end

    # NSXStructureBuilder::main()
    def self.main()
        options = [
            "standard target (new) -> OpenCycle",
            "standard target (new) -> starlight node",
            nil,
            "datapoint (new)",
            "datapoint (existing) -> OpenCycle",
            "datapoint (new) -> OpenCycle",
            nil,
            "starlight node (new or existing) + build around",
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        return if option.nil?
        if option == "standard target (new) -> OpenCycle" then
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/x-make-new-with-new-standard-target")
        end
        if option == "standard target (new) -> starlight node" then
            target = CatalystStandardTargets::issueNewTargetInteractivelyOrNull()
            return if target.nil?
            node = StartlightNodes::selectNodeOrNull()
            return if node.nil?
            claim = StarlightOwnershipClaims::issueClaimGivenNodeAndCatalystStandardTarget(node, target)
            puts JSON.pretty_generate(claim)
        end
        if option == "datapoint (new)" then
            DataPoints::issueDataPointInteractivelyOrNull()
        end
        if option == "datapoint (existing) -> OpenCycle" then
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/x-make-new-with-existing-datapoint")
        end
        if option == "datapoint (new) -> OpenCycle" then
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/x-make-new-with-new-datapoint")
        end
        if option == "starlight node (new or existing) + build around" then
            NSXStructureBuilder::newOrExistingStartLightNodeBuildAroundReturnNode()
        end
    end
end


