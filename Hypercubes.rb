
# encoding: UTF-8

class HypercubeCached
    # HypercubeCached::forget(hypercube)
    def self.forget(hypercube)
        InMemoryWithOnDiskPersistenceValueCache::delete("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{hypercube["uuid"]}") # toString
    end
end

class Hypercubes

    # Hypercubes::commitHypercubeToDisk(hypercube)
    def self.commitHypercubeToDisk(hypercube)
        NyxObjects::put(hypercube)
    end

    # Hypercubes::issueNewHypercubeInteractively()
    def self.issueNewHypercubeInteractively()
        puts "Issuing a new Hypercube..."

        hypercube = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(hypercube)
        Hypercubes::commitHypercubeToDisk(hypercube)

        flock = Flocks::issueNewFlockAndItsFirstFrameInteractivelyOrNull()
        if flock then
            puts JSON.pretty_generate(flock)
            Arrows::issue(hypercube, flock)
        end

        description = LucilleCore::askQuestionAnswerAsString("hypercube description: ")
        if description.size > 0 then
            descriptionz = DescriptionZ::issue(hypercube["uuid"], description)
            puts JSON.pretty_generate(descriptionz)
        end

        Hypercubes::issueZeroOrMoreHypercubeTagsForHypercubeInteractively(hypercube)

        hypercube
    end

    # Hypercubes::hypercubes()
    def self.hypercubes()
        NyxObjects::getSet("6b240037-8f5f-4f52-841d-12106658171f")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Hypercubes::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # Hypercubes::destroyHypercubeByUUID(uuid)
    def self.destroyHypercubeByUUID(uuid)
        NyxObjects::destroy(uuid)
    end

    # Hypercubes::hypercubeToString(hypercube)
    def self.hypercubeToString(hypercube)
        str = InMemoryWithOnDiskPersistenceValueCache::getOrNull("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{hypercube["uuid"]}")
        return str if str

        description = Hypercubes::getHypercubeDescriptionZDescriptionOrNull(hypercube)
        if description then
            str = "[hypercube] [#{hypercube["uuid"][0, 4]}] #{description}"
            InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{hypercube["uuid"]}", str)
            return str
        end

        flocks = Flocks::getFlocksForSource(hypercube)
        if flocks.size > 0 then
            str = "[hypercube] #{Flocks::flockToString(flocks[0])}"
            InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{hypercube["uuid"]}", str)
            return str
        end

        str = "[hypercube] [#{hypercube["uuid"][0, 4]}] [no description]"
        InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{hypercube["uuid"]}", str)
        str
    end

    # Hypercubes::landing(hypercube)
    def self.landing(hypercube)
        loop {

            hypercube = Hypercubes::getOrNull(hypercube["uuid"])

            return if hypercube.nil? # Could have been destroyed in the previous loop

            system("clear")

            HypercubeCached::forget(hypercube)

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule(false)

            # -------------------------------------------
            # Hypercube metadata
            puts Hypercubes::hypercubeToString(hypercube)

            description = DescriptionZ::getLastDescriptionForTargetOrNull(hypercube["uuid"])
            if description then
                puts "description: #{description}"
            end

            puts "uuid: #{hypercube["uuid"]}"
            puts "date: #{Hypercubes::getHypercubeReferenceDateTime(hypercube)}"

            notetext = Notes::getMostRecentTextForTargetOrNull(hypercube["uuid"])
            if notetext then
                puts ""
                puts "Note:"
                puts notetext.lines.map{|line| "    #{line}" }.join()
            end

            Comments::getCommentsForTargetInTimeOrder(hypercube["uuid"]).each{|comment|
                puts ""
                puts "Comment:"
                puts NyxBlobs::getBlobOrNull(comment["namedhash"]).lines.map{|line| "    #{line}" }.join()
            }

            Hypercubes::getHypercubeTags(hypercube)
                .each{|tag|
                    puts "tag: #{tag["payload"]}"
                }

            puts ""

            if DescriptionZ::getDescriptionZsForTargetInTimeOrder(hypercube["uuid"]).last then
                menuitems.item(
                    "description (update)",
                    lambda{
                        description = Hypercubes::getHypercubeDescriptionZDescriptionOrNull(hypercube)
                        if description.nil? then
                            description = LucilleCore::askQuestionAnswerAsString("description: ")
                        else
                            description = Miscellaneous::editTextUsingTextmate(description).strip
                        end
                        return if description == ""
                        DescriptionZ::issue(hypercube["uuid"], description)
                    }
                )
            else
                menuitems.item(
                    "description (set)",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        DescriptionZ::issue(hypercube["uuid"], description)
                    }
                )
            end

            menuitems.item(
                "datetime (update)",
                lambda{
                    datetime = Miscellaneous::editTextUsingTextmate(Hypercubes::getHypercubeReferenceDateTime(hypercube)).strip
                    return if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
                    DateTimeZ::issue(hypercube["uuid"], datetime)
                }
            )

            menuitems.item(
                "top note (edit)", 
                lambda{ 
                    text = Notes::getMostRecentTextForTargetOrNull(hypercube["uuid"]) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    Notes::issue(hypercube["uuid"], text)
                }
            )

            menuitems.item(
                "comment (new)", 
                lambda{ 
                    text = Miscellaneous::editTextUsingTextmate("").strip
                    Comments::issue(hypercube["uuid"], nil, text)
                }
            )

            menuitems.item(
                "tag (add)",
                lambda {
                    payload = LucilleCore::askQuestionAnswerAsString("tag: ")
                    return if payload.size == 0
                    Tags::issueTag(hypercube["uuid"], payload)
                }
            )

            menuitems.item(
                "tag (select and remove)",
                lambda {
                    tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", Hypercubes::getHypercubeTags(hypercube), lambda{|tag| tag["payload"] })
                    return if tag.nil?
                    Tags::destroyTag(tag)
                }
            )

            menuitems.item(
                "hypercube (destroy)", 
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this hypercube ? ") then
                        NyxObjects::destroy(hypercube["uuid"])
                    end
                }
            )

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Latest Hypercube

            frame = Hypercubes::getLastHypercubeFrameOrNull(hypercube)
            if frame then
                menuitems.item(
                    "view data",
                    lambda { Frames::openFrame(hypercube, frame) }
                )
            else
                puts "No frame found for this hypercube"
            end

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Related

            puts "Cliques:"

            Arrows::getSourceOfGivenSetsForTarget(hypercube, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
                .sort{|o1, o2| Cliques::getLastActivityUnixtime(o1) <=> Cliques::getLastActivityUnixtime(o2) }
                .each{|clique|
                    menuitems.item(
                        Cliques::cliqueToString(clique), 
                        lambda { Cliques::landing(clique) }
                    )
                }

            puts ""

            menuitems.item(
                "clique (link to)",
                lambda {
                    clique = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
                    return if clique.nil?
                    Arrows::issue(clique, hypercube)
                }
            )

            menuitems.item(
                "clique (select and unlink)",
                lambda {
                    clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", Hypercubes::getHypercubeCliques(hypercube), lambda{|clique| Cliques::cliqueToString(clique) })
                    return if clique.nil?
                    Arrows::issue(clique, hypercube)
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

    # Hypercubes::getHypercubeCliques(hypercube)
    def self.getHypercubeCliques(hypercube)
        Arrows::getSourceOfGivenSetsForTarget(hypercube, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
    end

    # Hypercubes::getHypercubeFramesInTimeOrder(hypercube)
    def self.getHypercubeFramesInTimeOrder(hypercube)
        Arrows::getTargetOfGivenSetsForSource(hypercube, ["0f555c97-3843-4dfe-80c8-714d837eba69"])
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # Hypercubes::getLastHypercubeFrameOrNull(hypercube)
    def self.getLastHypercubeFrameOrNull(hypercube)
        Hypercubes::getHypercubeFramesInTimeOrder(hypercube).last
    end

    # Hypercubes::getHypercubeReferenceDateTime(hypercube)
    def self.getHypercubeReferenceDateTime(hypercube)
        datetimezs = DateTimeZ::getDateTimeZsForTargetInTimeOrder(hypercube["uuid"])
        return Time.at(hypercube["unixtime"]).utc.iso8601 if datetimezs.empty?
        datetimezs.last["datetimeISO8601"]
    end

    # Hypercubes::getHypercubeReferenceUnixtime(hypercube)
    def self.getHypercubeReferenceUnixtime(hypercube)
        DateTime.parse(Hypercubes::getHypercubeReferenceDateTime(hypercube)).to_time.to_f
    end

    # Hypercubes::getHypercubeDescriptionZDescriptionOrNull(hypercube)
    def self.getHypercubeDescriptionZDescriptionOrNull(hypercube)
        descriptionzs = DescriptionZ::getDescriptionZsForTargetInTimeOrder(hypercube["uuid"])
        return nil if descriptionzs.empty?
        descriptionzs.last["description"]
    end

    # Hypercubes::hypercubeuuidToString(hypercubeuuid)
    def self.hypercubeuuidToString(hypercubeuuid)
        hypercube = Hypercubes::getOrNull(hypercubeuuid)
        return "[hypercube not found]" if hypercube.nil?
        Hypercubes::hypercubeToString(hypercube)
    end

    # Hypercubes::selectHypercubeFromHypercubeuuidsOrNull(hypercubeuuids)
    def self.selectHypercubeFromHypercubeuuidsOrNull(hypercubeuuids)
        if hypercubeuuids.size == 0 then
            return nil
        end
        if hypercubeuuids.size == 1 then
            hypercubeuuid = hypercubeuuids[0]
            return Hypercubes::getOrNull(hypercubeuuid)
        end

        hypercubeuuid = LucilleCore::selectEntityFromListOfEntitiesOrNull("hypercube: ", hypercubeuuids, lambda{|uuid| Hypercubes::hypercubeuuidToString(uuid) })
        return nil if hypercubeuuid.nil?
        Hypercubes::getOrNull(hypercubeuuid)
    end

    # Hypercubes::hypercubesListingAndLanding()
    def self.hypercubesListingAndLanding()
        loop {
            ms = LCoreMenuItemsNX1.new()
            Hypercubes::hypercubes()
                .sort{|q1, q2| q1["unixtime"]<=>q2["unixtime"] }
                .each{|hypercube|
                    ms.item(
                        Hypercubes::hypercubeToString(hypercube), 
                        lambda{ Hypercubes::landing(hypercube) }
                    )
                }
            status = ms.prompt()
            break if !status
        }
    end

    # Hypercubes::selectHypercubeFromExistingHypercubesOrNull()
    def self.selectHypercubeFromExistingHypercubesOrNull()
        hypercubestrings = Hypercubes::hypercubes().map{|hypercube| Hypercubes::hypercubeToString(hypercube) }
        hypercubestring = Miscellaneous::chooseALinePecoStyle("hypercube:", [""]+hypercubestrings)
        return nil if hypercubestring == ""
        Hypercubes::hypercubes()
            .select{|hypercube| Hypercubes::hypercubeToString(hypercube) == hypercubestring }
            .first
    end

    # Hypercubes::hypercubeMatchesPattern(hypercube, pattern)
    def self.hypercubeMatchesPattern(hypercube, pattern)
        return true if hypercube["uuid"].downcase.include?(pattern.downcase)
        return true if Hypercubes::hypercubeToString(hypercube).downcase.include?(pattern.downcase)
        if hypercube["type"] == "unique-name" then
            return true if hypercube["name"].downcase.include?(pattern.downcase)
        end
        false
    end

    # Hypercubes::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        Hypercubes::hypercubes()
            .select{|hypercube| Hypercubes::hypercubeMatchesPattern(hypercube, pattern) }
            .map{|hypercube|
                {
                    "description"   => Hypercubes::hypercubeToString(hypercube),
                    "referencetime" => Hypercubes::getHypercubeReferenceUnixtime(hypercube),
                    "dive"          => lambda{ Hypercubes::landing(hypercube) }
                }
            }
    end

    # Hypercubes::issueZeroOrMoreHypercubeTagsForHypercubeInteractively(hypercube)
    def self.issueZeroOrMoreHypercubeTagsForHypercubeInteractively(hypercube)
        loop {
            payload = LucilleCore::askQuestionAnswerAsString("tag (empty to exit) : ")
            break if payload.size == 0
            Tags::issueTag(hypercube["uuid"], payload)
        }
    end

    # Hypercubes::attachHypercubeToZeroOrMoreCliquesInteractively(hypercube)
    def self.attachHypercubeToZeroOrMoreCliquesInteractively(hypercube)
        Cliques::selectZeroOrMoreCliquesExistingOrCreated()
            .each{|clique| Arrows::issue(clique, hypercube) }
    end

    # Hypercubes::ensureHypercubeDescription(hypercube)
    def self.ensureHypercubeDescription(hypercube)
        return if Hypercubes::getHypercubeDescriptionZDescriptionOrNull(hypercube)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description.size == 0
        DescriptionZ::issue(hypercube["uuid"], description)
    end

    # Hypercubes::ensureAtLeastOneHypercubeCliques(hypercube)
    def self.ensureAtLeastOneHypercubeCliques(hypercube)
        if Hypercubes::getHypercubeCliques(hypercube).empty? then
            Hypercubes::attachHypercubeToZeroOrMoreCliquesInteractively(hypercube)
        end
    end

    # Hypercubes::getHypercubeTags(hypercube)
    def self.getHypercubeTags(hypercube)
        Tags::getTagsForTargetUUID(hypercube["uuid"])
    end
end
