
# encoding: UTF-8

class PointCached
    # PointCached::forget(point)
    def self.forget(point)
        InMemoryWithOnDiskPersistenceValueCache::delete("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{point["uuid"]}") # toString
    end
end

class Points

    # Points::commitPointToDisk(point)
    def self.commitPointToDisk(point)
        NyxObjects::put(point)
    end

    # Points::issueNewPointInteractivelyOrNull()
    def self.issueNewPointInteractivelyOrNull()
        puts "Issuing a new Point..."

        point = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        #puts JSON.pretty_generate(point)
        Points::commitPointToDisk(point)

        frame = Frames::issueNewFrameInteractivelyOrNull()
        return point if frame.nil?
        #puts JSON.pretty_generate(frame)

        flock = Flocks::issue()
        Arrows::issue(flock, frame)
        Arrows::issue(point, flock)

        if ["line", "url", "text"].include?(frame["type"]) then
            return point
        end

        description = LucilleCore::askQuestionAnswerAsString("point description: ")
        if description.size > 0 then
            descriptionz = DescriptionZ::issue(point["uuid"], description)
            puts JSON.pretty_generate(descriptionz)
        end

        point
    end

    # Points::points()
    def self.points()
        NyxObjects::getSet("6b240037-8f5f-4f52-841d-12106658171f")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Points::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # Points::destroyPointByUUID(uuid)
    def self.destroyPointByUUID(uuid)
        NyxObjects::destroy(uuid)
    end

    # Points::pointToString(point)
    def self.pointToString(point)
        str = InMemoryWithOnDiskPersistenceValueCache::getOrNull("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{point["uuid"]}")
        return str if str

        description = Points::getPointDescriptionZDescriptionOrNull(point)
        if description then
            str = "[point] [#{point["uuid"][0, 4]}] #{description}"
            InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{point["uuid"]}", str)
            return str
        end

        flocks = Flocks::getFlocksForSource(asteroid)
        if flocks.size > 0 then
            str = Flocks::flockToString(flocks[0])
            InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{point["uuid"]}", str)
            return str
        end

        str = "[point] [#{point["uuid"][0, 4]}] [no description]"
        InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{point["uuid"]}", str)
        str
    end

    # Points::pointDive(point)
    def self.pointDive(point)
        loop {

            point = Points::getOrNull(point["uuid"])

            return if point.nil? # Could have been destroyed in the previous loop

            system("clear")

            PointCached::forget(point)

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule(false)
            # -------------------------------------------
            # Point metadata

            puts "Point: "
            puts "    #{Points::pointToString(point)}"

            descriptionz = DescriptionZ::getDescriptionZsForTargetInTimeOrder(point["uuid"]).last
            if descriptionz then
                puts "    description: #{descriptionz["description"]}"
            else
                puts "    #{Points::pointToString(point)}"
            end

            puts "    uuid: #{point["uuid"]}"
            puts "    date: #{Points::getPointReferenceDateTime(point)}"

            notetext = Notes::getMostRecentTextForTargetOrNull(point["uuid"])
            if notetext then
                puts ""
                puts "Note:"
                puts notetext.lines.map{|line| "    #{line}" }.join()
            end

            Comments::getCommentsForTargetInTimeOrder(point["uuid"]).each{|comment|
                puts ""
                puts "Comment:"
                puts NyxBlobs::getBlobOrNull(comment["namedhash"]).lines.map{|line| "    #{line}" }.join()
            }

            Points::getPointTags(point)
                .each{|tag|
                    puts "tag: #{tag["payload"]}"
                }

            puts ""

            if DescriptionZ::getDescriptionZsForTargetInTimeOrder(point["uuid"]).last then
                menuitems.item(
                    "description (update)",
                    lambda{
                        description = Points::getPointDescriptionZDescriptionOrNull(point)
                        if description.nil? then
                            description = LucilleCore::askQuestionAnswerAsString("description: ")
                        else
                            description = Miscellaneous::editTextUsingTextmate(description).strip
                        end
                        return if description == ""
                        DescriptionZ::issue(point["uuid"], description)
                    }
                )
            else
                menuitems.item(
                    "description (set)",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        DescriptionZ::issue(point["uuid"], description)
                    }
                )
            end

            menuitems.item(
                "datetime (update)",
                lambda{
                    datetime = Miscellaneous::editTextUsingTextmate(Points::getPointReferenceDateTime(point)).strip
                    return if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
                    DateTimeZ::issue(point["uuid"], datetime)
                }
            )

            menuitems.item(
                "top note (edit)", 
                lambda{ 
                    text = Notes::getMostRecentTextForTargetOrNull(point["uuid"]) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    Notes::issue(point["uuid"], text)
                }
            )

            menuitems.item(
                "comment (new)", 
                lambda{ 
                    text = Miscellaneous::editTextUsingTextmate("").strip
                    Comments::issue(point["uuid"], nil, text)
                }
            )

            menuitems.item(
                "tag (add)",
                lambda {
                    payload = LucilleCore::askQuestionAnswerAsString("tag: ")
                    return if payload.size == 0
                    Tags::issueTag(point["uuid"], payload)
                }
            )

            menuitems.item(
                "tag (select and remove)",
                lambda {
                    tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", Points::getPointTags(point), lambda{|tag| tag["payload"] })
                    return if tag.nil?
                    Tags::destroyTag(tag)
                }
            )

            menuitems.item(
                "point (destroy)", 
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this point ? ") then
                        NyxObjects::destroy(point["uuid"])
                    end
                }
            )

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Operations

            puts "Flocks:"
            puts ""

            Flocks::getFlocksForSource(point).each{|flock|
                frame = Flocks::getLastFlockFrameOrNull(flock)
                next if frame.nil?
                menuitems.item(
                    Frames::frameToString(frame),
                    lambda { Frames::openFrame(flock, frame) }
                )
            }

            puts ""
            menuitems.item(
                "add new frame to point",
                lambda { 
                    frame = Frames::issueNewFrameInteractivelyOrNull()
                    return if frame.nil?
                    flock = Flocks::issue()
                    Arrows::issue(flock, frame)
                    Arrows::issue(point, flock)
                }
            )

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Related

            puts "Cliques:"

            Arrows::getSourceOfGivenSetsForTarget(point, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
                .sort{|o1, o2| Cliques::getLastActivityUnixtime(o1) <=> Cliques::getLastActivityUnixtime(o2) }
                .each{|clique|
                    menuitems.item(
                        Cliques::cliqueToString(clique), 
                        lambda { Cliques::cliqueDive(clique) }
                    )
                }

            puts ""
            puts "Point/Cliques Operations:"

            menuitems.item(
                "clique (link to)",
                lambda {
                    clique = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
                    return if clique.nil?
                    Arrows::issue(clique, point)
                }
            )

            menuitems.item(
                "clique (select and unlink)",
                lambda {
                    clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", Points::getPointCliques(point), lambda{|clique| Cliques::cliqueToString(clique) })
                    return if clique.nil?
                    Arrows::issue(clique, point)
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

    # Points::getPointCliques(point)
    def self.getPointCliques(point)
        Arrows::getSourceOfGivenSetsForTarget(point, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
    end

    # Points::getPointReferenceDateTime(point)
    def self.getPointReferenceDateTime(point)
        datetimezs = DateTimeZ::getDateTimeZsForTargetInTimeOrder(point["uuid"])
        return Time.at(point["unixtime"]).utc.iso8601 if datetimezs.empty?
        datetimezs.last["datetimeISO8601"]
    end

    # Points::getPointReferenceUnixtime(point)
    def self.getPointReferenceUnixtime(point)
        DateTime.parse(Points::getPointReferenceDateTime(point)).to_time.to_f
    end

    # Points::getPointDescriptionZDescriptionOrNull(point)
    def self.getPointDescriptionZDescriptionOrNull(point)
        descriptionzs = DescriptionZ::getDescriptionZsForTargetInTimeOrder(point["uuid"])
        return nil if descriptionzs.empty?
        descriptionzs.last["description"]
    end

    # Points::pointuuidToString(pointuuid)
    def self.pointuuidToString(pointuuid)
        point = Points::getOrNull(pointuuid)
        return "[point not found]" if point.nil?
        Points::pointToString(point)
    end

    # Points::selectPointFromPointuuidsOrNull(pointuuids)
    def self.selectPointFromPointuuidsOrNull(pointuuids)
        if pointuuids.size == 0 then
            return nil
        end
        if pointuuids.size == 1 then
            pointuuid = pointuuids[0]
            return Points::getOrNull(pointuuid)
        end

        pointuuid = LucilleCore::selectEntityFromListOfEntitiesOrNull("point: ", pointuuids, lambda{|uuid| Points::pointuuidToString(uuid) })
        return nil if pointuuid.nil?
        Points::getOrNull(pointuuid)
    end

    # Points::pointsListingAndDive()
    def self.pointsListingAndDive()
        loop {
            ms = LCoreMenuItemsNX1.new()
            Points::points()
                .sort{|q1, q2| q1["unixtime"]<=>q2["unixtime"] }
                .each{|point|
                    ms.item(
                        Points::pointToString(point), 
                        lambda{ Points::pointDive(point) }
                    )
                }
            status = ms.prompt()
            break if !status
        }
    end

    # Points::selectPointFromExistingPointsOrNull()
    def self.selectPointFromExistingPointsOrNull()
        pointstrings = Points::points().map{|point| Points::pointToString(point) }
        pointstring = Miscellaneous::chooseALinePecoStyle("point:", [""]+pointstrings)
        return nil if pointstring == ""
        Points::points()
            .select{|point| Points::pointToString(point) == pointstring }
            .first
    end

    # Points::pointMatchesPattern(point, pattern)
    def self.pointMatchesPattern(point, pattern)
        return true if point["uuid"].downcase.include?(pattern.downcase)
        return true if Points::pointToString(point).downcase.include?(pattern.downcase)
        if point["type"] == "unique-name" then
            return true if point["name"].downcase.include?(pattern.downcase)
        end
        false
    end

    # Points::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        Points::points()
            .select{|point| Points::pointMatchesPattern(point, pattern) }
            .map{|point|
                {
                    "description"   => Points::pointToString(point),
                    "referencetime" => Points::getPointReferenceUnixtime(point),
                    "dive"          => lambda{ Points::pointDive(point) }
                }
            }
    end

    # Points::issueZeroOrMorePointTagsForPointInteractively(point)
    def self.issueZeroOrMorePointTagsForPointInteractively(point)
        loop {
            payload = LucilleCore::askQuestionAnswerAsString("tag (empty to exit) : ")
            break if payload.size == 0
            Tags::issueTag(point["uuid"], payload)
        }
    end

    # Points::attachPointToZeroOrMoreCliquesInteractively(point)
    def self.attachPointToZeroOrMoreCliquesInteractively(point)
        Cliques::selectZeroOrMoreCliquesExistingOrCreated()
            .each{|clique| Arrows::issue(clique, point) }
    end

    # Points::ensurePointDescription(point)
    def self.ensurePointDescription(point)
        return if Points::getPointDescriptionZDescriptionOrNull(point)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description.size == 0
        DescriptionZ::issue(point["uuid"], description)
    end

    # Points::ensureAtLeastOnePointCliques(point)
    def self.ensureAtLeastOnePointCliques(point)
        if Points::getPointCliques(point).empty? then
            Points::attachPointToZeroOrMoreCliquesInteractively(point)
        end
    end

    # Points::getPointTags(point)
    def self.getPointTags(point)
        Tags::getTagsForTargetUUID(point["uuid"])
    end
end
