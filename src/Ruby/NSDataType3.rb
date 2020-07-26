
# encoding: UTF-8

class NSDataType3

    # NSDataType3::issueNewStoryWithDescription(description)
    def self.issueNewStoryWithDescription(description)
        story = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "5f98770b-ee31-4c67-9d7c-509c89618ea6",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(story)
        NyxObjects::put(story)
        NSDataTypeXExtended::issueDescriptionForTarget(story, description)
        story
    end

    # NSDataType3::issueNewStoryInteractivelyOrNull()
    def self.issueNewStoryInteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("story description: ")
        return nil if description.size == 0

        story = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "5f98770b-ee31-4c67-9d7c-509c89618ea6",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(story)
        NyxObjects::put(story)

        NSDataTypeXExtended::issueDescriptionForTarget(story, description)

        story
    end

    # NSDataType3::stories()
    def self.stories()
        NyxObjects::getSet("5f98770b-ee31-4c67-9d7c-509c89618ea6")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # NSDataType3::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataType3::getStoryDescriptionOrNull(story)
    def self.getStoryDescriptionOrNull(story)
        NSDataTypeXExtended::getLastDescriptionForTargetOrNull(story)
    end

    # NSDataType3::storyToString(story)
    def self.storyToString(story)
        cacheKey = "6517beea-cf36-4d71-ad7a-917ee97522ea:#{Miscellaneous::today()}:#{story["uuid"]}"
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return str if str

        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(story)
        if description then
            str = "[story] [#{story["uuid"][0, 4]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end

        str = "[story] [#{story["uuid"][0, 4]}] [no description]"
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
        str
    end

    # NSDataType3::storyMatchesPattern(story, pattern)
    def self.storyMatchesPattern(story, pattern)
        return true if story["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType3::storyToString(story).downcase.include?(pattern.downcase)
        false
    end

    # NSDataType3::selectStorysUsingPattern(pattern)
    def self.selectStorysUsingPattern(pattern)
        NSDataType3::stories()
            .select{|story| NSDataType3::storyMatchesPattern(story, pattern) }
    end

    # NSDataType3::landing(story)
    def self.landing(story)
        loop {

            system("clear")

            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete("6517beea-cf36-4d71-ad7a-917ee97522ea:#{Miscellaneous::today()}:#{story["uuid"]}") # decaching the toString

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule()

            puts "[story]"

            puts "    uuid: #{story["uuid"]}"
            description = NSDataType3::getStoryDescriptionOrNull(story)
            if description then
                puts "    description: #{description}"
            end

            puts ""
            puts "Parents:"

            GraphTypes::getUpstreamGraphTypes(story).each{|ns|
                print "    "
                menuitems.raw(
                    GraphTypes::toString(ns),
                    GraphTypes::landingLambda(ns)
                )
                puts ""
            }

            puts ""
            puts "Children:"

            GraphTypes::getDownstreamGraphTypes(story).each{|ns|
                print "    "
                menuitems.raw(
                    GraphTypes::toString(ns),
                    GraphTypes::landingLambda(ns)
                )
                puts ""
            }

            Miscellaneous::horizontalRule()

            description = NSDataType3::getStoryDescriptionOrNull(story)
            if description then
                menuitems.item(
                    "[this] description update",
                    lambda{
                        description = Miscellaneous::editTextSynchronously(description).strip
                        return if description == ""
                        NSDataTypeXExtended::issueDescriptionForTarget(story, description)
                    }
                )
            else
                menuitems.item(
                    "[this] description set",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        NSDataTypeXExtended::issueDescriptionForTarget(story, description)
                    }
                )
            end

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "[this] destroy", 
                    lambda { 
                        if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this story ? ") then
                            NyxObjects::destroy(story)
                        end
                    }
                )
            end

            menuitems.item(
                "[upstream] add concept",
                lambda {
                    concept = NSDataType2::selectExistingConceptOrMakeNewConceptInteractivelyOrNull()
                    return if concept.nil?
                    Arrows::issueOrException(concept, story)
                }
            )

            if Miscellaneous::isAlexandra() then
                menuitems.item(
                    "[upstream] remove concept",
                    lambda {
                        concept = LucilleCore::selectEntityFromListOfEntitiesOrNull("concept", GraphTypes::getUpstreamGraphTypes(story), lambda{|concept| NSDataType3::storyToString(concept) })
                        return if concept.nil?
                        Arrows::remove(concept, story)
                    }
                )
            end

            menuitems.item(
                "[downstream] add point (chosen from existing points)",
                lambda {
                    point = NSDataType1::selectExistingPointInteractivelyOrNull()
                    return if point.nil?
                    Arrows::issueOrException(story, point)
                }
            )
            menuitems.item(
                "[downstream] add new point",
                lambda {
                    point = NSDataType1::issueNewPointAndItsFirstFrameInteractivelyOrNull()
                    return if point.nil?
                    Arrows::issueOrException(story, point)
                }
            )

            Miscellaneous::horizontalRule()

            status = menuitems.prompt()
            break if !status
        }
    end

    # ---------------------------------------------

    # NSDataType3::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataType3::selectStorysUsingPattern(pattern)
            .map{|story|
                {
                    "description"   => NSDataType3::storyToString(story),
                    "referencetime" => story["unixtime"],
                    "dive"          => lambda{ NSDataType3::landing(story) }
                }
            }
    end
end
