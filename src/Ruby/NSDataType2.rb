
# encoding: UTF-8

class NSDataType2

    # NSDataType2::issueNewNodeWithDescription(description)
    def self.issueNewNodeWithDescription(description)
        node = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(node)
        NyxObjects::put(node)
        NSDataTypeXExtended::issueDescriptionForTarget(node, description)
        node
    end

    # NSDataType2::issueNewNodeInteractivelyOrNull()
    def self.issueNewNodeInteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("node description: ")
        return nil if description.size == 0

        node = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(node)
        NyxObjects::put(node)

        NSDataTypeXExtended::issueDescriptionForTarget(node, description)

        node
    end

    # NSDataType2::nodes()
    def self.nodes()
        NyxObjects::getSet("6b240037-8f5f-4f52-841d-12106658171f")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # NSDataType2::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataType2::nodeToString(node)
    def self.nodeToString(node)
        cacheKey = "9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{Miscellaneous::today()}:#{node["uuid"]}"
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return str if str

        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(node)
        if description then
            str = "[node] [#{node["uuid"][0, 4]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end

        NavigationTypes::getDownstreamNavigationTypes(node).each{|ns1|
            str = "[node] [#{node["uuid"][0, 4]}] #{NSDataType1::pointToString(ns1)}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        }

        str = "[node] [#{node["uuid"][0, 4]}] [no description]"
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
        str
    end

    # NSDataType2::nodeMatchesPattern(node, pattern)
    def self.nodeMatchesPattern(node, pattern)
        return true if node["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType2::nodeToString(node).downcase.include?(pattern.downcase)
        false
    end

    # NSDataType2::selectNodesUsingPattern(pattern)
    def self.selectNodesUsingPattern(pattern)
        NSDataType2::nodes()
            .select{|node| NSDataType2::nodeMatchesPattern(node, pattern) }
    end

    # ---------------------------------------------

    # NSDataType2::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataType2::selectNodesUsingPattern(pattern)
            .map{|node|
                {
                    "description"   => NSDataType2::nodeToString(node),
                    "referencetime" => node["unixtime"],
                    "dive"          => lambda{ NavigationTypes::landing(node) }
                }
            }
    end
end
