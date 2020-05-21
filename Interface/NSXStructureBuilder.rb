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

    # NSXStructureBuilder::startLightNodeNewOrExistingThenBuildAroundThenReturnNode()
    def self.startLightNodeNewOrExistingThenBuildAroundThenReturnNode()
        node = StartlightNodes::selectNodePossiblyMakeANewOneOrNull()
        if node.nil? then
            puts "Could not determine a Startlight node. Aborting build sequence."
            return
        end
        node = NSXStructureBuilder::startlightNodeBuildAround(node)
        node
    end

    # NSXStructureBuilder::standardTargetNewThenAttachToStarlightNode()
    def self.standardTargetNewThenAttachToStarlightNode()
            target = CatalystStandardTargets::issueNewTargetInteractivelyOrNull()
            return if target.nil?
            node = StartlightNodes::selectNodeOrNull()
            return if node.nil?
            claim = StarlightOwnershipClaims::issueClaimGivenNodeAndCatalystStandardTarget(node, target)
            puts JSON.pretty_generate(claim)
    end

    # NSXStructureBuilder::structure()
    def self.structure()
        [
            {
                "text"   => "standard target (new) -> OpenCycle",
                "lambda" => lambda { system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/x-make-new-with-new-standard-target") }
            },
            {
                "text"   => "standard target (new) -> Starlight Node",
                "lambda" => lambda { NSXStructureBuilder::standardTargetNewThenAttachToStarlightNode() }
            },
            {
                "text"   => "datapoint (new)",
                "lambda" => lambda { DataPoints::issueDataPointInteractivelyOrNull() }
            },
            {
                "text"   => "datapoint (existing) -> OpenCycle",
                "lambda" => lambda {
                    puts "Look search for datapoint and promote to opencycle"
                    LucilleCore::pressEnterToContinue()
                    DataPointsSearch::search()
                }
            },
            {
                "text"   => "datapoint (new) -> OpenCycle",
                "lambda" => lambda { OpenCycles::dataPointNewThenRegisterAsOpenCycle() }
            },
            {
                "text"   => "starlight node (new or existing) + build around",
                "lambda" => lambda { NSXStructureBuilder::startLightNodeNewOrExistingThenBuildAroundThenReturnNode() }
            }
        ]
    end
end


