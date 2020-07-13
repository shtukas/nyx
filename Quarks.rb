
# encoding: UTF-8

class QuarkCached
    # QuarkCached::forget(quark)
    def self.forget(quark)
        InMemoryWithOnDiskPersistenceValueCache::delete("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{quark["uuid"]}") # toString
    end
end

class Quarks

    # Quarks::commitQuarkToDisk(quark)
    def self.commitQuarkToDisk(quark)
        NyxObjects::put(quark)
    end

    # Quarks::issueNewQuarkInteractivelyOrNull()
    def self.issueNewQuarkInteractivelyOrNull()
        puts "Issuing a new Quark..."

        quarkuuid = SecureRandom.uuid

        spin = Spins::issueNewSpinInteractivelyOrNull(quarkuuid)
        return nil if spin.nil?

        #puts JSON.pretty_generate(spin)

        quark = {
            "uuid"      => quarkuuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        #puts JSON.pretty_generate(quark)
        Quarks::commitQuarkToDisk(quark)

        if ["line", "url", "text"].include?(spin["type"]) then
            return quark
        end

        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        if description.size > 0 then
            descriptionz = DescriptionZ::issue(quarkuuid, description)
            puts JSON.pretty_generate(descriptionz)
        end

        quark
    end

    # Quarks::quarks()
    def self.quarks()
        NyxObjects::getSet("6b240037-8f5f-4f52-841d-12106658171f")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Quarks::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # Quarks::destroyQuarkByUUID(uuid)
    def self.destroyQuarkByUUID(uuid)
        quark = Quarks::getOrNull(uuid)
        if quark then
             if quark["type"] == "aion-point" then
                folderpath = DeskOperator::deskFolderpathForSpinCreateIfNotExists(quark)
                if folderpath then
                    LucilleCore::removeFileSystemLocation(folderpath)
                end
            end
        end
        NyxObjects::destroy(uuid)
    end

    # Quarks::quarkToString(quark)
    def self.quarkToString(quark)
        str = InMemoryWithOnDiskPersistenceValueCache::getOrNull("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{quark["uuid"]}")
        return str if str

        str = (lambda{|quark|
            description = Quarks::getQuarkDescriptionOrNull(quark)
            if description then
                return  "[quark] [#{quark["uuid"][0, 4]}] #{description}"
            end
            spin = Quarks::getQuarkLatestSpinOrNull(quark)
            if spin then
                return "[quark] [#{quark["uuid"][0, 4]}] #{Spins::spinToString(spin)}"
            end
            "[quark] [#{quark["uuid"][0, 4]}] [no spin]"
        }).call(quark)

        InMemoryWithOnDiskPersistenceValueCache::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{quark["uuid"]}", str)

        str
    end

    # Quarks::openQuark(quark)
    def self.openQuark(quark)
        spin = Quarks::getQuarkLatestSpinOrNull(quark)
        return if spin.nil?
        Spins::openSpin(spin)
    end

    # Quarks::quarkDive(quark)
    def self.quarkDive(quark)
        loop {

            quark = Quarks::getOrNull(quark["uuid"])

            return if quark.nil? # Could have been destroyed in the previous loop

            system("clear")

            QuarkCached::forget(quark)

            menuitems = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule(false)
            # -------------------------------------------
            # Quark metadata

            DescriptionZ::getForTargetUUIDInTimeOrder(quark["uuid"])
                .last(1)
                .each{|descriptionz|
                    puts "description: #{descriptionz["description"]}"
                }

            puts ""

            puts "uuid: #{quark["uuid"]}"

            puts "date: #{Quarks::getQuarkReferenceDateTime(quark)}"

            notetext = Notes::getMostRecentTextForTargetOrNull(quark["uuid"])
            if notetext then
                puts ""
                puts "Note:"
                puts notetext
            end

            Comments::getForTargetUUIDInTimeOrder(quark["uuid"]).each{|comment|
                puts ""
                puts "Comment:"
                puts NyxBlobs::getBlobOrNull(comment["namedhash"])
            }

            Quarks::getQuarkTags(quark)
                .each{|tag|
                    puts "tag: #{tag["payload"]}"
                }

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Operations

            puts "Quark Operations:"

            menuitems.item(
                "description (update)",
                lambda{
                    description = Quarks::getQuarkDescriptionOrNull(quark)
                    if description.nil? then
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                    else
                        description = Miscellaneous::editTextUsingTextmate(description).strip
                    end
                    return if description == ""
                    DescriptionZ::issue(quark["uuid"], description)
                }
            )

            menuitems.item(
                "datetime (update)",
                lambda{
                    datetime = Miscellaneous::editTextUsingTextmate(Quarks::getQuarkReferenceDateTime(quark)).strip
                    return if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
                    DateTimeZ::issue(quark["uuid"], datetime)
                }
            )

            menuitems.item(
                "top note (edit)", 
                lambda{ 
                    text = Notes::getMostRecentTextForTargetOrNull(quark["uuid"]) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    Notes::issue(quark["uuid"], text)
                }
            )

            menuitems.item(
                "comment (new)", 
                lambda{ 
                    text = Miscellaneous::editTextUsingTextmate("").strip
                    Comments::issue(quark["uuid"], nil, text)
                }
            )

            menuitems.item(
                "tag (add)",
                lambda {
                    payload = LucilleCore::askQuestionAnswerAsString("tag: ")
                    return if payload.size == 0
                    Tags::issueTag(quark["uuid"], payload)
                }
            )

            menuitems.item(
                "tag (select and remove)",
                lambda {
                    tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", Quarks::getQuarkTags(quark), lambda{|tag| tag["payload"] })
                    return if tag.nil?
                    Tags::destroyTag(tag)
                }
            )

            menuitems.item(
                "clique (link to)",
                lambda {
                    clique = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
                    return if clique.nil?
                    Bosons::issue(clique, quark)
                }
            )

            menuitems.item(
                "clique (select and unlink)",
                lambda {
                    clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", Quarks::getQuarkCliques(quark), lambda{|clique| Cliques::cliqueToString(clique) })
                    return if clique.nil?
                    Bosons::issue(clique, quark)
                }
            )

            menuitems.item(
                "asteroid (create with this as target)", 
                lambda { 
                    description = LucilleCore::askQuestionAnswerAsString("asteroid payload series description: ")
                    return if description == ""
                    payload = {
                        "type"        => "quarks",
                        "uuids"       => [ quark["uuid"] ],
                        "description" => description
                    }
                    orbital = Asteroids::makeOrbitalInteractivelyOrNull()
                    return if orbital.nil?
                    asteroid = Asteroids::issue(payload, orbital)
                    puts JSON.pretty_generate(asteroid)
                }
            )

            menuitems.item(
                "re-spin", 
                lambda { 
                    puts "re spinning is not implemented yet"
                    LucilleCore::pressEnterToContinue()
                }
            )

            menuitems.item(
                "quark (destroy)", 
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this quark ? ") then
                        NyxObjects::destroy(quark["uuid"])
                    end
                }
            )

            menuitems.item(
                "/", 
                lambda { DataPortalUI::dataPortalFront() }
            )

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Operations

            puts "Data:"

            Quarks::getQuarkSpins(quark)
                .last(1)
                .each{|spin|
                    menuitems.item(
                        Spins::spinToString(spin),
                        lambda{ Spins::openSpin(spin) }
                    )
                }

            Miscellaneous::horizontalRule(true)
            # ----------------------------------------------------------
            # Related

            puts "Related Objects"

            TodoRoles::getRolesForTarget(quark["uuid"])
                .each{|object| 
                    menuitems.item(
                        TodoRoles::objectToString(object), 
                        lambda{ TodoRoles::objectDive(object) }
                    )
                }

            Bosons::getCliquesForQuark(quark)
                .sort{|o1, o2| Cliques::getLastActivityUnixtime(o1) <=> Cliques::getLastActivityUnixtime(o2) }
                .each{|clique|
                    menuitems.item(
                        Cliques::cliqueToString(clique), 
                        lambda { Cliques::cliqueDive(clique) }
                    )
                }

            Miscellaneous::horizontalRule(true)

            status = menuitems.prompt()
            break if !status
        }
    end

    # ---------------------------------------------

    # Quarks::getQuarkCliques(quark)
    def self.getQuarkCliques(quark)
        Bosons::getCliquesForQuark(quark)
            .select{|object| object["nyxNxSet"] == "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5" }
    end

    # Quarks::getQuarkReferenceDateTime(quark)
    def self.getQuarkReferenceDateTime(quark)
        datetimezs = DateTimeZ::getForTargetUUIDInTimeOrder(quark["uuid"])
        return Time.at(quark["unixtime"]).utc.iso8601 if datetimezs.empty?
        datetimezs.last["datetimeISO8601"]
    end

    # Quarks::getQuarkReferenceUnixtime(quark)
    def self.getQuarkReferenceUnixtime(quark)
        DateTime.parse(Quarks::getQuarkReferenceDateTime(quark)).to_time.to_f
    end

    # Quarks::getQuarkSpins(quark)
    def self.getQuarkSpins(quark)
        Spins::getForTargetUUIDInTimeOrder(quark["uuid"])
    end

    # Quarks::getQuarkLatestSpinOrNull(quark)
    def self.getQuarkLatestSpinOrNull(quark)
        spins = Quarks::getQuarkSpins(quark)
        return nil if spins.empty?
        spins.last
    end

    # Quarks::getQuarkDescriptionOrNull(quark)
    def self.getQuarkDescriptionOrNull(quark)
        descriptionzs = DescriptionZ::getForTargetUUIDInTimeOrder(quark["uuid"])
        return nil if descriptionzs.empty?
        descriptionzs.last["description"]
    end

    # Quarks::quarkuuidToString(quarkuuid)
    def self.quarkuuidToString(quarkuuid)
        quark = Quarks::getOrNull(quarkuuid)
        return "[quark not found]" if quark.nil?
        Quarks::quarkToString(quark)
    end

    # Quarks::selectQuarkFromQuarkuuidsOrNull(quarkuuids)
    def self.selectQuarkFromQuarkuuidsOrNull(quarkuuids)
        if quarkuuids.size == 0 then
            return nil
        end
        if quarkuuids.size == 1 then
            quarkuuid = quarkuuids[0]
            return Quarks::getOrNull(quarkuuid)
        end

        quarkuuid = LucilleCore::selectEntityFromListOfEntitiesOrNull("quark: ", quarkuuids, lambda{|uuid| Quarks::quarkuuidToString(uuid) })
        return nil if quarkuuid.nil?
        Quarks::getOrNull(quarkuuid)
    end

    # Quarks::quarksListingAndDive()
    def self.quarksListingAndDive()
        loop {
            ms = LCoreMenuItemsNX1.new()
            Quarks::quarks()
                .sort{|q1, q2| q1["unixtime"]<=>q2["unixtime"] }
                .each{|quark|
                    ms.item(
                        Quarks::quarkToString(quark), 
                        lambda{ Quarks::quarkDive(quark) }
                    )
                }
            status = ms.prompt()
            break if !status
        }
    end

    # Quarks::selectQuarkFromExistingQuarksOrNull()
    def self.selectQuarkFromExistingQuarksOrNull()
        quarkstrings = Quarks::quarks().map{|quark| Quarks::quarkToString(quark) }
        quarkstring = Miscellaneous::chooseALinePecoStyle("quark:", [""]+quarkstrings)
        return nil if quarkstring == ""
        Quarks::quarks()
            .select{|quark| Quarks::quarkToString(quark) == quarkstring }
            .first
    end

    # Quarks::quarkMatchesPattern(quark, pattern)
    def self.quarkMatchesPattern(quark, pattern)
        return true if quark["uuid"].downcase.include?(pattern.downcase)
        return true if Quarks::quarkToString(quark).downcase.include?(pattern.downcase)
        if quark["type"] == "unique-name" then
            return true if quark["name"].downcase.include?(pattern.downcase)
        end
        false
    end

    # Quarks::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        Quarks::quarks()
            .select{|quark| Quarks::quarkMatchesPattern(quark, pattern) }
            .map{|quark|
                {
                    "description"   => Quarks::quarkToString(quark),
                    "referencetime" => Quarks::getQuarkReferenceUnixtime(quark),
                    "dive"          => lambda{ Quarks::quarkDive(quark) }
                }
            }
    end

    # Quarks::issueZeroOrMoreQuarkTagsForQuarkInteractively(quark)
    def self.issueZeroOrMoreQuarkTagsForQuarkInteractively(quark)
        loop {
            payload = LucilleCore::askQuestionAnswerAsString("tag (empty to exit) : ")
            break if payload.size == 0
            Tags::issueTag(quark["uuid"], payload)
        }
    end

    # Quarks::attachQuarkToZeroOrMoreCliquesInteractively(quark)
    def self.attachQuarkToZeroOrMoreCliquesInteractively(quark)
        Cliques::selectZeroOrMoreCliquesExistingOrCreated()
            .each{|clique| Bosons::issue(clique, quark) }
    end

    # Quarks::ensureQuarkDescription(quark)
    def self.ensureQuarkDescription(quark)
        return if Quarks::getQuarkDescriptionOrNull(quark)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description.size == 0
        DescriptionZ::issue(quark["uuid"], description)
    end

    # Quarks::ensureAtLeastOneQuarkCliques(quark)
    def self.ensureAtLeastOneQuarkCliques(quark)
        if Quarks::getQuarkCliques(quark).empty? then
            Quarks::attachQuarkToZeroOrMoreCliquesInteractively(quark)
        end
    end

    # Quarks::getQuarkTags(quark)
    def self.getQuarkTags(quark)
        Tags::getTagsForTargetUUID(quark["uuid"])
    end
end
