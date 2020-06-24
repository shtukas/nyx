
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Quarks.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Bosons.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"

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
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "description"      => line,
            "type"             => "line",
            "line"             => line
        }
    end

    # QuarksMakers::makeQuarkUrlInteractively()
    def self.makeQuarkUrlInteractively()
        url = LucilleCore::askQuestionAnswerAsString("url: ")
        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "type"             => "url",
            "url"              => url
        }
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
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
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
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
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
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
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
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
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
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
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
                "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
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
                "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
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
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "type"             => "unique-name",
            "name"             => uniquename
        }
    end

    # QuarksMakers::makeQuarkDataPodInteractively()
    def self.makeQuarkDataPodInteractively()
        podname = LucilleCore::askQuestionAnswerAsString("podname: ")
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "type"             => "datapod",
            "podname"          => podname
        }
    end

    # QuarksMakers::makeNewQuarkInteractivelyOrNull()
    def self.makeNewQuarkInteractivelyOrNull()
        puts "Making a new Quark..."
        types = ["line", "url", "file", "new text file", "folder", "unique-name", "datapod"]
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
        if type == "datapod" then
            return QuarksMakers::makeQuarkDataPodInteractively()
        end
    end
end

class Quarks

    # Quarks::issueNewQuarkInteractivelyOrNull()
    def self.issueNewQuarkInteractivelyOrNull()
        puts "Issuing a new Quark..."
        quark = QuarksMakers::makeNewQuarkInteractivelyOrNull()
        return nil if quark.nil?
        NyxIO::commitToDisk(quark)
        quark
    end

    # Quarks::issueQuarkFileOrFolderFromLocation(location)
    def self.issueQuarkFileOrFolderFromLocation(location)
        quark = QuarksMakers::makeQuarkFileOrFolderFromLocation(location)
        NyxIO::commitToDisk(quark)
        quark
    end

    # Quarks::quarks()
    def self.quarks()
        NyxIO::objects("quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end

    # Quarks::destroyQuarkByUUID(uuid)
    def self.destroyQuarkByUUID(uuid)
        NyxIO::destroyAtType(uuid, "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2")
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

    # Quarks::quarkHasConnections(quark)
    def self.quarkHasConnections(quark)
        return true if Bosons2::getLinkedObjects(quark).size > 0
        return true if NyxRoles::getRolesForTarget(quark["uuid"]).size > 0
        false
    end

    # Quarks::getQuarkTags(quark)
    def self.getQuarkTags(quark)
        Bosons2::getLinkedObjects(quark)
            .select{|object| object["nyxType"] == "tag-57c7eced-24a8-466d-a6fe-588142afd53b" }
    end

    # Quarks::getQuarkCliques(quark)
    def self.getQuarkCliques(quark)
        Bosons2::getLinkedObjects(quark)
            .select{|object| object["nyxType"] == "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721" }
    end

    # Quarks::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxIO::getOrNull(uuid)
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
        if quark["type"] == "datapod" then
            return "[quark] [#{quark["uuid"][0, 4]}] [datapod] #{quark["podname"]}"
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
        if quark["type"] == "datapod" then
            podname = quark["podname"]
            puts "#{podname}"
            puts "I do not yet know how to open/access/browse DataPods"
            LucilleCore::pressEnterToContinue()
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
            puts Quarks::quarkToString(quark).green
            puts "uuid: #{quark["uuid"]}"

            items = []

            items << [
                "open", 
                lambda{ Quarks::openQuark(quark) }
            ]

            items << [
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
                    NyxIO::commitToDisk(quark)
                }
            ]

            items << [
                "tag (add)",
                lambda {
                    payload = LucilleCore::askQuestionAnswerAsString("tag payload: ")
                    tag = Tags::issueTag(payload)
                    Bosons2::link(quark, tag)
                }
            ]

            items << [
                "clique (link to)",
                lambda {
                    clique = Cliques::selectCliqueFromExistingOrCreateOneOrNull()
                    return if clique.nil?
                    Bosons2::link(quark, clique)
                }
            ]

            items << [
                "clique (select and unlink)",
                lambda {
                    clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", Quarks::getQuarkCliques(quark), lambda{|clique| Cliques::cliqueToString(clique) })
                    return if clique.nil?
                    Bosons2::unlink(quark, clique)
                }
            ]

            items << [
                "quark (make new + attach to this with gluon)",
                lambda {
                    newquark = Quarks::issueNewQuarkInteractivelyOrNull()
                    return if newquark.nil?
                    Gluons::issueLink(quark, newquark)
                    Quarks::issueZeroOrMoreTagsForQuarkInteractively(newquark)
                }
            ]

            items << [
                "quark (select existing + attach to this with gluon)",
                lambda {
                    quark2 = Quarks::selectQuarkFromExistingQuarksOrNull()
                    return if quark2.nil?
                    return if quark["uuid"] == quark2["uuid"]
                    Gluons::issueLink(quark, quark2)
                }
            ]

            items << [
                "opencycle (register as)", 
                lambda { OpenCycles::issueFromQuark(quark) }
            ]

            items << [
                "quark (recast)", 
                lambda { Quarks::recastQuark(quark) }
            ]

            items << [
                "quark (destroy)", 
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure to want to destroy this quark ? ") then
                        NyxIO::destroy(quark["uuid"])
                    end
                }
            ]

            items << nil

            NyxRoles::getRolesForTarget(quark["uuid"])
                .each{|object| items << [NyxRoles::objectToString(object), lambda{ NyxRoles::objectDive(object) }] }

            items << nil

            Gluons::getLinkedQuarks(quark)
                .sort{|q1, q2| q1["creationUnixtime"] <=> q2["creationUnixtime"] }
                .each{|q|
                    items << [ Quarks::quarkToString(q), lambda{ Quarks::quarkDive(q) } ]
                }

            Cliques::getCliqueBosonLinkedObjects(quark)
                .sort{|o1, o2| NyxDataCarriers::objectLastActivityUnixtime(o1) <=> NyxDataCarriers::objectLastActivityUnixtime(o2) }
                .each{|object|
                    object = NyxDataCarriers::applyQuarkToCubeUpgradeIfRelevant(object)
                    items << [NyxDataCarriers::objectToString(object), lambda { NyxDataCarriers::objectDive(object) } ]
                }

            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

    # Quarks::quarksListingAndDive()
    def self.quarksListingAndDive()
        loop {
            items = []
            Quarks::quarks()
                .sort{|q1, q2| q1["creationUnixtime"]<=>q2["creationUnixtime"] }
                .each{|quark|
                    items << [ Quarks::quarkToString(quark), lambda{ Quarks::quarkDive(quark) }]
                }
            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
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

    # Quarks::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        Quarks::quarks()
            .select{|quark| 
                [
                    quark["uuid"].downcase.include?(pattern.downcase),
                    Quarks::quarkToString(quark).downcase.include?(pattern.downcase)
                ].any?
            }
            .map{|quark|
                {
                    "description"   => Quarks::quarkToString(quark),
                    "referencetime" => quark["creationUnixtime"],
                    "dive"          => lambda{ Quarks::quarkDive(quark) }
                }
            }
    end

    # Quarks::issueZeroOrMoreTagsForQuarkInteractively(quark)
    def self.issueZeroOrMoreTagsForQuarkInteractively(quark)
        loop {
            tagPayload = LucilleCore::askQuestionAnswerAsString("tag payload (empty to exit) : ")
            break if tagPayload.size == 0
            tag = Tags::issueTag(tagPayload)
            Bosons2::link(quark, tag)
        }
    end

    # Quarks::attachQuarkToZeroOrMoreCliquesInteractively(quark)
    def self.attachQuarkToZeroOrMoreCliquesInteractively(quark)
        Cliques::selectZeroOrMoreCliquesExistingOrCreated()
            .each{|clique|
                Bosons2::link(quark, clique)
            }
    end

    # Quarks::ensureQuarkDescription(quark)
    def self.ensureQuarkDescription(quark)
        if quark["description"].nil? then
            quark["description"] = LucilleCore::askQuestionAnswerAsString("quark description: ")
            NyxIO::commitToDisk(quark)
        end
        quark
    end

    # Quarks::ensureAtLeastOneQuarkTags(quark)
    def self.ensureAtLeastOneQuarkTags(quark)
        if Quarks::getQuarkTags(quark).empty? then
            Quarks::issueZeroOrMoreTagsForQuarkInteractively(quark)
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
        NyxIO::commitToDisk(newquark)
        newquark
    end
end
