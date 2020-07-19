
# encoding: UTF-8

class NSDataType2

    # NSDataType2::issueNewNSDataType2WithDescription(description)
    def self.issueNewNSDataType2WithDescription(description)
        ns2 = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(ns2)
        NyxObjects::put(ns2)

        descriptionz = DescriptionZ::issue(description)
        puts JSON.pretty_generate(descriptionz)
        Arrows::issue(ns2, descriptionz)
        ns2
    end

    # NSDataType2::issueNewNSDataType2InteractivelyOrNull()
    def self.issueNewNSDataType2InteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("ns2 description: ")
        return nil if description.size == 0

        ns2 = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(ns2)
        NyxObjects::put(ns2)

        descriptionz = DescriptionZ::issue(description)
        puts JSON.pretty_generate(descriptionz)
        Arrows::issue(ns2, descriptionz)

        ns2
    end

    # NSDataType2::ns2s()
    def self.ns2s()
        NyxObjects::getSet("6b240037-8f5f-4f52-841d-12106658171f")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # NSDataType2::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataType2::toStringCacheKey(ns2)
    def self.toStringCacheKey(ns2)
        "9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{Miscellaneous::today()}:#{ns2["uuid"]}"
    end

    # NSDataType2::ns2ToString(ns2)
    def self.ns2ToString(ns2)
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(NSDataType2::toStringCacheKey(ns2))
        return str if str

        description = DescriptionZ::getLastDescriptionForSourceOrNull(ns2)
        if description then
            str = "[#{NavigationPoint::userFriendlyName(ns2)}] [#{ns2["uuid"][0, 4]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(NSDataType2::toStringCacheKey(ns2), str)
            return str
        end

        NavigationPoint::getDownstreamNavigationPointsType1(ns2).each{|ns1|
            str = "[#{NavigationPoint::userFriendlyName(ns2)}] [#{ns2["uuid"][0, 4]}] #{NSDataType1::ns1ToString(ns1)}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(NSDataType2::toStringCacheKey(ns2), str)
            return str
        }

        str = "[#{NavigationPoint::userFriendlyName(ns2)}] [#{ns2["uuid"][0, 4]}] [no description]"
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(NSDataType2::toStringCacheKey(ns2), str)
        str
    end

    # NSDataType2::landing(ns2)
    def self.landing(ns2)
        loop {

            ns2 = NSDataType2::getOrNull(ns2["uuid"])

            return if ns2.nil? # Could have been destroyed in the previous loop

            system("clear")

            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete(NSDataType2::toStringCacheKey(ns2)) # decaching the toString

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule()

            puts NSDataType2::ns2ToString(ns2)

            puts "uuid: #{ns2["uuid"]}"
            description = DescriptionZ::getLastDescriptionForSourceOrNull(ns2)
            if description then
                puts "description: #{description}"
            end
            puts "date: #{NavigationPoint::getReferenceDateTime(ns2)}"
            notetext = Notes::getMostRecentTextForSourceOrNull(ns2)
            if notetext then
                puts ""
                puts "Note:"
                puts notetext.lines.map{|line| "    #{line}" }.join()
            end

            description = DescriptionZ::getLastDescriptionForSourceOrNull(ns2)
            if description then
                menuitems.item(
                    "description (update)",
                    lambda{
                        description = DescriptionZ::getLastDescriptionForSourceOrNull(ns2)
                        if description.nil? then
                            description = LucilleCore::askQuestionAnswerAsString("description: ")
                        else
                            description = Miscellaneous::editTextUsingTextmate(description).strip
                        end
                        return if description == ""
                        descriptionz = DescriptionZ::issue(description)
                        Arrows::issue(ns2, descriptionz)
                    }
                )
            else
                menuitems.item(
                    "description (set)",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        descriptionz = DescriptionZ::issue(description)
                        Arrows::issue(ns2, descriptionz)
                    }
                )
            end

            menuitems.item(
                "datetime (update)",
                lambda{
                    datetime = Miscellaneous::editTextUsingTextmate(NavigationPoint::getReferenceDateTime(ns2)).strip
                    return if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
                    datetimez = DateTimeZ::issue(datetime)
                    Arrows::issue(ns2, datetimez)
                }
            )

            menuitems.item(
                "top note (edit)", 
                lambda{ 
                    text = Notes::getMostRecentTextForSourceOrNull(ns2) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    note = Notes::issue(text)
                    Arrows::issue(ns2, note)
                }
            )

            menuitems.item(
                "remove as intermediary page", 
                lambda { 
                    puts "intermediary node removal simulation"
                    NavigationPoint::getUpstreamNavigationPoints(ns2).each{|upstreampage|
                        puts "upstreampage   : #{NavigationPoint::toString("", upstreampage)}"
                    }
                    NavigationPoint::getDownstreamNavigationPoints(ns2).each{|downstreampoint|
                        puts "downstreampoint: #{NavigationPoint::toString("", downstreampoint)}"
                    }
                    return if !LucilleCore::askQuestionAnswerAsBoolean("confirm removing as intermediary page ? ")
                    NavigationPoint::getUpstreamNavigationPoints(ns2).each{|upstreampage|
                        NavigationPoint::getDownstreamNavigationPoints(ns2).each{|downstreampoint|
                            Arrows::issue(upstreampage, downstreampoint)
                        }
                    }
                    NyxObjects::destroy(ns2)
                }
            )

            menuitems.item(
                "destroy", 
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this ns2 ? ") then
                        NyxObjects::destroy(ns2)
                    end
                }
            )

            Miscellaneous::horizontalRule()

            # We are only expecting Type2 here because Type1 don't link down to Type2
            NavigationPoint::getUpstreamNavigationPoints(ns2).each{|ns|
                menuitems.item(
                    NavigationPoint::toString("upstream: ", ns),
                    NavigationPoint::navigationLambda(ns)
                )
            }
            menuitems.item(
                "add upstream #{NavigationPoint::ufn("Type2")}",
                lambda {
                    x = NavigationPointSelection::selectExistingNavigationPointType2OrMakeNewType2OrNull()
                    return if x.nil?
                    Arrows::issue(x, ns2)
                }
            )
            menuitems.item(
                "remove upstream #{NavigationPoint::ufn("Type2")}",
                lambda {
                    x = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns", NavigationPoint::getUpstreamNavigationPoints(ns2), lambda{|ns| NavigationPoint::toString("", ns) })
                    return if x.nil?
                    Arrows::remove(x, ns2)
                }
            )

            Miscellaneous::horizontalRule()

            # Type2 can down stream to Type2 and Type1, we display them separately

            NavigationPoint::getDownstreamNavigationPointsType2(ns2).each{|ns|
                menuitems.item(
                    NavigationPoint::toString("downstream #{NavigationPoint::ufn("Type2")}: ", ns),
                    NavigationPoint::navigationLambda(ns)
                )
            }

            menuitems.item(
                "add downstream #{NavigationPoint::ufn("Type2")}",
                lambda {
                    x2 = NavigationPointSelection::selectExistingNavigationPointType2OrMakeNewType2OrNull()
                    return if x2.nil?
                    Arrows::issue(ns2, x2)
                }
            )
            menuitems.item(
                "remove downstream #{NavigationPoint::ufn("Type2")}",
                lambda {
                    x2 = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns", NavigationPoint::getDownstreamNavigationPoints(ns2), lambda{|ns| NavigationPoint::toString("", ns) })
                    return if x2.nil?
                    Arrows::remove(ns2, x2)
                }
            )

            Miscellaneous::horizontalRule()

            NavigationPoint::getDownstreamNavigationPointsType1(ns2).each{|ns|
                menuitems.item(
                    NavigationPoint::toString("content: ", ns),
                    NavigationPoint::navigationLambda(ns)
                )
            }
            menuitems.item(
                "add existing #{NavigationPoint::ufn("Type1")}",
                lambda {
                    x1 = NavigationPointSelection::selectExistingNavigationPointType1OrNull()
                    return if x1.nil?
                    Arrows::issue(ns2, x1)
                }
            )
            menuitems.item(
                "add new #{NavigationPoint::ufn("Type1")}",
                lambda {
                    x1 = NSDataType1::issueNewNSDataType1AndItsFirstNSDataType0InteractivelyOrNull()
                    return if x1.nil?
                    Arrows::issue(ns2, x1)
                }
            )

            Miscellaneous::horizontalRule()

            menuitems.item(
                "/", 
                lambda { DataPortalUI::dataPortalFront() }
            )

            puts ""

            status = menuitems.prompt()
            break if !status
        }
    end

    # ---------------------------------------------

    # NSDataType2::ns2MatchesPattern(ns2, pattern)
    def self.ns2MatchesPattern(ns2, pattern)
        return true if ns2["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType2::ns2ToString(ns2).downcase.include?(pattern.downcase)
        false
    end

    # NSDataType2::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataType2::ns2s()
            .select{|ns2| NSDataType2::ns2MatchesPattern(ns2, pattern) }
            .map{|ns2|
                {
                    "description"   => NSDataType2::ns2ToString(ns2),
                    "referencetime" => NavigationPoint::getReferenceUnixtime(ns2),
                    "dive"          => lambda{ NSDataType2::landing(ns2) }
                }
            }
    end
end
