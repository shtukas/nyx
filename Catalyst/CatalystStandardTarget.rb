
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTarget.rb"
=begin
    CatalystStandardTarget::locationToFileOrFolderTarget(location)
    CatalystStandardTarget::makeNewTargetInteractivelyOrNull()
    CatalystStandardTarget::targetToString(target)
    CatalystStandardTarget::openTarget(target)
=end

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

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/AtlasCore.rb"

# -----------------------------------------------------------------

class CoreDataUtils
    # CoreDataUtils::pathToCoreData()
    def self.pathToCoreData()
        "/Users/pascal/Galaxy/DataBank/Catalyst/CoreData"
    end

    # CoreDataUtils::copyLocationToCatalystBin(location)
    def self.copyLocationToCatalystBin(location)
        return if location.nil?
        return if !File.exists?(location)
        folder1 = "#{CatalystCommon::binTimelineFolderpath()}/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{Time.new.strftime("%Y-%m-%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{LucilleCore::timeStringL22()}"
        FileUtils.mkdir(folder3)
        LucilleCore::copyFileSystemLocation(location, folder3)
    end
end

class CoreDataFile

    # CoreDataFile::filenameToFilepath(filename)
    def self.filenameToFilepath(filename)
        "#{CoreDataUtils::pathToCoreData()}/Files/#{filename}"
    end

    # CoreDataFile::copyFileToRepository(filepath)
    def self.copyFileToRepository(filepath)
        raise "CoreData error 3afc90f9e9bb" if !File.exists?(filepath)
        raise "CoreData error 860270278181" if File.basename(filepath).include?("'")
        filepath2 = "#{CoreDataUtils::pathToCoreData()}/Files/#{File.basename(filepath)}"
        raise "CoreData error 08abbfa63965" if File.exists?(filepath2)
        FileUtils.cp(filepath, filepath2)
    end

    # CoreDataFile::exists?(filename)
    def self.exists?(filename)
        filepath = CoreDataFile::filenameToFilepath(filename)
        File.exists?(filepath)
    end

    # CoreDataFile::fileByFilenameIsSafelyOpenable(filename)
    def self.fileByFilenameIsSafelyOpenable(filename)
        safelyOpeneableExtensions = [".txt", ".jpg", ".jpeg", ".png", ".eml", ".webloc", ".pdf"]
        safelyOpeneableExtensions.any?{|extension| filename.downcase[-extension.size, extension.size] == extension }
    end

    # CoreDataFile::openOrCopyToDesktop(filename)
    def self.openOrCopyToDesktop(filename)
        if CoreDataFile::fileByFilenameIsSafelyOpenable(filename) then
            filepath = CoreDataFile::filenameToFilepath(filename)
            system("open '#{filepath}'")
        else
            filepath = CoreDataFile::filenameToFilepath(filename)
            FileUtils.cp(filepath, "/Users/pascal/Desktop/")
            puts "File copied to Desktop {#{File.basename(filepath)}}"
            LucilleCore::pressEnterToContinue()
        end
    end
end

class CoreDataDirectory

    # CoreDataDirectory::foldernameToFolderpath(foldername)
    def self.foldernameToFolderpath(foldername)
        "#{CoreDataUtils::pathToCoreData()}/Directories/#{foldername}"
    end

    # CoreDataDirectory::exists?(foldername)
    def self.exists?(foldername)
        folderpath = CoreDataDirectory::foldernameToFolderpath(foldername)
        File.exists?(folderpath)
    end

    # CoreDataDirectory::copyFolderToRepository(folderpath)
    def self.copyFolderToRepository(folderpath)
        raise "CoreData error 0c51bcb0a97d" if !File.exists?(folderpath)
        raise "CoreData error a54826bb1621" if File.basename(folderpath).include?("'")
        folderpath2 = "#{CoreDataUtils::pathToCoreData()}/Directories/#{File.basename(folderpath)}"
        raise "CoreData error d4d6143b3d7d" if File.exists?(folderpath2)
        LucilleCore::copyFileSystemLocation(folderpath, "#{CoreDataUtils::pathToCoreData()}/Directories")
    end

    # CoreDataDirectory::openFolder(foldername)
    def self.openFolder(foldername)
        folderpath = CoreDataDirectory::foldernameToFolderpath(foldername)
        return if !File.exists?(folderpath)
        system("open '#{folderpath}'")
    end
