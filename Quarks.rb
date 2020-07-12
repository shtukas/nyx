
# encoding: UTF-8

# require_relative "Quarks.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require_relative "KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require_relative "AtlasCore.rb"
require_relative "Miscellaneous.rb"
require_relative "Bosons.rb"
require_relative "Librarian.rb"
require_relative "DataPortalUI.rb"
require_relative "Tags.rb"
require_relative "Notes.rb"
require_relative "DateTimeZ.rb"
require_relative "DescriptionZ.rb"
require_relative "Spins.rb"
require_relative "Comments.rb"
require_relative "InMemoryGlobalHash"

# -----------------------------------------------------------------

class QuarkCached

    # QuarkCached::quarkToStringUseTheForce(quark)
    def self.quarkToStringUseTheForce(quark)
        description = Quarks::getQuarkDescriptionOrNull(quark)
        if description then
            return  "[quark] [#{quark["uuid"][0, 4]}] (#{quark["type"]}) #{description}"
        end
        spin = Quarks::getQuarkLatestSpinsOrNull(quark)
        spinstring = spin ? Spins::spinToString(spin) : "[no spin]"
        "[quark] [#{quark["uuid"][0, 4]}] #{spinstring}"
    end

    # QuarkCached::quarkToStringForgetCachedValues(quark)
    def self.quarkToStringForgetCachedValues(quark)
        InMemoryGlobalHash::delete("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{quark["uuid"]}")
        KeyValueStore::destroy(nil, "9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{quark["uuid"]}")
    end

    # QuarkCached::forget(quark)
    def self.forget(quark)
        QuarkCached::quarkToStringForgetCachedValues(quark)
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

        quark = {
            "uuid"      => quarkuuid,
            "nyxNxSet"  => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"  => Time.new.to_f
        }
        Quarks::commitQuarkToDisk(quark)

        description = LucilleCore::askQuestionAnswerAsString("description: ")
        if description.size > 0 then
            DescriptionZ::issue(quarkuuid, description)
        end
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
        description = InMemoryGlobalHash::getOrNull("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{quark["uuid"]}")
        if description then
            return description 
        end
        description = KeyValueStore::getOrNull(nil, "9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{quark["uuid"]}")
        if description then
            InMemoryGlobalHash::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{quark["uuid"]}", description)
            return description
        end
        description = QuarkCached::quarkToStringUseTheForce(quark)
        KeyValueStore::set(nil, "9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{quark["uuid"]}", description)
        InMemoryGlobalHash::set("9c26b6e2-ab55-4fed-a632-b8b1bdbc6e82:#{quark["uuid"]}", description)
        description
    end

    # Quarks::openQuark(quark)
    def self.openQuark(quark)
        spin = Quarks::getQuarkLatestSpinsOrNull(quark)
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

            Miscellaneous::horizontalRule(false)

            puts Quarks::quarkToString(quark)
            puts "uuid: #{quark["uuid"]}"

            DescriptionZ::getForTargetUUIDInTimeOrder(quark["uuid"])
                .last(1)
                .each{|descriptionz|
                    puts "description: #{descriptionz["description"]}"
                }

            puts "date: #{Quarks::getQuarkReferenceDateTime(quark)}"

            Quarks::getQuarkTags(quark)
                .each{|tag|
                    puts "tag: #{tag["payload"]}"
                }

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

            Miscellaneous::horizontalRule(true)

            menuitems = LCoreMenuItemsNX1.new()

            Quarks::getQuarkSpins(quark)
                .last(1)
                .each{|spin|
                    puts Spins::spinToString(spin)
                }

            Miscellaneous::horizontalRule(true)

            menuitems.item(
                "open", 
                lambda{ Quarks::openQuark(quark) }
            )

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
                    payload = {
                        "type"  => "quarks",
                        "uuids" => [ quark["uuid"] ]
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

    # Quarks::getQuarkLatestSpinsOrNull(quark)
    def self.getQuarkLatestSpinsOrNull(quark)
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
