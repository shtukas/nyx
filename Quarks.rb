
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

require_relative "AtlasCore.rb"
require_relative "Miscellaneous.rb"
require_relative "Bosons.rb"
require_relative "Librarian.rb"
require_relative "DataPortalUI.rb"
require_relative "Tags.rb"
require_relative "Notes.rb"
require_relative "DateTimeZ.rb"
require_relative "DescriptionZ.rb"

# -----------------------------------------------------------------

class QuarksUtils

    # QuarksUtils::selectOneLocationOnTheDesktopOrNull()
    def self.selectOneLocationOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.basename(filepath) != 'pascal.png' }
                            .select{|filepath| File.basename(filepath) != 'Todo-Inbox' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # QuarksUtils::makeNewTextFileInteractivelyReturnFilepath()
    def self.makeNewTextFileInteractivelyReturnFilepath()
        filepath = "/tmp/#{Miscellaneous::l22()}.txt"
        FileUtils.touch(filepath)
        system("open '#{filepath}'")
        LucilleCore::pressEnterToContinue()
        filepath
    end

    # QuarksUtils::textToFilepath(text)
    def self.textToFilepath(text)
        filepath = "/tmp/#{Miscellaneous::l22()}.txt"
        File.open(filepath, "w"){|f| f.puts(text) }
        filepath
    end
end

class QuarksMakers

    # QuarksMakers::makeQuarkLineInteractively()
    def self.makeQuarkLineInteractively()
        uuid = SecureRandom.uuid
        line = LucilleCore::askQuestionAnswerAsString("line: ")
        DescriptionZ::issue(uuid, line)
        {
            "uuid"             => uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"         => Time.new.to_f,
            "type"             => "line",
            "line"             => line
        }
    end

    # QuarksMakers::makeQuarkUrl(url, description)
    def self.makeQuarkUrl(url, description)
        uuid = SecureRandom.uuid
        DescriptionZ::issue(uuid, description)
        {
            "uuid"             => uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"         => Time.new.to_f,
            "type"             => "url",
            "url"              => url
        }
    end

    # QuarksMakers::makeQuarkUrlInteractively()
    def self.makeQuarkUrlInteractively()
        url = LucilleCore::askQuestionAnswerAsString("url: ")
        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        QuarksMakers::makeQuarkUrl(url, description)
    end

    # QuarksMakers::makeQuarkAionPointInteractivelyOrNull()
    def self.makeQuarkAionPointInteractivelyOrNull()
        uuid = SecureRandom.uuid
        location = QuarksUtils::selectOneLocationOnTheDesktopOrNull()
        return nil if location.nil?
        namedhash = LibrarianOperator::locationToNamedHash(location)
        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        DescriptionZ::issue(uuid, description)
        {
            "uuid"             => uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"         => Time.new.to_f,
            "type"             => "aion-point",
            "namedhash"        => namedhash
        }
    end

    # QuarksMakers::makeQuarkAionPointFromFilepathAndDescription(filepath, description)
    def self.makeQuarkAionPointFromFilepathAndDescription(filepath, description)
        uuid = SecureRandom.uuid
        namedhash = LibrarianOperator::locationToNamedHash(filepath)
        DescriptionZ::issue(uuid, description)
        {
            "uuid"             => uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"         => Time.new.to_f,
            "type"             => "aion-point",
            "namedhash"        => namedhash
        }
    end

    # QuarksMakers::makeQuarkAionPointFromLocation(location)
    def self.makeQuarkAionPointFromLocation(location)
        raise "f8e3b314" if !File.exists?(location)
        uuid = SecureRandom.uuid
        namedhash = LibrarianOperator::locationToNamedHash(location)
        description = File.basename(location)
        DescriptionZ::issue(uuid, description)
        {
            "uuid"             => uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"         => Time.new.to_f,
            "type"             => "aion-point",
            "namedhash"        => namedhash
        }
    end

    # QuarksMakers::makeQuarkUniqueNameInteractivelyOrNull()
    def self.makeQuarkUniqueNameInteractivelyOrNull()
        uuid = SecureRandom.uuid
        uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
        return nil if uniquename.size == 0
        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        DescriptionZ::issue(uuid, description)
        {
            "uuid"             => uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"         => Time.new.to_f,
            "type"             => "unique-name",
            "name"             => uniquename
        }
    end

    # QuarksMakers::makeNewQuarkInteractivelyOrNull()
    def self.makeNewQuarkInteractivelyOrNull()
        puts "Making a new Quark..."
        types = ["line", "url", "fs-location aion-point", "new text file", "unique-name"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            return QuarksMakers::makeQuarkLineInteractively()
        end
        if type == "url" then
            return QuarksMakers::makeQuarkUrlInteractively()
        end
        if type == "fs-location aion-point" then
            return QuarksMakers::makeQuarkAionPointInteractivelyOrNull()
        end
        if type == "new text file" then
            filepath = QuarksUtils::makeNewTextFileInteractivelyReturnFilepath()
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return QuarksMakers::makeQuarkAionPointFromFilepathAndDescription(filepath, description)
        end
        if type == "unique-name" then
            return QuarksMakers::makeQuarkUniqueNameInteractivelyOrNull()
        end
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
        quark = QuarksMakers::makeNewQuarkInteractivelyOrNull()
        return nil if quark.nil?
        Quarks::commitQuarkToDisk(quark)
        quark
    end

    # Quarks::issueQuarkAionPointFromLocation(location)
    def self.issueQuarkAionPointFromLocation(location)
        quark = QuarksMakers::makeQuarkAionPointFromLocation(location)
        Quarks::commitQuarkToDisk(quark)
        quark
    end

    # Quarks::quarks()
    def self.quarks()
        NyxObjects::getSet("6b240037-8f5f-4f52-841d-12106658171f")
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Quarks::destroyQuarkByUUID(uuid)
    def self.destroyQuarkByUUID(uuid)
        quark = Quarks::getOrNull(uuid)
        if quark then
             if quark["type"] == "aion-point" then
                folderpath = DeskOperator::deskFolderpathForQuarkCreateIfNotExists(quark)
                if folderpath then
                    LucilleCore::removeFileSystemLocation(folderpath)
                end
            end
        end
        NyxObjects::destroy(uuid)
    end

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

    # Quarks::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # Quarks::getQuarkDescriptionOrNull(quark)
    def self.getQuarkDescriptionOrNull(quark)
        descriptionzs = DescriptionZ::getForTargetUUIDInTimeOrder(quark["uuid"])
        return nil if descriptionzs.empty?
        descriptionzs.last["description"]
    end

    # Quarks::quarkToString(quark)
    def self.quarkToString(quark)
        description = Quarks::getQuarkDescriptionOrNull(quark)
        if description then
            return  "[quark] [#{quark["uuid"][0, 4]}] (#{quark["type"]}) #{description}"
        end
        if quark["type"] == "line" then
            return "[quark] [#{quark["uuid"][0, 4]}] [line] #{quark["line"]}"
        end
        if quark["type"] == "url" then
            return "[quark] [#{quark["uuid"][0, 4]}] [url] #{quark["url"]}"
        end
        if quark["type"] == "aion-point" then
            return "[quark] [#{quark["uuid"][0, 4]}] [aion-point] #{quark["namedhash"]}"
        end
        if quark["type"] == "unique-name" then
            return "[quark] [#{quark["uuid"][0, 4]}] [unique name] #{quark["name"]}"
        end
        raise "Quark error 3c7968e4"
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

    # Quarks::openQuark(quark)
    def self.openQuark(quark)
        if quark["type"] == "line" then
            puts quark["line"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if quark["type"] == "aion-point" then
            folderpath = DeskOperator::deskFolderpathForQuarkCreateIfNotExists(quark)
            system("open '#{folderpath}'")
            return
        end
        if quark["type"] == "url" then
            system("open '#{quark["url"]}'")
            return
        end
        if quark["type"] == "unique-name" then
            uniquename = quark["name"]
            location = AtlasCore::uniqueStringToLocationOrNull(uniquename)
            if location then
                if File.file?(location) then
                    if Miscellaneous::fileByFilenameIsSafelyOpenable(File.basename(location)) then
                        puts "opening safely openable file '#{location}'"
                        system("open '#{location}'")
                    else
                        puts "opening parent folder of '#{location}'"
                        system("open '#{File.dirname(location)}'")
                    end
                else
                    puts "opening folder '#{location}'"
                    system("open '#{location}'")
                end
            else
                puts "I could not determine the location of unique name: #{uniquename}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        raise "Quark error 160050-490261"
    end

    # Quarks::quarkDive(quark)
    def self.quarkDive(quark)
        loop {

            quark = Quarks::getOrNull(quark["uuid"])

            return if quark.nil? # Could have been destroyed in the previous loop

            system("clear")

            Miscellaneous::horizontalRule(false)

            puts Quarks::quarkToString(quark)
            puts "uuid: #{quark["uuid"]}"
            DescriptionZ::getForTargetUUIDInTimeOrder(quark["uuid"]).each{|descriptionz|
                puts "description: #{descriptionz["description"]}"
            }
            puts "date: #{Quarks::getQuarkReferenceDateTime(quark)}"
            Quarks::getQuarkTags(quark).each{|tag|
                puts "tag: #{tag["payload"]}"
            }

            notetext = Notes::getMostRecentTextForTargetOrNull(quark["uuid"])
            if notetext then
                puts "Note:"
                puts notetext
            end

            Miscellaneous::horizontalRule(true)

            menuitems = LCoreMenuItemsNX1.new()

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
                    DescriptionZ::issueReplacementOfAnyExisting(quark["uuid"], description)
                }
            )


            menuitems.item(
                "datetime (update)",
                lambda{
                    datetime = Miscellaneous::editTextUsingTextmate(Quarks::getQuarkReferenceDateTime(quark)).strip
                    return if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
                    DateTimeZ::issueReplacementOfAnyExisting(quark["uuid"], datetime)
                }
            )

            menuitems.item(
                "textnote (edit)", 
                lambda{ 
                    text = Notes::getMostRecentTextForTargetOrNull(quark["uuid"]) || ""
                    text = Miscellaneous::editTextUsingTextmate(text).strip
                    Notes::issue(quark["uuid"], text)
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
                "quark (recast)", 
                lambda { Quarks::recastQuark(quark) }
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

    # Quarks::recastQuark(quark)
    def self.recastQuark(quark)
        # This function makes a new quark, gives it the uuid of the argument and saves it.
        # Thereby replacing the argument by a new one, of a possibly different type.
        # If we were to just create a new quark and delete the old one, the new one would not 
        # inherit the links of the old one.
        newquark = QuarksMakers::makeNewQuarkInteractivelyOrNull()
        newquark["uuid"] = quark["uuid"] # uuid override
        Quarks::commitQuarkToDisk(newquark)
        newquark
    end

    # Quarks::getQuarkTags(quark)
    def self.getQuarkTags(quark)
        Tags::getTagsForTargetUUID(quark["uuid"])
    end
end
