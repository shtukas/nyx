
# encoding: UTF-8

class NSDataType2Cached
    # NSDataType2Cached::forget(hypercube)
    def self.forget(hypercube)
        InMemoryWithOnDiskPersistenceValueCache::delete("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{hypercube["uuid"]}") # toString
    end
end

class NSDataType2s

    # NSDataType2s::commitNSDataType2ToDisk(hypercube)
    def self.commitNSDataType2ToDisk(hypercube)
        NyxObjects::put(hypercube)
    end

    # NSDataType2s::issueNewNSDataType2Interactively()
    def self.issueNewNSDataType2Interactively()
        puts "Issuing a new NSDataType2..."

        hypercube = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(hypercube)
        NSDataType2s::commitNSDataType2ToDisk(hypercube)

        cube = Cubes::issueNewCubeInteractivelyOrNull()
        if cube then
            puts JSON.pretty_generate(cube)
            Arrows::issue(hypercube, cube)
        end

        description = LucilleCore::askQuestionAnswerAsString("hypercube description: ")
        if description.size > 0 then
            descriptionz = DescriptionZ::issue(description)
            puts JSON.pretty_generate(descriptionz)
            Arrows::issue(hypercube, descriptionz)
        end

        NSDataType2s::issueZeroOrMoreTagsForNSDataType2Interactively(hypercube)

        hypercube
    end

    # NSDataType2s::hypercubes()
    def self.hypercubes()
        NyxObjects::getSet("6b240037-8f5f-4f52-841d-12106658171f")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # NSDataType2s::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataType2s::destroyNSDataType2ByUUID(uuid)
    def self.destroyNSDataType2ByUUID(uuid)
        NyxObjects::destroy(uuid)
    end

    # NSDataType2s::hypercubeToString(hypercube)
    def self.hypercubeToString(hypercube)
        str = InMemoryWithOnDiskPersistenceValueCache::getOrNull("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{hypercube["uuid"]}")
        return str if str

        description = DescriptionZ::getLastDescriptionForSourceOrNull(hypercube)
        if description then
            str = "[hypercube] [#{hypercube["uuid"][0, 4]}] #{description}"
            InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{hypercube["uuid"]}", str)
            return str
        end

        cube = NSDataType2s::getLastNSDataType2CubeOrNull(hypercube)
        if cube then
            str = "[hypercube] #{Cubes::cubeToString(cube)}"
            InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{hypercube["uuid"]}", str)
            return str
        end

        str = "[hypercube] [#{hypercube["uuid"][0, 4]}] [no description]"
        InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{hypercube["uuid"]}", str)
        str
    end

    # NSDataType2s::landing(hypercube)
    def self.landing(hypercube)
        loop {

            hypercube = NSDataType2s::getOrNull(hypercube["uuid"])

            return if hypercube.nil? # Could have been destroyed in the previous loop

            system("clear")

            NSDataType2Cached::forget(hypercube)

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule(false)

            # -------------------------------------------
            # NSDataType2 metadata
            puts NSDataType2s::hypercubeToString(hypercube)
            puts ""

            description = DescriptionZ::getLastDescriptionForSourceOrNull(hypercube)
            if description then
                puts "description: #{description}"
            end

            puts "uuid: #{hypercube["uuid"]}"
            puts "date: #{NSDataType2s::getNSDataType2ReferenceDateTime(hypercube)}"

            notetext = Notes::getMostRecentTextForSourceOrNull(hypercube)
            if notetext then
                puts ""
                puts "Note:"
                puts notetext.lines.map{|line| "    #{line}" }.join()
            end

            NSDataType2s::getNSDataType2Tags(hypercube)
                .each{|tag|
                    puts "tag: #{tag["payload"]}"
                }

            puts ""

            description = DescriptionZ::getLastDescriptionForSourceOrNull(hypercube)
            if description then
                menuitems.item(
                    "description (update)",
                    lambda{
                        description = DescriptionZ::getLastDescriptionForSourceOrNull(hypercube)
                        if description.nil? then
                            description = LucilleCore::askQuestionAnswerAsString("description: ")
                        else
                            description = Miscellaneous::editTextUsingTextmate(description).strip
                        end
                        return if description == ""
                        descriptionz = DescriptionZ::issue(description)
                        Arrows::issue(hypercube, descriptionz)
                    }
                )
            else
                menuitems.item(
                    "description (set)",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        descriptionz = DescriptionZ::issue(description)
                        Arrows::issue(hypercube, descriptionz)
                    }
                )
            end

            menuitems.item(
                "datetime (update)",
                lambda{
                    datetime = Miscellaneous::editTextUsingTextmate(NSDataType2s::getNSDataType2ReferenceDateTime(hypercube)).strip
                    return if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
                    datetimez = DateTimeZ::issue(datetime)
                    Arrows::issue(hypercube, datetimez)
                }
            )

            menuitems.item(
                "top note (edit)", 
                lambda{ 
                    text = Notes::getMostRecentTextForSourceOrNull(hypercube) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    note = Notes::issue(text)
                    Arrows::issue(hypercube, note)
                }
            )

            menuitems.item(
                "tag (add)",
                lambda {
                    payload = LucilleCore::askQuestionAnswerAsString("tag: ")
                    return if payload.size == 0
                    tag = Tags::issue(payload)
                    Arrows::issue(hypercube, tag)
                }
            )

            menuitems.item(
                "tag (select and remove)",
                lambda {
                    tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", NSDataType2s::getNSDataType2Tags(hypercube), lambda{|tag| tag["payload"] })
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
            # Latest NSDataType2

            cube = NSDataType2s::getLastNSDataType2CubeOrNull(hypercube)
            if cube then
                menuitems.item(
                    "access cube (#{cube["type"]})",
                    lambda { Cubes::openCube(hypercube, cube) }
                )
            else
                puts "No cube found for this hypercube"
            end

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Cliques

            puts "Cliques:"

            Arrows::getSourcesOfGivenSetsForTarget(hypercube, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
                .sort{|o1, o2| Cliques::getLastActivityUnixtime(o1) <=> Cliques::getLastActivityUnixtime(o2) }
                .each{|clique|
                    menuitems.item(
                        Cliques::cliqueToString(clique), 
                        lambda { Cliques::landing(clique) }
                    )
                }

            puts ""

            menuitems.item(
                "select clique and add to",
                lambda {
                    clique = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
                    return if clique.nil?
                    Arrows::issue(clique, hypercube)
                }
            )

            menuitems.item(
                "select clique and remove from",
                lambda {
                    clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", NSDataType2s::getNSDataType2Cliques(hypercube), lambda{|clique| Cliques::cliqueToString(clique) })
                    return if clique.nil?
                    Arrows::remove(clique, hypercube)
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

    # NSDataType2s::getNSDataType2Cliques(hypercube)
    def self.getNSDataType2Cliques(hypercube)
        Arrows::getSourcesOfGivenSetsForTarget(hypercube, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
    end

    # NSDataType2s::getNSDataType2CubesInTimeOrder(hypercube)
    def self.getNSDataType2CubesInTimeOrder(hypercube)
        Arrows::getTargetsOfGivenSetsForSource(hypercube, ["0f555c97-3843-4dfe-80c8-714d837eba69"])
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # NSDataType2s::getLastNSDataType2CubeOrNull(hypercube)
    def self.getLastNSDataType2CubeOrNull(hypercube)
        NSDataType2s::getNSDataType2CubesInTimeOrder(hypercube).last
    end

    # NSDataType2s::getNSDataType2ReferenceDateTime(hypercube)
    def self.getNSDataType2ReferenceDateTime(hypercube)
        datetime = DateTimeZ::getLastDateTimeISO8601ForSourceOrNull(hypercube)
        return datetime if datetime
        Time.at(hypercube["unixtime"]).utc.iso8601
    end

    # NSDataType2s::getNSDataType2ReferenceUnixtime(hypercube)
    def self.getNSDataType2ReferenceUnixtime(hypercube)
        DateTime.parse(NSDataType2s::getNSDataType2ReferenceDateTime(hypercube)).to_time.to_f
    end

    # NSDataType2s::hypercubeuuidToString(hypercubeuuid)
    def self.hypercubeuuidToString(hypercubeuuid)
        hypercube = NSDataType2s::getOrNull(hypercubeuuid)
        return "[hypercube not found]" if hypercube.nil?
        NSDataType2s::hypercubeToString(hypercube)
    end

    # NSDataType2s::selectNSDataType2FromNSDataType2uuidsOrNull(hypercubeuuids)
    def self.selectNSDataType2FromNSDataType2uuidsOrNull(hypercubeuuids)
        if hypercubeuuids.size == 0 then
            return nil
        end
        if hypercubeuuids.size == 1 then
            hypercubeuuid = hypercubeuuids[0]
            return NSDataType2s::getOrNull(hypercubeuuid)
        end

        hypercubeuuid = LucilleCore::selectEntityFromListOfEntitiesOrNull("hypercube: ", hypercubeuuids, lambda{|uuid| NSDataType2s::hypercubeuuidToString(uuid) })
        return nil if hypercubeuuid.nil?
        NSDataType2s::getOrNull(hypercubeuuid)
    end

    # NSDataType2s::hypercubesListingAndLanding()
    def self.hypercubesListingAndLanding()
        loop {
            ms = LCoreMenuItemsNX1.new()
            NSDataType2s::hypercubes()
                .sort{|q1, q2| q1["unixtime"]<=>q2["unixtime"] }
                .each{|hypercube|
                    ms.item(
                        NSDataType2s::hypercubeToString(hypercube), 
                        lambda{ NSDataType2s::landing(hypercube) }
                    )
                }
            status = ms.prompt()
            break if !status
        }
    end

    # NSDataType2s::selectNSDataType2FromExistingNSDataType2sOrNull()
    def self.selectNSDataType2FromExistingNSDataType2sOrNull()
        hypercubestrings = NSDataType2s::hypercubes().map{|hypercube| NSDataType2s::hypercubeToString(hypercube) }
        hypercubestring = Miscellaneous::chooseALinePecoStyle("hypercube:", [""]+hypercubestrings)
        return nil if hypercubestring == ""
        NSDataType2s::hypercubes()
            .select{|hypercube| NSDataType2s::hypercubeToString(hypercube) == hypercubestring }
            .first
    end

    # NSDataType2s::hypercubeMatchesPattern(hypercube, pattern)
    def self.hypercubeMatchesPattern(hypercube, pattern)
        return true if hypercube["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType2s::hypercubeToString(hypercube).downcase.include?(pattern.downcase)
        if hypercube["type"] == "unique-name" then
            return true if hypercube["name"].downcase.include?(pattern.downcase)
        end
        false
    end

    # NSDataType2s::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataType2s::hypercubes()
            .select{|hypercube| NSDataType2s::hypercubeMatchesPattern(hypercube, pattern) }
            .map{|hypercube|
                {
                    "description"   => NSDataType2s::hypercubeToString(hypercube),
                    "referencetime" => NSDataType2s::getNSDataType2ReferenceUnixtime(hypercube),
                    "dive"          => lambda{ NSDataType2s::landing(hypercube) }
                }
            }
    end

    # NSDataType2s::issueZeroOrMoreTagsForNSDataType2Interactively(hypercube)
    def self.issueZeroOrMoreTagsForNSDataType2Interactively(hypercube)
        loop {
            payload = LucilleCore::askQuestionAnswerAsString("tag (empty to exit) : ")
            break if payload.size == 0
            tag = Tags::issue(payload)
            Arrows::issue(hypercube, tag)
        }
    end

    # NSDataType2s::attachNSDataType2ToZeroOrMoreCliquesInteractively(hypercube)
    def self.attachNSDataType2ToZeroOrMoreCliquesInteractively(hypercube)
        Cliques::selectZeroOrMoreCliquesExistingOrCreated()
            .each{|clique| Arrows::issue(clique, hypercube) }
    end

    # NSDataType2s::ensureNSDataType2Description(hypercube)
    def self.ensureNSDataType2Description(hypercube)
        return if DescriptionZ::getLastDescriptionForSourceOrNull(hypercube)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description.size == 0
        descriptionz = DescriptionZ::issue(description)
        Arrows::issue(hypercube, descriptionz)
    end

    # NSDataType2s::ensureAtLeastOneNSDataType2Cliques(hypercube)
    def self.ensureAtLeastOneNSDataType2Cliques(hypercube)
        if NSDataType2s::getNSDataType2Cliques(hypercube).empty? then
            NSDataType2s::attachNSDataType2ToZeroOrMoreCliquesInteractively(hypercube)
        end
    end

    # NSDataType2s::getNSDataType2Tags(hypercube)
    def self.getNSDataType2Tags(hypercube)
        Tags::getTagsForSource(hypercube)
    end
end
