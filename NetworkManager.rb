
# encoding: UTF-8

class NetworkManager

    # NetworkManager::ensureReadiness()
    def self.ensureReadiness()

        # --------------------------------------------------------
        # We ensure that the "[root]" ns3 exists

        if NSDataType3::ns3s().none?{|ns3| NSDataType3::isRoot?(ns3) } then
            # We do not have a [root] ns3, going to create one
            puts "We do not have a [root] ns3, going to create one"
            LucilleCore::pressEnterToContinue()
            NSDataType3::issueNSDataType3("[root]")
        end

        # --------------------------------------------------------
        # Make any ns3 that is not a target a target of root

        root = NSDataType3::getRootNSDataType3()
        if root.nil? then
            puts "[error: 8891f3b1] That's strange, I could not find the root ns3 🤔"
            exit
        end
    end

    # NetworkManager::performSecondaryNetworkMaintenance()
    def self.performSecondaryNetworkMaintenance()

        # --------------------------------------------------------
        # Make any ns3 that is not a target a target of root

        root = NSDataType3::getRootNSDataType3()
        if root.nil? then
            puts "[error: bb9833e3] That's strange, I could not find the root ns3 🤔"
            exit
        end

        NSDataType3::ns3s().each{|ns3|
            next if NSDataType3::isRoot?(ns3) # we do not target the [root]
            next if NSDataType3::getNSDataType3NavigationSources(ns3).size > 0
            # At this ns2 we have a ns3 which doesn't have any sources
            Arrows::issue(root, ns3)
        }

        # --------------------------------------------------------
        # Make any ns3 that is a target of root and something else 
        # (meaning has more than one source)
        # is untargetted from [root]

        NSDataType3::getNSDataType3NavigationTargets(root).each{|ns3|
            next if NSDataType3::isRoot?(ns3) # we do not target the [root]
            next if Arrows::getSourcesOfGivenSetsForTarget(ns3, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"]).size <= 1 # It would be pathologique if it was zero, because by this ns2 they should all have at least one source 
            Arrows::remove(root, ns3)
        }
    end
end
