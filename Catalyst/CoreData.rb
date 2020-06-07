
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

    # CoreDataUtils::getSubfoldersMonthsNotIncludingThisMonth(folderpath)
    def self.getSubfoldersMonthsNotIncludingThisMonth(folderpath)
        months = Dir.entries(folderpath)
                    .select{|filename| filename[0, 1] != '.' }
        months - [ Time.new.strftime("%Y-%m") ]
    end
end

class CoreDataFile



    # CoreDataFile::filenameToRepositoryFilepath(filename)
    def self.filenameToRepositoryFilepath(filename)

        thisMonthFolderPath = "#{CoreDataUtils::pathToCoreData()}/Files2/#{Time.new.strftime("%Y-%m")}"

        if !File.exists?(thisMonthFolderPath) then
            FileUtils.mkdir(thisMonthFolderPath)
        end

        filepath1 = "#{thisMonthFolderPath}/#{filename}"

        return filepath1 if File.exists?(filepath1)

        filepath2 = CoreDataUtils::getSubfoldersMonthsNotIncludingThisMonth("#{CoreDataUtils::pathToCoreData()}/Files2")
                        .map{|month| "#{CoreDataUtils::pathToCoreData()}/Files2/#{month}/#{filename}" }
                        .select{|fpath| File.exists?(fpath) }
                        .first

        if filepath2 then
            FileUtils.mv(filepath2, filepath1)
            return filepath1
        end

        filepath1
    end

    # CoreDataFile::copyFileToRepository(filepath1)
    def self.copyFileToRepository(filepath1)
        raise "CoreData Error 655ACBBD" if !File.exists?(filepath1)
        raise "CoreData Error 7755B7DB" if File.basename(filepath1).include?("'") 
                # We could make the correction here but we want the clients (which manage the file) 
                # to make the renaming themselves if needed
        filepath2 = CoreDataFile::filenameToRepositoryFilepath(File.basename(filepath1))
        raise "CoreData Error 909222C9" if File.exists?(filepath2)
        FileUtils.cp(filepath1, filepath2)
    end

    # CoreDataFile::exists?(filename)
    def self.exists?(filename)
        filepath = CoreDataFile::filenameToRepositoryFilepath(filename)
        File.exists?(filepath)
    end

    # CoreDataFile::fileByFilenameIsSafelyOpenable(filename)
    def self.fileByFilenameIsSafelyOpenable(filename)
        safelyOpeneableExtensions = [".txt", ".jpg", ".jpeg", ".png", ".eml", ".webloc", ".pdf"]
        safelyOpeneableExtensions.any?{|extension| filename.downcase[-extension.size, extension.size] == extension }
    end

    # CoreDataFile::accessFile(filename)
    def self.accessFile(filename)
        if CoreDataFile::fileByFilenameIsSafelyOpenable(filename) then
            filepath = CoreDataFile::filenameToRepositoryFilepath(filename)
            system("open '#{filepath}'")
            if LucilleCore::askQuestionAnswerAsBoolean("Duplicate to Desktop ? ", false) then
                FileUtils.cp(filepath, "/Users/pascal/Desktop")
                puts "File copied to Desktop {#{File.basename(filepath)}}"
                LucilleCore::pressEnterToContinue()
            end
        else
            filepath = CoreDataFile::filenameToRepositoryFilepath(filename)
            FileUtils.cp(filepath, "/Users/pascal/Desktop")
            puts "File copied to Desktop {#{File.basename(filepath)}}"
            LucilleCore::pressEnterToContinue()
        end
    end

    # CoreDataFile::makeNewTextFileInteractivelyReturnCoreDataFilename()
    def self.makeNewTextFileInteractivelyReturnCoreDataFilename()
        filename = "#{CatalystCommon::l22()}.txt"
        filepath = CoreDataFile::filenameToRepositoryFilepath(filename)
        FileUtils.touch(filepath)
        system("open '#{filepath}'")
        LucilleCore::pressEnterToContinue()
        filename
    end

    # CoreDataFile::textToFilename(text)
    def self.textToFilename(text)
        filename = "#{CatalystCommon::l22()}.txt"
        filepath = CoreDataFile::filenameToRepositoryFilepath(filename)
        File.open(filepath, "w"){|f| f.puts(text) }
        filename
    end
end

class CoreDataDirectory

    # CoreDataDirectory::foldernameToFolderpath(foldername)
    def self.foldernameToFolderpath(foldername)

        thisMonthFolderPath = "#{CoreDataUtils::pathToCoreData()}/Directories2/#{Time.new.strftime("%Y-%m")}"

        if !File.exists?(thisMonthFolderPath) then
            FileUtils.mkdir(thisMonthFolderPath)
        end

        folderpath1 = "#{thisMonthFolderPath}/#{foldername}"

        return folderpath1 if File.exists?(folderpath1)

        folderpath2 = CoreDataUtils::getSubfoldersMonthsNotIncludingThisMonth("#{CoreDataUtils::pathToCoreData()}/Directories2")
                        .map{|month| "#{CoreDataUtils::pathToCoreData()}/Directories2/#{month}/#{foldername}" }
                        .select{|fpath| File.exists?(fpath) }
                        .first

        if folderpath2 then
            FileUtils.mv(folderpath2, folderpath1)
            return folderpath1
        end

        folderpath1
    end

    # CoreDataDirectory::exists?(foldername)
    def self.exists?(foldername)
        folderpath = CoreDataDirectory::foldernameToFolderpath(foldername)
        File.exists?(folderpath)
    end

    # CoreDataDirectory::copyDirectoryToRepository(folderpath1)
    def self.copyDirectoryToRepository(folderpath1)
        raise "CoreData Error 9F5F3754" if !File.exists?(folderpath1)
        raise "CoreData Error D6D2099B" if File.basename(folderpath1).include?("'")
                # We could make the correction here but we want the clients (which manage the directory) 
                # to make the renaming themselves if needed
        folderpath2 = CoreDataDirectory::foldernameToFolderpath(File.basename(folderpath1))
        raise "CoreData Error 58A61FB9" if File.exists?(folderpath2)
        LucilleCore::copyFileSystemLocation(folderpath1, folderpath2)
    end

    # CoreDataDirectory::openFolder(foldername)
    def self.openFolder(foldername)
        folderpath = CoreDataDirectory::foldernameToFolderpath(foldername)
        return if !File.exists?(folderpath)
        system("open '#{folderpath}'")
    end
end
