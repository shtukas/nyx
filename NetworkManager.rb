
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

        root = NSDataType3::getElementByNameOrNull("[root]")
        if root.nil? then
            puts "[error: 8891f3b1] That's strange, I could not find the root ns3 🤔"
            exit
        end
    end

    # NetworkManager::performSecondaryNetworkMaintenance()
    def self.performSecondaryNetworkMaintenance()

        # --------------------------------------------------------
        # Make any ns3 that does not have a source a target of [unconnected]

        unconnected = NSDataType3::getElementByNameOrNull("[unconnected]")
        if unconnected.nil? then
            puts "[error: bb9833e3] That's strange, I could not find the [unconnected] ns3 🤔"
            exit
        end

        NSDataType3::ns3s().each{|ns3|
            next if NSDataType3::isRoot?(ns3) # We do not add the [root] to unconnected
            if NSDataType3::getNSDataType3NavigationSources(ns3).size == 0 then
                # At this ns2 we have a ns3 which doesn't have any sources
                puts "adding to [unconnected]: #{NSDataType3::ns3ToString(ns3)}"
                Arrows::issue(unconnected, ns3)
            end
        }

        # --------------------------------------------------------
        # Make any target of [unconnected] that has more that two sources, not a target of unconnected

        unconnected = NSDataType3::getElementByNameOrNull("[unconnected]")

        if unconnected.nil? then
            puts "[error: 9717c526] That's strange, I could not find the [unconnected] ns3 🤔"
            exit
        end

        NSDataType3::getNSDataType3NavigationTargets(unconnected).each{|ns3|
            if NSDataType3::getNSDataType3NavigationSources(ns3).size > 1 then
                puts "removing from [unconnected]: #{NSDataType3::ns3ToString(ns3)}"
                Arrows::remove(unconnected, ns3)
            end
        }

    end
end
