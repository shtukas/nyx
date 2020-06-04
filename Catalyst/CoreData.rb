
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Quark.rb"

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
        folder1 = "#{CatalystCommon::binT1mel1neFolderpath()}/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{Time.new.strftime("%Y-%m-%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{LucilleCore::timeStringL22()}"
        FileUtils.mkdir(folder3)
        LucilleCore::copyFileSystemLocation(location, folder3)
    end
end

class CoreDataFile

    # CoreDataFile::filenameToFilepath(filename)
    def self.filenameToFilepath(filename)
        filepath1 = "#{CoreDataUtils::pathToCoreData()}/Files/#{filename}"
        filepath2 = "#{CoreDataUtils::pathToCoreData()}/Files2/2020-06/#{filename}"
        if !File.exists?(File.dirname(filepath2)) then
            FileUtils.mkdir(File.dirname(filepath2))
        end
        if File.exists?(filepath2) then
            return filepath2
        end
        if File.exists?(filepath1) then
            FileUtils.mv(filepath1, filepath2)
            return filepath2
        end
        filepath2
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

    # CoreDataFile::openAndOrCopyToDesktop(filename)
    def self.openAndOrCopyToDesktop(filename)
        if CoreDataFile::fileByFilenameIsSafelyOpenable(filename) then
            filepath = CoreDataFile::filenameToFilepath(filename)
            system("open '#{filepath}'")
        else
            filepath = CoreDataFile::filenameToFilepath(filename)
            FileUtils.cp(filepath, "/Users/pascal/Desktop/Quarks-Drop")
            puts "File copied to Quarks-Drop {#{File.basename(filepath)}}"
            LucilleCore::pressEnterToContinue()
        end
    end

    # CoreDataFile::makeNewTextFileInteractivelyReturnCoreDataFilename()
    def self.makeNewTextFileInteractivelyReturnCoreDataFilename()
        filename = "#{CatalystCommon::l22()}.txt"
        filepath = CoreDataFile::filenameToFilepath(filename)
        FileUtils.touch(filepath)
        system("open '#{filepath}'")
        LucilleCore::pressEnterToContinue()
        filename
    end
end

class CoreDataDirectory

    # CoreDataDirectory::foldernameToFolderpath(foldername)
    def self.foldernameToFolderpath(foldername)
        folderpath1 = "#{CoreDataUtils::pathToCoreData()}/Directories/#{foldername}"
        folderpath2 = "#{CoreDataUtils::pathToCoreData()}/Directories2/2020-06/#{foldername}"
        if !File.exists?(File.dirname(folderpath2)) then
            FileUtils.mkdir(File.dirname(folderpath2))
        end
        if File.exists?(folderpath2) then
            return folderpath2
        end
        if File.exists?(folderpath1) then
            FileUtils.mv(folderpath1, folderpath2)
            return folderpath2
        end
        folderpath2
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
