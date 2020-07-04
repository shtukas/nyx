
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

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/AtlasCore.rb"

require_relative "Common.rb"

require_relative "Bosons.rb"
require_relative "NyxGenericObjectInterface.rb"

require_relative "Librarian.rb"

# -----------------------------------------------------------------

class QuarksUtils
    # QuarksUtils::selectOneFilepathOnTheDesktopOrNull()
    def self.selectOneFilepathOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.file?(filepath) }
                            .select{|filepath| File.basename(filepath) != 'pascal.png' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # QuarksUtils::selectOneFolderpathOnTheDesktopOrNull()
    def self.selectOneFolderpathOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.directory?(filepath) }
                            .select{|filepath| File.basename(filepath) != 'Todo-Inbox' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("folderpath", desktopLocations, lambda{ |location| File.basename(location) })
    end
end

class QuarksMakers

    # QuarksMakers::makeQuarkLineInteractively()
    def self.makeQuarkLineInteractively()
        line = LucilleCore::askQuestionAnswerAsString("line: ")
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "creationUnixtime" => Time.new.to_f,
            "description"      => line,
            "type"             => "line",
            "line"             => line
        }
    end

    # QuarksMakers::makeQuarkUrl(url, description)
    def self.makeQuarkUrl(url, description)
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
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

    # QuarksMakers::makeQuarkFileInteractivelyOrNull()
    def self.makeQuarkFileInteractivelyOrNull()
        filepath1 = QuarksUtils::selectOneFilepathOnTheDesktopOrNull()
        return nil if filepath1.nil?
        filename1 = File.basename(filepath1)
        filename2 = "#{CatalystCommon::l22()}-#{filename1}"
        filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
        FileUtils.mv(filepath1, filepath2)
        LibrarianFile::copyFileToRepository(filepath2)
        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "type"             => "file",
            "filename"         => filename2
        }
    end

    # QuarksMakers::makeQuarkFile(filepath)
    def self.makeQuarkFile(filepath1)
        filename2 = "#{CatalystCommon::l22()}-#{File.basename(filepath1)}"
        filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
        FileUtils.mv(filepath1, filepath2)
        LibrarianFile::copyFileToRepository(filepath2)
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "creationUnixtime" => Time.new.to_f,
            "type"             => "file",
            "filename"         => filename2
        }
    end

    # QuarksMakers::makeQuarkFileFromTextInteractively(text)
    def self.makeQuarkFileFromTextInteractively(text)
        filename = LibrarianFile::textToFilename(text)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "type"             => "file",
            "filename"         => filename
        }
    end

    # QuarksMakers::makeQuarkFileFromFilenameAndDescription(filename, description)
    def self.makeQuarkFileFromFilenameAndDescription(filename, description)
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "type"             => "file",
            "filename"         => filename
        }
    end

    # QuarksMakers::makeQuarkFolderInteractivelyOrNull()
    def self.makeQuarkFolderInteractivelyOrNull()
        folderpath1 = QuarksUtils::selectOneFolderpathOnTheDesktopOrNull()
        return nil if folderpath1.nil?
        foldername1 = File.basename(folderpath1)
        foldername2 = "#{CatalystCommon::l22()}-#{foldername1}"
        folderpath2 = "#{File.dirname(folderpath1)}/#{foldername2}"
        FileUtils.mv(folderpath1, folderpath2)
        LibrarianDirectory::copyDirectoryToRepository(folderpath2)
        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "type"             => "folder",
            "foldername"       => foldername2
        }
    end

    # QuarksMakers::makeQuarkFileOrFolderFromLocation(location)
    def self.makeQuarkFileOrFolderFromLocation(location)
        raise "f8e3b314" if !File.exists?(location)
        if File.file?(location) then
            filepath1 = location
            filename1 = File.basename(filepath1)
            filename2 = "#{CatalystCommon::l22()}-#{filename1}"
            filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
            FileUtils.mv(filepath1, filepath2)
            LibrarianFile::copyFileToRepository(filepath2)
            FileUtils.mv(filepath2, filepath1) # putting thing back so that the location doesn't disappear under the nose of the caller
            {
                "uuid"             => SecureRandom.uuid,
                "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
                "creationUnixtime" => Time.new.to_f,
                "type"             => "file",
                "filename"         => filename2
            }
        else
            folderpath1 = location
            foldername1 = File.basename(folderpath1)
            foldername2 = "#{CatalystCommon::l22()}-#{foldername1}"
            folderpath2 = "#{File.dirname(foldername1)}/#{foldername2}"
            FileUtils.mv(folderpath1, folderpath2)
            LibrarianDirectory::copyDirectoryToRepository(folderpath2)
            FileUtils.mv(folderpath2, folderpath1) # putting thing back so that the location doesn't disappear under the nose of the caller
            {
                "uuid"             => SecureRandom.uuid,
                "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
                "creationUnixtime" => Time.new.to_f,
                "type"             => "folder",
                "foldername"       => foldername2
            }
        end
    end

    # QuarksMakers::makeQuarkUniqueNameInteractivelyOrNull()
    def self.makeQuarkUniqueNameInteractivelyOrNull()
        uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
        return nil if uniquename.size == 0
        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "6b240037-8f5f-4f52-841d-12106658171f",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "type"             => "unique-name",
            "name"             => uniquename
        }
    end

    # QuarksMakers::makeNewQuarkInteractivelyOrNull()
    def self.makeNewQuarkInteractivelyOrNull()
        puts "Making a new Quark..."
        types = ["line", "url", "file", "new text file", "folder", "unique-name"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            return QuarksMakers::makeQuarkLineInteractively()
        end
        if type == "url" then
            return QuarksMakers::makeQuarkUrlInteractively()
        end
        if type == "file" then
            return QuarksMakers::makeQuarkFileInteractivelyOrNull()
        end
        if type == "new text file" then
            filename = LibrarianFile::makeNewTextFileInteractivelyReturnLibrarianFilename()
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return QuarksMakers::makeQuarkFileFromFilenameAndDescription(filename, description)
        end
        if type == "folder" then
            return QuarksMakers::makeQuarkFolderInteractivelyOrNull()
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

    # Quarks::issueQuarkFileOrFolderFromLocation(location)
    def self.issueQuarkFileOrFolderFromLocation(location)
        quark = QuarksMakers::makeQuarkFileOrFolderFromLocation(location)
        Quarks::commitQuarkToDisk(quark)
        quark
    end

    # Quarks::quarks()
    def self.quarks()
        NyxObjects::getSet("6b240037-8f5f-4f52-841d-12106658171f")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end

    # Quarks::destroyQuarkByUUID(uuid)
    def self.destroyQuarkByUUID(uuid)
        NyxObjects::destroy(uuid)
    end

    # Quarks::getQuarksOfTypeFolderByFoldername(foldername)
    def self.getQuarksOfTypeFolderByFoldername(foldername)
        Quarks::quarks()
            .select{|quark| quark["type"] == "folder" and quark["foldername"] == foldername }
    end

    # Quarks::getQuarksOfTypeFileByFilename(filename)
    def self.getQuarksOfTypeFileByFilename(filename)
        Quarks::quarks()
            .select{|quark| quark["type"] == "file" and quark["filename"] == filename }
    end

    # Quarks::getQuarkQuarkTags(quark)
    def self.getQuarkQuarkTags(quark)
        QuarkTags::getQuarkTagsByQuarkUUID(quark["uuid"])
    end

    # Quarks::getQuarkCliques(quark)
    def self.getQuarkCliques(quark)
        Bosons::getLinkedObjects(quark)
            .select{|object| object["nyxNxSet"] == "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5" }
    end

    # Quarks::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # Quarks::quarkToString(quark)
    def self.quarkToString(quark)
        if quark["description"] then
            if quark["type"] == "file" then
                return "[quark] [#{quark["uuid"][0, 4]}] [#{quark["type"]}#{File.extname(quark["filename"])}] #{quark["description"]}"
            else
                return "[quark] [#{quark["uuid"][0, 4]}] [#{quark["type"]}] #{quark["description"]}"
            end
        end
        if quark["type"] == "line" then
            return "[quark] [#{quark["uuid"][0, 4]}] [line] #{quark["line"]}"
        end
        if quark["type"] == "file" then
            return "[quark] [#{quark["uuid"][0, 4]}] [file] #{quark["filename"]}"
        end
        if quark["type"] == "url" then
            return "[quark] [#{quark["uuid"][0, 4]}] [url] #{quark["url"]}"
        end
        if quark["type"] == "folder" then
            return "[quark] [#{quark["uuid"][0, 4]}] [folder] #{quark["foldername"]}"
        end
        if quark["type"] == "unique-name" then
            return "[quark] [#{quark["uuid"][0, 4]}] [unique name] #{quark["name"]}"
        end
        raise "Quark error 3c7968e4"
    end

    # Quarks::openQuark(quark)
    def self.openQuark(quark)
        if quark["type"] == "line" then
            puts quark["line"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if quark["type"] == "file" then
            LibrarianFile::accessFile(quark["filename"])
            return
        end
        if quark["type"] == "url" then
            system("open '#{quark["url"]}'")
            return
        end
        if quark["type"] == "folder" then
            LibrarianDirectory::openFolder(quark["foldername"])
            return
        end
        if quark["type"] == "unique-name" then
            uniquename = quark["name"]
            location = AtlasCore::uniqueStringToLocationOrNull(uniquename)
            if location then
                if File.file?(location) then
                    if LibrarianFile::fileByFilenameIsSafelyOpenable(File.basename(location)) then
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

            puts Quarks::quarkToString(quark).green
            puts "uuid: #{quark["uuid"]}"


            menuitems = LCoreMenuItemsNX1.new()

            CatalystCommon::horizontalRule(true)
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
                "tag (add)",
                lambda { QuarkTags::issueQuarkTagInteractivelyOrNull(quark) }
            )

            menuitems.item(
                "clique (link to)",
                lambda {
                    clique = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
                    return if clique.nil?
                    Bosons::link(quark, clique)
                }
            )

            menuitems.item(
                "clique (select and unlink)",
                lambda {
                    clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", Quarks::getQuarkCliques(quark), lambda{|clique| Cliques::cliqueToString(clique) })
                    return if clique.nil?
                    Bosons::unlink(quark, clique)
                }
            )

            menuitems.item(
                "quark (make new + attach to this)",
                lambda {
                    newquark = Quarks::issueNewQuarkInteractivelyOrNull()
                    return if newquark.nil?
                    Bosons::link(quark, newquark)
                    Quarks::issueZeroOrMoreQuarkTagsForQuarkInteractively(newquark)
                }
            )

            menuitems.item(
                "quark (select existing + attach to this)",
                lambda {
                    quark2 = Quarks::selectQuarkFromExistingQuarksOrNull()
                    return if quark2.nil?
                    return if quark["uuid"] == quark2["uuid"]
                    Bosons::link(quark, quark2)
                }
            )

            menuitems.item(
                "asteroid (create with this as target)", 
                lambda { 
                    payload = {
                        "type"      => "quark",
                        "quarkuuid" => quark["uuid"]
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

            CatalystCommon::horizontalRule(true)

            NyxRoles::getRolesForTarget(quark["uuid"])
                .each{|object| 
                    menuitems.item(
                        NyxRoles::objectToString(object), 
                        lambda{ NyxRoles::objectDive(object) }
                    )
                }

            QuarkTags::getQuarkTagsByQuarkUUID(quark["uuid"])
                .each{|tag|
                    menuitems.item(
                        QuarkTags::tagToString(tag), 
                        lambda { QuarkTags::tagDive(tag) }
                    )
                }

            Bosons::getLinkedObjects(quark)
                .sort{|o1, o2| NyxGenericObjectInterface::objectLastActivityUnixtime(o1) <=> NyxGenericObjectInterface::objectLastActivityUnixtime(o2) }
                .each{|object|
                    object = NyxGenericObjectInterface::applyQuarkToCubeUpgradeIfRelevant(object)
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
                .sort{|q1, q2| q1["creationUnixtime"]<=>q2["creationUnixtime"] }
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
                    "referencetime" => quark["creationUnixtime"],
                    "dive"          => lambda{ Quarks::quarkDive(quark) }
                }
            }
    end

    # Quarks::issueZeroOrMoreQuarkTagsForQuarkInteractively(quark)
    def self.issueZeroOrMoreQuarkTagsForQuarkInteractively(quark)
        loop {
            tagPayload = LucilleCore::askQuestionAnswerAsString("tag payload (empty to exit) : ")
            break if tagPayload.size == 0
            QuarkTags::issueTag(quark["uuid"], tagPayload)
        }
    end

    # Quarks::attachQuarkToZeroOrMoreCliquesInteractively(quark)
    def self.attachQuarkToZeroOrMoreCliquesInteractively(quark)
        Cliques::selectZeroOrMoreCliquesExistingOrCreated()
            .each{|clique|
                Bosons::link(quark, clique)
            }
    end

    # Quarks::ensureQuarkDescription(quark)
    def self.ensureQuarkDescription(quark)
        if quark["description"].nil? then
            quark["description"] = LucilleCore::askQuestionAnswerAsString("quark description: ")
            Quarks::commitQuarkToDisk(quark)
        end
        quark
    end

    # Quarks::ensureAtLeastOneQuarkQuarkTags(quark)
    def self.ensureAtLeastOneQuarkQuarkTags(quark)
        if Quarks::getQuarkQuarkTags(quark).empty? then
            Quarks::issueZeroOrMoreQuarkTagsForQuarkInteractively(quark)
        end
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
end
