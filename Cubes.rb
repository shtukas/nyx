
# encoding: UTF-8

class CubeCached
    # CubeCached::forget(cube)
    def self.forget(cube)
        InMemoryWithOnDiskPersistenceValueCache::delete("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{cube["uuid"]}") # toString
    end
end

class Cubes

    # Cubes::commitCubeToDisk(cube)
    def self.commitCubeToDisk(cube)
        NyxObjects::put(cube)
    end

    # Cubes::issueNewCubeInteractively()
    def self.issueNewCubeInteractively()
        puts "Issuing a new Cube..."

        cube = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        puts JSON.pretty_generate(cube)
        Cubes::commitCubeToDisk(cube)

        flock = Flocks::issueNewFlockAndItsFirstFrameInteractivelyOrNull()
        if flock then
            puts JSON.pretty_generate(flock)
            Arrows::issue(cube, flock)
        end

        description = LucilleCore::askQuestionAnswerAsString("cube description: ")
        if description.size > 0 then
            descriptionz = DescriptionZ::issue(cube["uuid"], description)
            puts JSON.pretty_generate(descriptionz)
        end

        Cubes::issueZeroOrMoreCubeTagsForCubeInteractively(cube)

        cube
    end

    # Cubes::cubes()
    def self.cubes()
        NyxObjects::getSet("6b240037-8f5f-4f52-841d-12106658171f")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Cubes::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # Cubes::destroyCubeByUUID(uuid)
    def self.destroyCubeByUUID(uuid)
        NyxObjects::destroy(uuid)
    end

    # Cubes::cubeToString(cube)
    def self.cubeToString(cube)
        str = InMemoryWithOnDiskPersistenceValueCache::getOrNull("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{cube["uuid"]}")
        return str if str

        description = Cubes::getCubeDescriptionZDescriptionOrNull(cube)
        if description then
            str = "[cube] [#{cube["uuid"][0, 4]}] #{description}"
            InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{cube["uuid"]}", str)
            return str
        end

        flocks = Flocks::getFlocksForSource(cube)
        if flocks.size > 0 then
            str = "[cube] #{Flocks::flockToString(flocks[0])}"
            InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{cube["uuid"]}", str)
            return str
        end

        str = "[cube] [#{cube["uuid"][0, 4]}] [no description]"
        InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{cube["uuid"]}", str)
        str
    end

    # Cubes::cubeDive(cube)
    def self.cubeDive(cube)
        loop {

            cube = Cubes::getOrNull(cube["uuid"])

            return if cube.nil? # Could have been destroyed in the previous loop

            system("clear")

            CubeCached::forget(cube)

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule(false)

            # -------------------------------------------
            # Cube metadata
            puts Cubes::cubeToString(cube)

            description = DescriptionZ::getLastDescriptionForTargetOrNull(cube["uuid"])
            if description then
                puts "description: #{description}"
            end

            puts "uuid: #{cube["uuid"]}"
            puts "date: #{Cubes::getCubeReferenceDateTime(cube)}"

            notetext = Notes::getMostRecentTextForTargetOrNull(cube["uuid"])
            if notetext then
                puts ""
                puts "Note:"
                puts notetext.lines.map{|line| "    #{line}" }.join()
            end

            Comments::getCommentsForTargetInTimeOrder(cube["uuid"]).each{|comment|
                puts ""
                puts "Comment:"
                puts NyxBlobs::getBlobOrNull(comment["namedhash"]).lines.map{|line| "    #{line}" }.join()
            }

            Cubes::getCubeTags(cube)
                .each{|tag|
                    puts "tag: #{tag["payload"]}"
                }

            puts ""

            if DescriptionZ::getDescriptionZsForTargetInTimeOrder(cube["uuid"]).last then
                menuitems.item(
                    "description (update)",
                    lambda{
                        description = Cubes::getCubeDescriptionZDescriptionOrNull(cube)
                        if description.nil? then
                            description = LucilleCore::askQuestionAnswerAsString("description: ")
                        else
                            description = Miscellaneous::editTextUsingTextmate(description).strip
                        end
                        return if description == ""
                        DescriptionZ::issue(cube["uuid"], description)
                    }
                )
            else
                menuitems.item(
                    "description (set)",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        DescriptionZ::issue(cube["uuid"], description)
                    }
                )
            end

            menuitems.item(
                "datetime (update)",
                lambda{
                    datetime = Miscellaneous::editTextUsingTextmate(Cubes::getCubeReferenceDateTime(cube)).strip
                    return if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
                    DateTimeZ::issue(cube["uuid"], datetime)
                }
            )

            menuitems.item(
                "top note (edit)", 
                lambda{ 
                    text = Notes::getMostRecentTextForTargetOrNull(cube["uuid"]) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    Notes::issue(cube["uuid"], text)
                }
            )

            menuitems.item(
                "comment (new)", 
                lambda{ 
                    text = Miscellaneous::editTextUsingTextmate("").strip
                    Comments::issue(cube["uuid"], nil, text)
                }
            )

            menuitems.item(
                "tag (add)",
                lambda {
                    payload = LucilleCore::askQuestionAnswerAsString("tag: ")
                    return if payload.size == 0
                    Tags::issueTag(cube["uuid"], payload)
                }
            )

            menuitems.item(
                "tag (select and remove)",
                lambda {
                    tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", Cubes::getCubeTags(cube), lambda{|tag| tag["payload"] })
                    return if tag.nil?
                    Tags::destroyTag(tag)
                }
            )

            menuitems.item(
                "cube (destroy)", 
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this cube ? ") then
                        NyxObjects::destroy(cube["uuid"])
                    end
                }
            )

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Operations

            puts "Flocks:"

            Flocks::getFlocksForSource(cube).each{|flock|
                menuitems.item(
                    Flocks::flockToString(flock),
                    lambda { Flocks::dive(flock) }
                )
            }

            puts ""

            menuitems.item(
                "add new flock",
                lambda { 
                    flock = Flocks::issueNewFlockAndItsFirstFrameInteractivelyOrNull()
                    Arrows::issue(cube, flock)
                }
            )

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Related

            puts "Cliques:"

            Arrows::getSourceOfGivenSetsForTarget(cube, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
                .sort{|o1, o2| Cliques::getLastActivityUnixtime(o1) <=> Cliques::getLastActivityUnixtime(o2) }
                .each{|clique|
                    menuitems.item(
                        Cliques::cliqueToString(clique), 
                        lambda { Cliques::cliqueDive(clique) }
                    )
                }

            puts ""

            menuitems.item(
                "clique (link to)",
                lambda {
                    clique = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
                    return if clique.nil?
                    Arrows::issue(clique, cube)
                }
            )

            menuitems.item(
                "clique (select and unlink)",
                lambda {
                    clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", Cubes::getCubeCliques(cube), lambda{|clique| Cliques::cliqueToString(clique) })
                    return if clique.nil?
                    Arrows::issue(clique, cube)
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

    # Cubes::getCubeCliques(cube)
    def self.getCubeCliques(cube)
        Arrows::getSourceOfGivenSetsForTarget(cube, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
    end

    # Cubes::getCubeReferenceDateTime(cube)
    def self.getCubeReferenceDateTime(cube)
        datetimezs = DateTimeZ::getDateTimeZsForTargetInTimeOrder(cube["uuid"])
        return Time.at(cube["unixtime"]).utc.iso8601 if datetimezs.empty?
        datetimezs.last["datetimeISO8601"]
    end

    # Cubes::getCubeReferenceUnixtime(cube)
    def self.getCubeReferenceUnixtime(cube)
        DateTime.parse(Cubes::getCubeReferenceDateTime(cube)).to_time.to_f
    end

    # Cubes::getCubeDescriptionZDescriptionOrNull(cube)
    def self.getCubeDescriptionZDescriptionOrNull(cube)
        descriptionzs = DescriptionZ::getDescriptionZsForTargetInTimeOrder(cube["uuid"])
        return nil if descriptionzs.empty?
        descriptionzs.last["description"]
    end

    # Cubes::cubeuuidToString(cubeuuid)
    def self.cubeuuidToString(cubeuuid)
        cube = Cubes::getOrNull(cubeuuid)
        return "[cube not found]" if cube.nil?
        Cubes::cubeToString(cube)
    end

    # Cubes::selectCubeFromCubeuuidsOrNull(cubeuuids)
    def self.selectCubeFromCubeuuidsOrNull(cubeuuids)
        if cubeuuids.size == 0 then
            return nil
        end
        if cubeuuids.size == 1 then
            cubeuuid = cubeuuids[0]
            return Cubes::getOrNull(cubeuuid)
        end

        cubeuuid = LucilleCore::selectEntityFromListOfEntitiesOrNull("cube: ", cubeuuids, lambda{|uuid| Cubes::cubeuuidToString(uuid) })
        return nil if cubeuuid.nil?
        Cubes::getOrNull(cubeuuid)
    end

    # Cubes::cubesListingAndDive()
    def self.cubesListingAndDive()
        loop {
            ms = LCoreMenuItemsNX1.new()
            Cubes::cubes()
                .sort{|q1, q2| q1["unixtime"]<=>q2["unixtime"] }
                .each{|cube|
                    ms.item(
                        Cubes::cubeToString(cube), 
                        lambda{ Cubes::cubeDive(cube) }
                    )
                }
            status = ms.prompt()
            break if !status
        }
    end

    # Cubes::selectCubeFromExistingCubesOrNull()
    def self.selectCubeFromExistingCubesOrNull()
        cubestrings = Cubes::cubes().map{|cube| Cubes::cubeToString(cube) }
        cubestring = Miscellaneous::chooseALinePecoStyle("cube:", [""]+cubestrings)
        return nil if cubestring == ""
        Cubes::cubes()
            .select{|cube| Cubes::cubeToString(cube) == cubestring }
            .first
    end

    # Cubes::cubeMatchesPattern(cube, pattern)
    def self.cubeMatchesPattern(cube, pattern)
        return true if cube["uuid"].downcase.include?(pattern.downcase)
        return true if Cubes::cubeToString(cube).downcase.include?(pattern.downcase)
        if cube["type"] == "unique-name" then
            return true if cube["name"].downcase.include?(pattern.downcase)
        end
        false
    end

    # Cubes::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        Cubes::cubes()
            .select{|cube| Cubes::cubeMatchesPattern(cube, pattern) }
            .map{|cube|
                {
                    "description"   => Cubes::cubeToString(cube),
                    "referencetime" => Cubes::getCubeReferenceUnixtime(cube),
                    "dive"          => lambda{ Cubes::cubeDive(cube) }
                }
            }
    end

    # Cubes::issueZeroOrMoreCubeTagsForCubeInteractively(cube)
    def self.issueZeroOrMoreCubeTagsForCubeInteractively(cube)
        loop {
            payload = LucilleCore::askQuestionAnswerAsString("tag (empty to exit) : ")
            break if payload.size == 0
            Tags::issueTag(cube["uuid"], payload)
        }
    end

    # Cubes::attachCubeToZeroOrMoreCliquesInteractively(cube)
    def self.attachCubeToZeroOrMoreCliquesInteractively(cube)
        Cliques::selectZeroOrMoreCliquesExistingOrCreated()
            .each{|clique| Arrows::issue(clique, cube) }
    end

    # Cubes::ensureCubeDescription(cube)
    def self.ensureCubeDescription(cube)
        return if Cubes::getCubeDescriptionZDescriptionOrNull(cube)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description.size == 0
        DescriptionZ::issue(cube["uuid"], description)
    end

    # Cubes::ensureAtLeastOneCubeCliques(cube)
    def self.ensureAtLeastOneCubeCliques(cube)
        if Cubes::getCubeCliques(cube).empty? then
            Cubes::attachCubeToZeroOrMoreCliquesInteractively(cube)
        end
    end

    # Cubes::getCubeTags(cube)
    def self.getCubeTags(cube)
        Tags::getTagsForTargetUUID(cube["uuid"])
    end
end
