
# encoding: UTF-8

class PageCached
    # PageCached::forget(page)
    def self.forget(page)
        InMemoryWithOnDiskPersistenceValueCache::delete("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{page["uuid"]}") # toString
    end
end

class Pages

    # Pages::commitPageToDisk(page)
    def self.commitPageToDisk(page)
        NyxObjects::put(page)
    end

    # Pages::issueNewPageInteractivelyOrNull()
    def self.issueNewPageInteractivelyOrNull()
        puts "Issuing a new Page..."

        page = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        #puts JSON.pretty_generate(page)
        Pages::commitPageToDisk(page)

        frame = Frames::issueNewFrameInteractivelyOrNull()
        return page if frame.nil?
        #puts JSON.pretty_generate(frame)

        flock = Flocks::issue()
        Arrows::issue(flock, frame)
        Arrows::issue(page, flock)

        if ["line", "url", "text"].include?(frame["type"]) then
            return page
        end

        description = LucilleCore::askQuestionAnswerAsString("page description: ")
        if description.size > 0 then
            descriptionz = DescriptionZ::issue(page["uuid"], description)
            puts JSON.pretty_generate(descriptionz)
        end

        page
    end

    # Pages::pages()
    def self.pages()
        NyxObjects::getSet("6b240037-8f5f-4f52-841d-12106658171f")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Pages::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # Pages::destroyPageByUUID(uuid)
    def self.destroyPageByUUID(uuid)
        NyxObjects::destroy(uuid)
    end

    # Pages::pageToString(page)
    def self.pageToString(page)
        str = InMemoryWithOnDiskPersistenceValueCache::getOrNull("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{page["uuid"]}")
        return str if str

        description = Pages::getPageDescriptionZDescriptionOrNull(page)
        if description then
            str = "[page] [#{page["uuid"][0, 4]}] #{description}"
            InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{page["uuid"]}", str)
            return str
        end

        flocks = Flocks::getFlocksForSource(page)
        if flocks.size > 0 then
            str = Flocks::flockToString(flocks[0])
            InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{page["uuid"]}", str)
            return str
        end

        str = "[page] [#{page["uuid"][0, 4]}] [no description]"
        InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{page["uuid"]}", str)
        str
    end

    # Pages::pageDive(page)
    def self.pageDive(page)
        loop {

            page = Pages::getOrNull(page["uuid"])

            return if page.nil? # Could have been destroyed in the previous loop

            system("clear")

            PageCached::forget(page)

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule(false)
            # -------------------------------------------
            # Page metadata
            puts "Page: #{Pages::pageToString(page)}"

            descriptionz = DescriptionZ::getDescriptionZsForTargetInTimeOrder(page["uuid"]).last
            if descriptionz then
                puts "    description: #{descriptionz["description"]}"
            else
                puts "    #{Pages::pageToString(page)}"
            end

            puts "    uuid: #{page["uuid"]}"
            puts "    date: #{Pages::getPageReferenceDateTime(page)}"

            notetext = Notes::getMostRecentTextForTargetOrNull(page["uuid"])
            if notetext then
                puts ""
                puts "Note:"
                puts notetext.lines.map{|line| "    #{line}" }.join()
            end

            Comments::getCommentsForTargetInTimeOrder(page["uuid"]).each{|comment|
                puts ""
                puts "Comment:"
                puts NyxBlobs::getBlobOrNull(comment["namedhash"]).lines.map{|line| "    #{line}" }.join()
            }

            Pages::getPageTags(page)
                .each{|tag|
                    puts "tag: #{tag["payload"]}"
                }

            puts ""

            if DescriptionZ::getDescriptionZsForTargetInTimeOrder(page["uuid"]).last then
                menuitems.item(
                    "description (update)",
                    lambda{
                        description = Pages::getPageDescriptionZDescriptionOrNull(page)
                        if description.nil? then
                            description = LucilleCore::askQuestionAnswerAsString("description: ")
                        else
                            description = Miscellaneous::editTextUsingTextmate(description).strip
                        end
                        return if description == ""
                        DescriptionZ::issue(page["uuid"], description)
                    }
                )
            else
                menuitems.item(
                    "description (set)",
                    lambda{
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        return if description == ""
                        DescriptionZ::issue(page["uuid"], description)
                    }
                )
            end

            menuitems.item(
                "datetime (update)",
                lambda{
                    datetime = Miscellaneous::editTextUsingTextmate(Pages::getPageReferenceDateTime(page)).strip
                    return if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
                    DateTimeZ::issue(page["uuid"], datetime)
                }
            )

            menuitems.item(
                "top note (edit)", 
                lambda{ 
                    text = Notes::getMostRecentTextForTargetOrNull(page["uuid"]) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    Notes::issue(page["uuid"], text)
                }
            )

            menuitems.item(
                "comment (new)", 
                lambda{ 
                    text = Miscellaneous::editTextUsingTextmate("").strip
                    Comments::issue(page["uuid"], nil, text)
                }
            )

            menuitems.item(
                "tag (add)",
                lambda {
                    payload = LucilleCore::askQuestionAnswerAsString("tag: ")
                    return if payload.size == 0
                    Tags::issueTag(page["uuid"], payload)
                }
            )

            menuitems.item(
                "tag (select and remove)",
                lambda {
                    tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", Pages::getPageTags(page), lambda{|tag| tag["payload"] })
                    return if tag.nil?
                    Tags::destroyTag(tag)
                }
            )

            menuitems.item(
                "page (destroy)", 
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this page ? ") then
                        NyxObjects::destroy(page["uuid"])
                    end
                }
            )

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Operations

            puts "Flocks:"
            puts ""

            Flocks::getFlocksForSource(page).each{|flock|
                frame = Flocks::getLastFlockFrameOrNull(flock)
                next if frame.nil?
                menuitems.item(
                    Frames::frameToString(frame),
                    lambda { Frames::openFrame(flock, frame) }
                )
            }

            puts ""
            menuitems.item(
                "add new frame to page",
                lambda { 
                    frame = Frames::issueNewFrameInteractivelyOrNull()
                    return if frame.nil?
                    flock = Flocks::issue()
                    Arrows::issue(flock, frame)
                    Arrows::issue(page, flock)
                }
            )

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Related

            puts "Cliques:"

            Arrows::getSourceOfGivenSetsForTarget(page, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
                .sort{|o1, o2| Cliques::getLastActivityUnixtime(o1) <=> Cliques::getLastActivityUnixtime(o2) }
                .each{|clique|
                    menuitems.item(
                        Cliques::cliqueToString(clique), 
                        lambda { Cliques::cliqueDive(clique) }
                    )
                }

            puts ""
            puts "Page/Cliques Operations:"

            menuitems.item(
                "clique (link to)",
                lambda {
                    clique = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
                    return if clique.nil?
                    Arrows::issue(clique, page)
                }
            )

            menuitems.item(
                "clique (select and unlink)",
                lambda {
                    clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", Pages::getPageCliques(page), lambda{|clique| Cliques::cliqueToString(clique) })
                    return if clique.nil?
                    Arrows::issue(clique, page)
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

    # Pages::getPageCliques(page)
    def self.getPageCliques(page)
        Arrows::getSourceOfGivenSetsForTarget(page, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"])
    end

    # Pages::getPageReferenceDateTime(page)
    def self.getPageReferenceDateTime(page)
        datetimezs = DateTimeZ::getDateTimeZsForTargetInTimeOrder(page["uuid"])
        return Time.at(page["unixtime"]).utc.iso8601 if datetimezs.empty?
        datetimezs.last["datetimeISO8601"]
    end

    # Pages::getPageReferenceUnixtime(page)
    def self.getPageReferenceUnixtime(page)
        DateTime.parse(Pages::getPageReferenceDateTime(page)).to_time.to_f
    end

    # Pages::getPageDescriptionZDescriptionOrNull(page)
    def self.getPageDescriptionZDescriptionOrNull(page)
        descriptionzs = DescriptionZ::getDescriptionZsForTargetInTimeOrder(page["uuid"])
        return nil if descriptionzs.empty?
        descriptionzs.last["description"]
    end

    # Pages::pageuuidToString(pageuuid)
    def self.pageuuidToString(pageuuid)
        page = Pages::getOrNull(pageuuid)
        return "[page not found]" if page.nil?
        Pages::pageToString(page)
    end

    # Pages::selectPageFromPageuuidsOrNull(pageuuids)
    def self.selectPageFromPageuuidsOrNull(pageuuids)
        if pageuuids.size == 0 then
            return nil
        end
        if pageuuids.size == 1 then
            pageuuid = pageuuids[0]
            return Pages::getOrNull(pageuuid)
        end

        pageuuid = LucilleCore::selectEntityFromListOfEntitiesOrNull("page: ", pageuuids, lambda{|uuid| Pages::pageuuidToString(uuid) })
        return nil if pageuuid.nil?
        Pages::getOrNull(pageuuid)
    end

    # Pages::pagesListingAndDive()
    def self.pagesListingAndDive()
        loop {
            ms = LCoreMenuItemsNX1.new()
            Pages::pages()
                .sort{|q1, q2| q1["unixtime"]<=>q2["unixtime"] }
                .each{|page|
                    ms.item(
                        Pages::pageToString(page), 
                        lambda{ Pages::pageDive(page) }
                    )
                }
            status = ms.prompt()
            break if !status
        }
    end

    # Pages::selectPageFromExistingPagesOrNull()
    def self.selectPageFromExistingPagesOrNull()
        pagestrings = Pages::pages().map{|page| Pages::pageToString(page) }
        pagestring = Miscellaneous::chooseALinePecoStyle("page:", [""]+pagestrings)
        return nil if pagestring == ""
        Pages::pages()
            .select{|page| Pages::pageToString(page) == pagestring }
            .first
    end

    # Pages::pageMatchesPattern(page, pattern)
    def self.pageMatchesPattern(page, pattern)
        return true if page["uuid"].downcase.include?(pattern.downcase)
        return true if Pages::pageToString(page).downcase.include?(pattern.downcase)
        if page["type"] == "unique-name" then
            return true if page["name"].downcase.include?(pattern.downcase)
        end
        false
    end

    # Pages::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        Pages::pages()
            .select{|page| Pages::pageMatchesPattern(page, pattern) }
            .map{|page|
                {
                    "description"   => Pages::pageToString(page),
                    "referencetime" => Pages::getPageReferenceUnixtime(page),
                    "dive"          => lambda{ Pages::pageDive(page) }
                }
            }
    end

    # Pages::issueZeroOrMorePageTagsForPageInteractively(page)
    def self.issueZeroOrMorePageTagsForPageInteractively(page)
        loop {
            payload = LucilleCore::askQuestionAnswerAsString("tag (empty to exit) : ")
            break if payload.size == 0
            Tags::issueTag(page["uuid"], payload)
        }
    end

    # Pages::attachPageToZeroOrMoreCliquesInteractively(page)
    def self.attachPageToZeroOrMoreCliquesInteractively(page)
        Cliques::selectZeroOrMoreCliquesExistingOrCreated()
            .each{|clique| Arrows::issue(clique, page) }
    end

    # Pages::ensurePageDescription(page)
    def self.ensurePageDescription(page)
        return if Pages::getPageDescriptionZDescriptionOrNull(page)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description.size == 0
        DescriptionZ::issue(page["uuid"], description)
    end

    # Pages::ensureAtLeastOnePageCliques(page)
    def self.ensureAtLeastOnePageCliques(page)
        if Pages::getPageCliques(page).empty? then
            Pages::attachPageToZeroOrMoreCliquesInteractively(page)
        end
    end

    # Pages::getPageTags(page)
    def self.getPageTags(page)
        Tags::getTagsForTargetUUID(page["uuid"])
    end
end
