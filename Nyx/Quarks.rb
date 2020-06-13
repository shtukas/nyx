
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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Links.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"

require_relative "Librarian.rb"

# -----------------------------------------------------------------

class Quark

    # Quark::selectOneFilepathOnTheDesktopOrNull()
    def self.selectOneFilepathOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.file?(filepath) }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # Quark::selectOneFolderpathOnTheDesktopOrNull()
    def self.selectOneFolderpathOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.directory?(filepath) }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("folderpath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # --------------------------------------------------
    # Issuers

    # Quark::issueQuarkLineInteractively()
    def self.issueQuarkLineInteractively()
        line = LucilleCore::askQuestionAnswerAsString("line: ")
        quark = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "description"      => line,
            "type"             => "line",
            "line"             => line
        }
        NyxIO::commitToDisk(quark)
        quark
    end

    # Quark::issueQuarkUrlInteractively()
    def self.issueQuarkUrlInteractively()
        url = LucilleCore::askQuestionAnswerAsString("url: ")
        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        quark = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "type"             => "url",
            "url"              => url
        }
        NyxIO::commitToDisk(quark)
        quark
    end

    # Quark::issueQuarkFileInteractivelyOrNull()
    def self.issueQuarkFileInteractivelyOrNull()
        filepath1 = Quark::selectOneFilepathOnTheDesktopOrNull()
        return nil if filepath1.nil?
        filename1 = File.basename(filepath1)
        filename2 = "#{CatalystCommon::l22()}-#{filename1}"
        filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
        FileUtils.mv(filepath1, filepath2)
        LibrarianFile::copyFileToRepository(filepath2)
        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        quark = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "type"             => "file",
            "filename"         => filename2
        }
        NyxIO::commitToDisk(quark)
        quark
    end

    # Quark::issueQuarkFile(filepath)
    def self.issueQuarkFile(filepath1)
        filename2 = "#{CatalystCommon::l22()}-#{File.basename(filepath1)}"
        filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
        FileUtils.mv(filepath1, filepath2)
        LibrarianFile::copyFileToRepository(filepath2)
        quark = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "type"             => "file",
            "filename"         => filename2
        }
        NyxIO::commitToDisk(quark)
        quark
    end

    # Quark::issueQuarkFromText(text)
    def self.issueQuarkFromText(text)
        filename = LibrarianFile::textToFilename(text)
        quark = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "type"             => "file",
            "filename"         => filename
        }
        NyxIO::commitToDisk(quark)
        quark
    end

    # Quark::issueQuarkFolderInteractivelyOrNull()
    def self.issueQuarkFolderInteractivelyOrNull()
        folderpath1 = Quark::selectOneFolderpathOnTheDesktopOrNull()
        return nil if folderpath1.nil?
        foldername1 = File.basename(folderpath1)
        foldername2 = "#{CatalystCommon::l22()}-#{foldername1}"
        folderpath2 = "#{File.dirname(folderpath1)}/#{foldername2}"
        FileUtils.mv(folderpath1, folderpath2)
        LibrarianDirectory::copyDirectoryToRepository(folderpath2)
        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        quark = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "type"             => "folder",
            "foldername"       => foldername2
        }
        NyxIO::commitToDisk(quark)
        quark
    end

    # Quark::locationToFileOrFolderQuarkIssued(location)
    def self.locationToFileOrFolderQuarkIssued(location)
        raise "f8e3b314" if !File.exists?(location)
        if File.file?(location) then
            filepath1 = location
            filename1 = File.basename(filepath1)
            filename2 = "#{CatalystCommon::l22()}-#{filename1}"
            filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
            FileUtils.mv(filepath1, filepath2)
            LibrarianFile::copyFileToRepository(filepath2)
            FileUtils.mv(filepath2, filepath1) # putting thing back so that the location doesn't disappear under the nose of the caller
            quark = {
                "uuid"             => SecureRandom.uuid,
                "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
                "creationUnixtime" => Time.new.to_f,
                "type"             => "file",
                "filename"         => filename2
            }
            NyxIO::commitToDisk(quark)
            quark
        else
            folderpath1 = location
            foldername1 = File.basename(folderpath1)
            foldername2 = "#{CatalystCommon::l22()}-#{foldername1}"
            folderpath2 = "#{File.dirname(foldername1)}/#{foldername2}"
            FileUtils.mv(folderpath1, folderpath2)
            LibrarianDirectory::copyDirectoryToRepository(folderpath2)
            FileUtils.mv(folderpath2, folderpath1) # putting thing back so that the location doesn't disappear under the nose of the caller
            quark = {
                "uuid"             => SecureRandom.uuid,
                "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
                "creationUnixtime" => Time.new.to_f,
                "type"             => "folder",
                "foldername"       => foldername2
            }
            NyxIO::commitToDisk(quark)
            quark
        end
    end

    # Quark::issueQuarkUniqueNameInteractively()
    def self.issueQuarkUniqueNameInteractively()
        uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
        description = LucilleCore::askQuestionAnswerAsString("quark description: ")
        quark = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "type"             => "unique-name",
            "name"             => uniquename
        }
        NyxIO::commitToDisk(quark)
        quark
    end

    # Quark::issueQuarkDirectoryMarkInteractively()
    def self.issueQuarkDirectoryMarkInteractively()
        options = ["mark file already exists", "mark file should be created"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return nil if option.nil?
        if option == "mark file already exists" then
            mark = LucilleCore::askQuestionAnswerAsString("mark: ")
            description = LucilleCore::askQuestionAnswerAsString("quark description: ")
            quark = {
                "uuid"             => SecureRandom.uuid,
                "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
                "creationUnixtime" => Time.new.to_f,
                "description"      => description,
                "type"             => "directory-mark",
                "mark"             => mark
            }
            NyxIO::commitToDisk(quark)
            return quark
        end
        if option == "mark file should be created" then
            mark = nil
            loop {
                quarkFolderLocation = LucilleCore::askQuestionAnswerAsString("Location to the quark folder: ")
                if !File.exists?(quarkFolderLocation) then
                    puts "I can't see location '#{quarkFolderLocation}'"
                    puts "Let's try that again..."
                    next
                end
                mark = SecureRandom.uuid
                markFilepath = "#{quarkFolderLocation}/Nyx-Directory-Mark.txt"
                File.open(markFilepath, "w"){|f| f.write(mark) }
                break
            }
            description = LucilleCore::askQuestionAnswerAsString("quark description: ")
            quark = {
                "uuid"             => SecureRandom.uuid,
                "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
                "creationUnixtime" => Time.new.to_f,
                "description"      => description,
                "type"             => "directory-mark",
                "mark"             => mark
            }
            NyxIO::commitToDisk(quark)
            return quark
        end
    end

    # Quark::issueQuarkDataPodInteractively()
    def self.issueQuarkDataPodInteractively()
        podname = LucilleCore::askQuestionAnswerAsString("podname: ")
        quark = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "type"             => "datapod",
            "podname"          => podname
        }
        NyxIO::commitToDisk(quark)
        quark
    end

    # --------------------------------------------------
    # User Interface

    # Quark::issueNewQuarkInteractivelyOrNull()
    def self.issueNewQuarkInteractivelyOrNull()
        puts "Making a new Quark..."
        types = ["line", "url", "file", "new text file", "folder", "unique-name", "directory-mark", "datapod"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            return Quark::issueQuarkLineInteractively()
        end
        if type == "url" then
            return Quark::issueQuarkUrlInteractively()
        end
        if type == "file" then
            return Quark::issueQuarkFileInteractivelyOrNull()
        end
        if type == "new text file" then
            filename = LibrarianFile::makeNewTextFileInteractivelyReturnLibrarianFilename()
            quark = {
                "uuid"             => SecureRandom.uuid,
                "nyxType"          => "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
                "creationUnixtime" => Time.new.to_f,
                "type"             => "file",
                "filename"         => filename
            }
            NyxIO::commitToDisk(quark)
            return quark
        end
        if type == "folder" then
            return Quark::issueQuarkFolderInteractivelyOrNull()
        end
        if type == "unique-name" then
            return Quark::issueQuarkUniqueNameInteractively()
        end
        if type == "directory-mark" then
            return Quark::issueQuarkDirectoryMarkInteractively()
        end
        if type == "datapod" then
            return Quark::issueQuarkDataPodInteractively()
        end
    end

    # Quark::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxIO::getOrNull(uuid)
    end

    # Quark::quarkToString(quark)
    def self.quarkToString(quark)
        if quark["description"] then
            if quark["type"] == "file" then
                return "[quark] [#{quark["type"]}] (#{File.extname(quark["filename"])}) #{quark["description"]}"
            else
                return "[quark] [#{quark["type"]}] #{quark["description"]}"
            end
        end
        if quark["type"] == "line" then
            return "[quark] [line] #{quark["line"]}"
        end
        if quark["type"] == "file" then
            return "[quark] [file] #{quark["filename"]}"
        end
        if quark["type"] == "url" then
            return "[quark] [url] #{quark["url"]}"
        end
        if quark["type"] == "folder" then
            return "[quark] [folder] #{quark["foldername"]}"
        end
        if quark["type"] == "unique-name" then
            return "[quark] [unique name] #{quark["name"]}"
        end
        if quark["type"] == "directory-mark" then
            return "[quark] [directory mark] #{quark["mark"]}"
        end
        if quark["type"] == "datapod" then
            return "[quark] [datapod] #{quark["podname"]}"
        end
        raise "Quark error 3c7968e4"
    end

    # Quark::openQuark(quark)
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
                puts "opening: #{location}"
                system("open '#{location}'")
            else
                puts "I could not determine the location of unique name: #{uniquename}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if quark["type"] == "directory-mark" then
            mark = quark["mark"]
            location = AtlasCore::uniqueStringToLocationOrNull(mark)
            if location then
                puts "opening: #{File.dirname(location)}"
                system("open '#{File.dirname(location)}'")
            else
                puts "I could not determine the location of mark: #{mark}"
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

    # Quark::quarkDive(quark)
    def self.quarkDive(quark)
        loop {
            system("clear")
            puts Quark::quarkToString(quark).green
            operations = ["open", "set description"]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operations", operations)
            return if operation.nil?
            if operation == "open" then
                Quark::openQuark(quark)
            end
            if operation == "set description" then
                description = LucilleCore::askQuestionAnswerAsString("quark description: ")
                next if description == ""
                quark["description"] = description
                NyxIO::commitToDisk(quark)
            end
        }
    end
end
