
# encoding: UTF-8

class NSDataType2Cached
    # NSDataType2Cached::forget(ns2)
    def self.forget(ns2)
        InMemoryWithOnDiskPersistenceValueCache::delete("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{ns2["uuid"]}") # toString
    end
end

class NSDataType2

    # NSDataType2::commitNSDataType2ToDisk(ns2)
    def self.commitNSDataType2ToDisk(ns2)
        NyxObjects::put(ns2)
    end

    # NSDataType2::issueNewNSDataType2Interactively()
    def self.issueNewNSDataType2Interactively()
        puts "Issuing a new NSDataType2..."

        ns2 = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(ns2)
        NSDataType2::commitNSDataType2ToDisk(ns2)

        ns0 = NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
        if ns0 then
            puts JSON.pretty_generate(ns0)
            Arrows::issue(ns2, ns0)
        end

        description = LucilleCore::askQuestionAnswerAsString("ns2 description: ")
        if description.size > 0 then
            descriptionz = DescriptionZ::issue(description)
            puts JSON.pretty_generate(descriptionz)
            Arrows::issue(ns2, descriptionz)
        end

        NSDataType2::issueZeroOrMoreTagsForNSDataType2Interactively(ns2)

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

    # NSDataType2::destroyNSDataType2ByUUID(uuid)
    def self.destroyNSDataType2ByUUID(uuid)
        NyxObjects::destroy(uuid)
    end

    # NSDataType2::ns2ToString(ns2)
    def self.ns2ToString(ns2)
        str = InMemoryWithOnDiskPersistenceValueCache::getOrNull("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{ns2["uuid"]}")
        return str if str

        description = DescriptionZ::getLastDescriptionForSourceOrNull(ns2)
        if description then
            str = "[ns2] [#{ns2["uuid"][0, 4]}] #{description}"
            InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{ns2["uuid"]}", str)
            return str
        end

        ns1 = NSDataType2::getNSDataType2NSDataType1sInTimeOrder(ns2).last
        if ns1 then
            str = "[ns2] #{NSDataType1::ns1ToString(ns1)}"
            InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{ns2["uuid"]}", str)
            return str
        end

        str = "[ns2] [#{ns2["uuid"][0, 4]}] [no description]"
        InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{ns2["uuid"]}", str)
        str
    end

    # NSDataType2::landing(ns2)
    def self.landing(ns2)
        loop {

            ns2 = NSDataType2::getOrNull(ns2["uuid"])

            return if ns2.nil? # Could have been destroyed in the previous loop

            system("clear")

            NSDataType2Cached::forget(ns2)

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule(false)

            # -------------------------------------------
            # NSDataType2 metadata
            puts NSDataType2::ns2ToString(ns2)
            puts ""

            description = DescriptionZ::getLastDescriptionForSourceOrNull(ns2)
            if description then
                puts "description: #{description}"
            end

            puts "uuid: #{ns2["uuid"]}"
            puts "date: #{NSDataType2::getNSDataType2ReferenceDateTime(ns2)}"

            notetext = Notes::getMostRecentTextForSourceOrNull(ns2)
            if notetext then
                puts ""
                puts "Note:"
                puts notetext.lines.map{|line| "    #{line}" }.join()
            end

            NSDataType2::getNSDataType2Tags(ns2)
                .each{|tag|
                    puts "tag: #{tag["payload"]}"
                }

            puts ""

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
                    datetime = Miscellaneous::editTextUsingTextmate(NSDataType2::getNSDataType2ReferenceDateTime(ns2)).strip
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
                "tag (add)",
                lambda {
                    payload = LucilleCore::askQuestionAnswerAsString("tag: ")
                    return if payload.size == 0
                    tag = Tags::issue(payload)
                    Arrows::issue(ns2, tag)
                }
            )

            menuitems.item(
                "tag (select and remove)",
                lambda {
                    tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", NSDataType2::getNSDataType2Tags(ns2), lambda{|tag| tag["payload"] })
                    return if tag.nil?
                    Tags::destroyTag(tag)
                }
            )

            menuitems.item(
                "ns2 (destroy)", 
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this ns2 ? ") then
                        NyxObjects::destroy(ns2["uuid"])
                    end
                }
            )

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # NSDataType1

            NSDataType2::getNSDataType2NSDataType1sInTimeOrder(ns2).each{|ns1|
                menuitems.item(
                    "access ns1: #{NSDataType1::ns1ToString(ns1)}",
                    lambda { NSDataType1::openLastNSDataType0(ns1) }
                )
            }

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # NSDataType3s

            puts "NSDataType3s:"

            Arrows::getSourcesOfGivenSetsForTarget(ns2, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
                .sort{|o1, o2| NSDataType3::getLastActivityUnixtime(o1) <=> NSDataType3::getLastActivityUnixtime(o2) }
                .each{|ns3|
                    menuitems.item(
                        NSDataType3::ns3ToString(ns3), 
                        lambda { NSDataType3::landing(ns3) }
                    )
                }

            puts ""

            menuitems.item(
                "select ns3 and add to",
                lambda {
                    ns3 = NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull()
                    return if ns3.nil?
                    Arrows::issue(ns3, ns2)
                }
            )

            menuitems.item(
                "select ns3 and remove from",
                lambda {
                    ns3 = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns3", NSDataType2::getNSDataType2NSDataType3s(ns2), lambda{|ns3| NSDataType3::ns3ToString(ns3) })
                    return if ns3.nil?
                    Arrows::remove(ns3, ns2)
                }
            )

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Operations

            menuitems.item(
                "/", 
                lambda { DataPortalUI::dataPortalFront() }
            )

            Miscellaneous::horizontalRule(true)

            status = menuitems.prompt()
            break if !status
        }
    end

    # ---------------------------------------------

    # NSDataType2::getNSDataType2NSDataType3s(ns2)
    def self.getNSDataType2NSDataType3s(ns2)
        Arrows::getSourcesOfGivenSetsForTarget(ns2, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
    end

    # NSDataType2::getNSDataType2NSDataType1sInTimeOrder(ns2)
    def self.getNSDataType2NSDataType1sInTimeOrder(ns2)
        Arrows::getTargetsOfGivenSetsForSource(ns2, ["c18e8093-63d6-4072-8827-14f238975d04"])
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # NSDataType2::getNSDataType2ReferenceDateTime(ns2)
    def self.getNSDataType2ReferenceDateTime(ns2)
        datetime = DateTimeZ::getLastDateTimeISO8601ForSourceOrNull(ns2)
        return datetime if datetime
        Time.at(ns2["unixtime"]).utc.iso8601
    end

    # NSDataType2::getNSDataType2ReferenceUnixtime(ns2)
    def self.getNSDataType2ReferenceUnixtime(ns2)
        DateTime.parse(NSDataType2::getNSDataType2ReferenceDateTime(ns2)).to_time.to_f
    end

    # NSDataType2::ns2uuidToString(ns2uuid)
    def self.ns2uuidToString(ns2uuid)
        ns2 = NSDataType2::getOrNull(ns2uuid)
        return "[ns2 not found]" if ns2.nil?
        NSDataType2::ns2ToString(ns2)
    end

    # NSDataType2::selectNSDataType2FromNSDataType2uuidsOrNull(ns2uuids)
    def self.selectNSDataType2FromNSDataType2uuidsOrNull(ns2uuids)
        if ns2uuids.size == 0 then
            return nil
        end
        if ns2uuids.size == 1 then
            ns2uuid = ns2uuids[0]
            return NSDataType2::getOrNull(ns2uuid)
        end

        ns2uuid = LucilleCore::selectEntityFromListOfEntitiesOrNull("ns2: ", ns2uuids, lambda{|uuid| NSDataType2::ns2uuidToString(uuid) })
        return nil if ns2uuid.nil?
        NSDataType2::getOrNull(ns2uuid)
    end

    # NSDataType2::ns2sListingAndLanding()
    def self.ns2sListingAndLanding()
        loop {
            ms = LCoreMenuItemsNX1.new()
            NSDataType2::ns2s()
                .sort{|q1, q2| q1["unixtime"]<=>q2["unixtime"] }
                .each{|ns2|
                    ms.item(
                        NSDataType2::ns2ToString(ns2), 
                        lambda{ NSDataType2::landing(ns2) }
                    )
                }
            status = ms.prompt()
            break if !status
        }
    end

    # NSDataType2::selectNSDataType2FromExistingNSDataType2OrNull()
    def self.selectNSDataType2FromExistingNSDataType2OrNull()
        ns2strings = NSDataType2::ns2s().map{|ns2| NSDataType2::ns2ToString(ns2) }
        ns2string = Miscellaneous::chooseALinePecoStyle("ns2:", [""]+ns2strings)
        return nil if ns2string == ""
        NSDataType2::ns2s()
            .select{|ns2| NSDataType2::ns2ToString(ns2) == ns2string }
            .first
    end

    # NSDataType2::ns2MatchesPattern(ns2, pattern)
    def self.ns2MatchesPattern(ns2, pattern)
        return true if ns2["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType2::ns2ToString(ns2).downcase.include?(pattern.downcase)
        if ns2["type"] == "unique-name" then
            return true if ns2["name"].downcase.include?(pattern.downcase)
        end
        false
    end

    # NSDataType2::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataType2::ns2s()
            .select{|ns2| NSDataType2::ns2MatchesPattern(ns2, pattern) }
            .map{|ns2|
                {
                    "description"   => NSDataType2::ns2ToString(ns2),
                    "referencetime" => NSDataType2::getNSDataType2ReferenceUnixtime(ns2),
                    "dive"          => lambda{ NSDataType2::landing(ns2) }
                }
            }
    end

    # NSDataType2::issueZeroOrMoreTagsForNSDataType2Interactively(ns2)
    def self.issueZeroOrMoreTagsForNSDataType2Interactively(ns2)
        loop {
            payload = LucilleCore::askQuestionAnswerAsString("tag (empty to exit) : ")
            break if payload.size == 0
            tag = Tags::issue(payload)
            Arrows::issue(ns2, tag)
        }
    end

    # NSDataType2::ensureNSDataType2Description(ns2)
    def self.ensureNSDataType2Description(ns2)
        return if DescriptionZ::getLastDescriptionForSourceOrNull(ns2)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description.size == 0
        descriptionz = DescriptionZ::issue(description)
        Arrows::issue(ns2, descriptionz)
    end

    # NSDataType2::getNSDataType2Tags(ns2)
    def self.getNSDataType2Tags(ns2)
        Tags::getTagsForSource(ns2)
    end
end
