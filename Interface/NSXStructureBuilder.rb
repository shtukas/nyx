# encoding: UTF-8

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/Core/Items.rb"

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
                datapoint = DataPoints::issueDataPointInteractivelyWithStarlightNodeInviteOrNull()
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

    # NSXStructureBuilder::startLightNodeExistingOrNewThenBuildAroundThenReturnNode()
    def self.startLightNodeExistingOrNewThenBuildAroundThenReturnNode()
        node = StartlightNodes::selectNodePossiblyMakeANewOneOrNull()
        if node.nil? then
            puts "Could not determine a Startlight node. Aborting build sequence."
            return
        end
        node = NSXStructureBuilder::startlightNodeBuildAround(node)
        node
    end

    # NSXStructureBuilder::attachTargetToStarlightNodeExistingOrNew(target)
    def self.attachTargetToStarlightNodeExistingOrNew(target)
        return if target.nil?
        node = StartlightNodes::selectNodePossiblyMakeANewOneOrNull()
        return if node.nil?
        claim = StarlightOwnershipClaims::issueClaimGivenNodeAndCatalystStandardTarget(node, target)
        puts JSON.pretty_generate(claim)
    end

    # NSXStructureBuilder::structure()
    def self.structure()
        [
            {
                "text"   => "standard target (new) -> { Todo, OpenCycle, Starlight Node (existing or new) }",
                "lambda" => lambda {
                    target = CatalystStandardTargets::issueNewTargetInteractivelyOrNull()
                    return if target.nil?
                    whereTo = LucilleCore::selectEntityFromListOfEntitiesOrNull("whereTo?", ["Todo", "OpenCycle", "Starlight Node"])
                    return if whereTo.nil?
                    if whereTo == "Todo" then
                        projectname = Items::selectProjectNameInteractivelyOrNull()
                        projectuuid = nil
                        if projectname.nil? then
                            projectname = LucilleCore::askQuestionAnswerAsString("project name: ")
                            projectuuid = SecureRandom.uuid
                        else
                            projectuuid = Items::projectname2projectuuidOrNUll(projectname)
                            return if projectuuid.nil?
                        end
                        description = LucilleCore::askQuestionAnswerAsString("todo item description: ")
                        Items::issueNewItem(projectname, projectuuid, description, target)
                    end
                    if whereTo == "OpenCycle" then
                        claim = {
                            "uuid"              => SecureRandom.uuid,
                            "creationTimestamp" => Time.new.to_f,
                            "entityuuid"        => target["uuid"]
                        }
                        OpenCycles::saveClaim(claim)
                    end
                    if whereTo == "Starlight Node" then
                        NSXStructureBuilder::attachTargetToStarlightNodeExistingOrNew(target)
                    end
                }
            },
            {
                "text"   => "datapoint (new) -> { OpenCycle, Starlight Node (existing or new) }",
                "lambda" => lambda { 
                    datapoint = DataPoints::issueDataPointInteractivelyWithStarlightNodeInviteOrNull()
                    return if datapoint.nil?

                    whereTo = LucilleCore::selectEntityFromListOfEntitiesOrNull("whereTo?", ["OpenCycle", "Starlight Node"])
                    return if whereTo.nil?
                    if whereTo == "OpenCycle" then
                        claim = {
                            "uuid"              => SecureRandom.uuid,
                            "creationTimestamp" => Time.new.to_f,
                            "entityuuid"        => datapoint["uuid"]
                        }
                        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles/#{claim["uuid"]}.json", "w"){|f| f.puts(JSON.pretty_generate(claim)) }
                    end
                    if whereTo == "Starlight Node" then
                        node = StartlightNodes::selectNodePossiblyMakeANewOneOrNull()
                        return if node.nil?
                        StarlightOwnershipClaims::issueClaimGivenNodeAndDataPoint(node, datapoint)
                    end
                }
            },
            {
                "text"   => "starlight node (existing or new) + build around",
                "lambda" => lambda { NSXStructureBuilder::startLightNodeExistingOrNewThenBuildAroundThenReturnNode() }
            }
        ]
    end
end


