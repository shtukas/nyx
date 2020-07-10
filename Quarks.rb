
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
require_relative "Common.rb"
require_relative "Bosons.rb"
require_relative "NyxGenericObjectInterface.rb"
require_relative "LibrarianAion.rb"
require_relative "DataPortalUI.rb"
require_relative "Tags.rb"

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
        filepath = "/tmp/#{CatalystCommon::l22()}.txt"
        FileUtils.touch(filepath)
        system("open '#{filepath}'")
        LucilleCore::pressEnterToContinue()
        filepath
    end

    # QuarksUtils::textToFilepath(text)
    def self.textToFilepath(text)
        filepath = "/tmp/#{CatalystCommon::l22()}.txt"
        File.open(filepath, "w"){|f| f.puts(text) }
        filepath
    end
end

class QuarksMakers

    # QuarksMakers::makeQuarkLineInteractively()
    def self.makeQuarkLineInteractively()
        line = LucilleCore::askQuestionAnswerAsString("line: ")
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"         => Time.new.to_f,
            "description"      => line,
            "type"             => "line",
            "line"             => line,
            "textnote"         => nil
        }
    end

    # QuarksMakers::makeQuarkUrl(url, description)
    def self.makeQuarkUrl(url, description)
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"         => Time.new.to_f,
            "description"      => description,
            "type"             => "url",
            "url"              => url,
            "textnote"         => nil
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
        location = QuarksUtils::selectOneLocationOnTheDesktopOrNull()
        return nil if location.nil?
        namedhash = LibrarianAionOperator::locationToNamedHash(location)
        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"         => Time.new.to_f,
            "description"      => description,
            "type"             => "aion-point",
            "namedhash"        => namedhash,
            "textnote"         => nil
        }
    end

    # QuarksMakers::makeQuarkAionPointFromFilepathAndDescription(filepath, description)
    def self.makeQuarkAionPointFromFilepathAndDescription(filepath, description)
        namedhash = LibrarianAionOperator::locationToNamedHash(filepath)
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"         => Time.new.to_f,
            "description"      => description,
            "type"             => "aion-point",
            "namedhash"        => namedhash,
            "textnote"         => nil
        }
    end

    # QuarksMakers::makeQuarkAionPointFromLocation(location)
    def self.makeQuarkAionPointFromLocation(location)
        raise "f8e3b314" if !File.exists?(location)
        namedhash = LibrarianAionOperator::locationToNamedHash(location)
        description = File.basename(location)
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"         => Time.new.to_f,
            "description"      => description,
            "type"             => "aion-point",
            "namedhash"        => namedhash,
            "textnote"         => nil
        }
    end

    # QuarksMakers::makeQuarkUniqueNameInteractivelyOrNull()
    def self.makeQuarkUniqueNameInteractivelyOrNull()
        uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
        return nil if uniquename.size == 0
        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "unixtime"         => Time.new.to_f,
            "description"      => description,
            "type"             => "unique-name",
            "name"             => uniquename,
            "textnote"         => nil
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
                folderpath = LibrarianDeskOperator::deskFolderpathForQuarkCreateIfNotExists(quark)
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

    # Quarks::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # Quarks::quarkToString(quark)
    def self.quarkToString(quark)
        if quark["description"] then
            return "[quark] [#{quark["uuid"][0, 4]}] (#{quark["type"]}) #{quark["description"]}"
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
            folderpath = LibrarianDeskOperator::deskFolderpathForQuarkCreateIfNotExists(quark)
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
                    if CatalystCommon::fileByFilenameIsSafelyOpenable(File.basename(location)) then
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

            CatalystCommon::horizontalRule(false)

            puts Quarks::quarkToString(quark)
            puts "uuid: #{quark["uuid"]}"
            puts "date: #{Time.at(quark["unixtime"]).utc.iso8601}"
            puts "tags: #{Quarks::getQuarkTags(quark).map{|tag| tag["payload"] }.join(", ")}"

            if quark["textnote"] then
                puts "Note:"
                namedhash = quark["textnote"]
                text = NyxBlobs::getBlobOrNull(namedhash)
                puts text
            end

            CatalystCommon::horizontalRule(true)

            menuitems = LCoreMenuItemsNX1.new()

            menuitems.item(
                "open", 
                lambda{ Quarks::openQuark(quark) }
            )

            menuitems.item(
                "description (update)",
                lambda{
                    description = 
                        if ( quark["description"].nil? or quark["description"].size == 0 ) then
                            description = LucilleCore::askQuestionAnswerAsString("description: ")
                        else
                            description = CatalystCommon::editTextUsingTextmate(quark["description"]).strip
                        end
                    return if description == ""
                    quark["description"] = description
                    Quarks::commitQuarkToDisk(quark)
                }
            )


            menuitems.item(
                "datetime (update)",
                lambda{
                    datetime = CatalystCommon::editTextUsingTextmate(Time.at(quark["unixtime"]).utc.iso8601).strip
                    return if !NSXMiscUtils::dateIsIso8601Format?(datetime)
                    unixtime = DateTime.parse(datetime).to_time.to_f
                    quark["unixtime"] = unixtime
                    Quarks::commitQuarkToDisk(quark)
                }
            )

            menuitems.item(
                "textnote (edit)", 
                lambda{ 
                    text = ""
                    if quark["textnote"] then
                        namedhash = quark["textnote"]
                        text = NyxBlobs::getBlobOrNull(namedhash)
                    end
                    text = CatalystCommon::editTextUsingTextmate(text).strip
                    namedhash = NyxBlobs::put(text)
                    quark["textnote"] = namedhash
                    Quarks::commitQuarkToDisk(quark)
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

            CatalystCommon::horizontalRule(true)

            NyxRoles::getRolesForTarget(quark["uuid"])
                .each{|object| 
                    menuitems.item(
                        NyxRoles::objectToString(object), 
                        lambda{ NyxRoles::objectDive(object) }
                    )
                }

            Bosons::getCliquesForQuark(quark)
                .sort{|o1, o2| NyxGenericObjectInterface::objectLastActivityUnixtime(o1) <=> NyxGenericObjectInterface::objectLastActivityUnixtime(o2) }
                .each{|object|
                    menuitems.item(
                        NyxGenericObjectInterface::objectToString(object), 
                        lambda { NyxGenericObjectInterface::objectDive(object) }
                    )
                }

            CatalystCommon::horizontalRule(true)

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
        quarkstring = CatalystCommon::chooseALinePecoStyle("quark:", [""]+quarkstrings)
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
                    "referencetime" => quark["unixtime"],
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
        if quark["description"].nil? then
            quark["description"] = LucilleCore::askQuestionAnswerAsString("quark description: ")
            Quarks::commitQuarkToDisk(quark)
        end
        quark
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