end

class CatalystStandardTarget

    # --------------------------------------------------
    # Makers

    # CatalystStandardTarget::selectOneFilepathOnTheDesktopOrNull()
    def self.selectOneFilepathOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.file?(filepath) }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # CatalystStandardTarget::selectOneFolderpathOnTheDesktopOrNull()
    def self.selectOneFolderpathOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.directory?(filepath) }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("folderpath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # CatalystStandardTarget::makeTargetLineInteractively()
    def self.makeTargetLineInteractively()
        line = LucilleCore::askQuestionAnswerAsString("line: ")
        return {
            "uuid" => SecureRandom.uuid,
            "type" => "line",
            "line" => line
        }
    end

    # CatalystStandardTarget::makeTargetUrlInteractively()
    def self.makeTargetUrlInteractively()
        url = LucilleCore::askQuestionAnswerAsString("url: ")
        return {
            "uuid" => SecureRandom.uuid,
            "type" => "url",
            "url"  => url
        }
    end

    # CatalystStandardTarget::makeTargetFileInteractivelyOrNull()
    def self.makeTargetFileInteractivelyOrNull()
        filepath1 = CatalystStandardTarget::selectOneFilepathOnTheDesktopOrNull()
        return nil if filepath1.nil?
        filename1 = File.basename(filepath1)
        filename2 = "#{CatalystCommon::l22()}-#{filename1}"
        filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
        FileUtils.mv(filepath1, filepath2)
        CoreDataFile::copyFileToRepository(filepath2)
        return {
            "uuid"     => SecureRandom.uuid,
            "type"     => "file",
            "filename" => filename2
        }
    end

    # CatalystStandardTarget::makeTargetFolderInteractivelyOrNull()
    def self.makeTargetFolderInteractivelyOrNull()
        folderpath1 = CatalystStandardTarget::selectOneFolderpathOnTheDesktopOrNull()
        return nil if folderpath1.nil?
        foldername1 = File.basename(folderpath1)
        foldername2 = "#{CatalystCommon::l22()}-#{foldername1}"
        folderpath2 = "#{File.dirname(foldername1)}/#{foldername2}"
        FileUtils.mv(folderpath1, folderpath2)
        CoreDataDirectory::copyFolderToRepository(folderpath2)
        return {
            "uuid"       => SecureRandom.uuid,
            "type"       => "folder",
            "foldername" => foldername2
        }
    end

    # CatalystStandardTarget::makeTargetUniqueNameInteractively()
    def self.makeTargetUniqueNameInteractively()
        uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
        return {
            "uuid" => SecureRandom.uuid,
            "type" => "unique-name",
            "name" => uniquename
        }
    end

    # CatalystStandardTarget::makeTargetDirectoryMarkInteractively()
    def self.makeTargetDirectoryMarkInteractively()
        options = ["mark file already exists", "mark file should be created"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return nil if option.nil?
        if option == "mark file already exists" then
            mark = LucilleCore::askQuestionAnswerAsString("mark: ")
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "directory-mark",
                "mark" => mark
            }
        end
        if option == "mark file should be created" then
            mark = nil
            loop {
                targetFolderLocation = LucilleCore::askQuestionAnswerAsString("Location to the target folder: ")
                if !File.exists?(targetFolderLocation) then
                    puts "I can't see location '#{targetFolderLocation}'"
                    puts "Let's try that again..."
                    next
                end
                mark = SecureRandom.uuid
                markFilepath = "#{targetFolderLocation}/Nyx-Directory-Mark.txt"
                File.open(markFilepath, "w"){|f| f.write(mark) }
                break
            }
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "directory-mark",
                "mark" => mark
            }
        end
    end

    # CatalystStandardTarget::makeNewTargetInteractivelyOrNull()
    def self.makeNewTargetInteractivelyOrNull()
        types = ["line", "url", "file", "folder", "unique-name", "directory-mark"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            return CatalystStandardTarget::makeTargetLineInteractively()
        end
        if type == "url" then
            return CatalystStandardTarget::makeTargetUrlInteractively()
        end
        if type == "file" then
            return CatalystStandardTarget::makeTargetFileInteractivelyOrNull()
        end
        if type == "folder" then
            return CatalystStandardTarget::makeTargetFolderInteractivelyOrNull()
        end
        if type == "unique-name" then
            return CatalystStandardTarget::makeTargetUniqueNameInteractively()
        end
        if type == "directory-mark" then
            return CatalystStandardTarget::makeTargetDirectoryMarkInteractively()
        end
    end

    # CatalystStandardTarget::locationToFileOrFolderTarget(location)
    def self.locationToFileOrFolderTarget(location)
        raise "f8e3b314" if !File.exists?(location)
        if File.file?(location) then
            filepath1 = location
            filename1 = File.basename(filepath1)
            filename2 = "#{CatalystCommon::l22()}-#{filename1}"
            filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
            FileUtils.mv(filepath1, filepath2)
            CoreDataFile::copyFileToRepository(filepath2)
            return {
                "uuid"     => SecureRandom.uuid,
                "type"     => "file",
                "filename" => filename2
            }
        else
            folderpath1 = location
            foldername1 = File.basename(folderpath1)
            foldername2 = "#{CatalystCommon::l22()}-#{foldername1}"
            folderpath2 = "#{File.dirname(foldername1)}/#{foldername2}"
            FileUtils.mv(folderpath1, folderpath2)
            CoreDataDirectory::copyFolderToRepository(folderpath2)
            return {
                "uuid"       => SecureRandom.uuid,
                "type"       => "folder",
                "foldername" => foldername2
            }
        end
    end

    # --------------------------------------------------

    # CatalystStandardTarget::targetToString(target)
    def self.targetToString(target)
        if target["type"] == "line" then
            return target["line"]
        end
        if target["type"] == "file" then
            return "CoreData file: #{target["filename"]}"
        end
        if target["type"] == "url" then
            return target["url"]
        end
        if target["type"] == "folder" then
            return "CoreData folder: #{target["foldername"]}"
        end
        if target["type"] == "unique-name" then
            return "unique name: #{target["name"]}"
        end
        if target["type"] == "directory-mark" then
            return "directory mark: #{target["mark"]}"
        end
        raise "Catalyst Standard Target error 3c7968e4"
    end

    # CatalystStandardTarget::openTarget(target)
    def self.openTarget(target)
        if target["type"] == "line" then
            puts target["line"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if target["type"] == "file" then
            CoreDataFile::openOrCopyToDesktop(target["filename"])
            return
        end
        if target["type"] == "url" then
            system("open '#{target["url"]}'")
            return
        end
        if target["type"] == "folder" then
            CoreDataDirectory::openFolder(target["foldername"])
            return
        end
        if target["type"] == "unique-name" then
            uniquename = target["name"]
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
        if target["type"] == "directory-mark" then
            mark = target["mark"]
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
        raise "Catalyst Standard Target error 160050-490261"
    end

    # CatalystStandardTarget::fsckTarget(target)
    def self.fsckTarget(target)
        if target["uuid"].nil? then
            raise "target as no uuid"
        end
        if target["type"].nil? then
            puts target
            raise "target as no type"
        end
        if target["type"] == "line" then
            if target["line"].nil? then
                puts target
                raise "target as no line"
            end
        end
        if target["type"] == "file" then
            if target["filename"].nil? then
                puts target
                raise "target as no filename"
            end
            status = CoreDataFile::exists?(target["filename"])
            if !status then
                puts target
                raise "CoreDataFile cannot find this filename: #{target["filename"]}"
            end
        end
        if target["type"] == "url" then
        end
        if target["type"] == "folder" then
            if target["foldername"].nil? then
                puts target
                raise "target as no foldername"
            end
            status = CoreDataDirectory::exists?(target["foldername"])
            if !status then
                puts target
                raise "CoreDataFile cannot find this foldername: #{target["foldername"]}"
            end
        end
        if target["type"] == "unique-name" then
        end
        if target["type"] == "directory-mark" then
        end
    end

    # CatalystStandardTarget::targetDive(target)
    def self.targetDive(target)
        puts "-> target:"
        puts JSON.pretty_generate(target)
        puts CatalystStandardTarget::targetToString(target)
        LucilleCore::pressEnterToContinue()
    end

    # CatalystStandardTarget::targetsDive(targets)
    def self.targetsDive(targets)
        toStringLambda = lambda { |target| CatalystStandardTarget::targetToString(target) }
        target = LucilleCore::selectEntityFromListOfEntitiesOrNull("Choose target", targets, toStringLambda)
        return if target.nil?
        CatalystStandardTarget::targetDive(target)
    end
end
