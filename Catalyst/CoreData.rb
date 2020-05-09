
# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CoreData.rb"
=begin

    CoreDataFile::copyFileToRepository(filepath)
    CoreDataFile::filenameToFilepath(filename)
    CoreDataFile::exists?(filename)
    CoreDataFile::openOrCopyToDesktop(filename)

    CoreDataDirectory::copyFolderToRepository(folderpath)
    CoreDataDirectory::foldernameToFolderpath(foldername)
    CoreDataDirectory::exists?(foldername)
    CoreDataDirectory::openFolder(foldername)


=end


# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

# -----------------------------------------------------------------

=begin

### Introduction

CoreData manages Aether data points with a specific specs covering the
needs of Lucille points (and OpenCycle and In Flight Control System) as well as 
Waves and Nyx

CoreData also manages files and folders, this gives flexibility and also allows 
backwards compatibility with Nyx.

### Estate

We have the main data repository: '/Users/pascal/Galaxy/DataBank/Catalyst/Catalyst/CoreData'
Which has the folders
    - AetherPoints
    - Directories
    - Files

We do not have a sub-folders structure for the moment

It is expected that
    - the basename of directories is their unique identifier.
    - files are fully named
    - Aether points are named after their identifier (the value of the uuid key) with the suffix '.aetherpoint'

### CoreData functions generalities

The functions focus on three parts
    - Manipulation of files
    - Manipulation of folders
    - Manipulation of Aether data (kvstores, aion references and aion data)

=end

class CoreDataInternalUtils
    # CoreDataInternalUtils::copyLocationToCatalystBin(location)
    def self.copyLocationToCatalystBin(location)
        return if location.nil?
        return if !File.exists?(location)
        folder1 = "#{CatalystCommon::binTimelineFolderpath()}/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{Time.new.strftime("%Y-%m-%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{LucilleCore::timeStringL22()}"
        FileUtils.mkdir(folder3)
        LucilleCore::copyFileSystemLocation(location, folder3)
    end
    # CoreDataInternalUtils::pathToCoreData()
    def self.pathToCoreData()
        "/Users/pascal/Galaxy/DataBank/Catalyst/CoreData"
    end
end

class CoreDataFile

    # CoreDataFile::filenameToFilepath(filename)
    def self.filenameToFilepath(filename)
        "#{CoreDataInternalUtils::pathToCoreData()}/Files/#{filename}"
    end

    # CoreDataFile::copyFileToRepository(filepath)
    def self.copyFileToRepository(filepath)
        raise "CoreData error 3afc90f9e9bb" if !File.exists?(filepath)
        raise "CoreData error 860270278181" if File.basename(filepath).include?("'")
        filepath2 = "#{CoreDataInternalUtils::pathToCoreData()}/Files/#{File.basename(filepath)}"
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
        safelyOpeneableExtensions = [".txt", ".jpg", ".jpeg", ".png", ".eml", ".webloc"]
        safelyOpeneableExtensions.any?{|extension| filename[-extension.size, extension.size] == extension }
    end

    # CoreDataFile::openOrCopyToDesktop(filename)
    def self.openOrCopyToDesktop(filename)
        if CoreDataFile::fileByFilenameIsSafelyOpenable(filename) then
            filepath = CoreDataFile::filenameToFilepath(filename)
            system("open '#{filepath}'")
        else
            filepath = CoreDataFile::filenameToFilepath(filename)
            FileUtils.cp(filepath, "/Users/pascal/Desktop/")
        end
    end
end

class CoreDataDirectory

    # CoreDataDirectory::foldernameToFolderpath(foldername)
    def self.foldernameToFolderpath(foldername)
        "#{CoreDataInternalUtils::pathToCoreData()}/Directories/#{foldername}"
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
        folderpath2 = "#{CoreDataInternalUtils::pathToCoreData()}/Directories/#{File.basename(folderpath)}"
        raise "CoreData error d4d6143b3d7d" if File.exists?(folderpath2)
        LucilleCore::copyFileSystemLocation(folderpath, "#{CoreDataInternalUtils::pathToCoreData()}/Directories")
    end

    # CoreDataDirectory::openFolder(foldername)
    def self.openFolder(foldername)
        folderpath = CoreDataDirectory::foldernameToFolderpath(foldername)
        return if !File.exists?(folderpath)
        system("open '#{folderpath}'")
    end
end

