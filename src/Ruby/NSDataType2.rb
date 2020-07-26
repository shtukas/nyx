
# encoding: UTF-8

class NSDataType2

    # NSDataType2::issueNewConceptWithDescription(description)
    def self.issueNewConceptWithDescription(description)
        concept = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(concept)
        NyxObjects::put(concept)
        NSDataTypeXExtended::issueDescriptionForTarget(concept, description)
        concept
    end

    # NSDataType2::issueNewConceptInteractivelyOrNull()
    def self.issueNewConceptInteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("concept description: ")
        return nil if description.size == 0

        concept = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(concept)
        NyxObjects::put(concept)

        NSDataTypeXExtended::issueDescriptionForTarget(concept, description)

        concept
    end

    # NSDataType2::concepts()
    def self.concepts()
        NyxObjects::getSet("6b240037-8f5f-4f52-841d-12106658171f")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # NSDataType2::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataType2::conceptToString(concept)
    def self.conceptToString(concept)
        cacheKey = "9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{Miscellaneous::today()}:#{concept["uuid"]}"
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return str if str

        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(concept)
        if description then
            str = "[concept] [#{concept["uuid"][0, 4]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end

        GraphTypes::getDownstreamGraphTypes(concept).each{|ns1|
            str = "[concept] [#{concept["uuid"][0, 4]}] #{NSDataType1::pointToString(ns1)}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        }

        str = "[concept] [#{concept["uuid"][0, 4]}] [no description]"
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
        str
    end

    # NSDataType2::conceptMatchesPattern(concept, pattern)
    def self.conceptMatchesPattern(concept, pattern)
        return true if concept["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType2::conceptToString(concept).downcase.include?(pattern.downcase)
        false
    end

    # NSDataType2::selectConceptsUsingPattern(pattern)
    def self.selectConceptsUsingPattern(pattern)
        NSDataType2::concepts()
            .select{|concept| NSDataType2::conceptMatchesPattern(concept, pattern) }
    end

    # ---------------------------------------------

    # NSDataType2::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataType2::selectConceptsUsingPattern(pattern)
            .map{|concept|
                {
                    "description"   => NSDataType2::conceptToString(concept),
                    "referencetime" => concept["unixtime"],
                    "dive"          => lambda{ GraphTypes::landing(concept) }
                }
            }
    end
end
