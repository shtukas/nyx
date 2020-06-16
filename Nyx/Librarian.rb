
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Librarian.rb"

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

class LibrarianUtils
    # LibrarianUtils::pathToLibrarian()
    def self.pathToLibrarian()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Librarian"
    end

    # LibrarianUtils::copyLocationToCatalystBin(location)
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

class LibrarianFile

    # LibrarianFile::filenameToRepositoryFilepath(filename)
    def self.filenameToRepositoryFilepath(filename)
        "#{LibrarianUtils::pathToLibrarian()}/Files/#{filename}"
    end

    # LibrarianFile::copyFileToRepository(filepath1)
    def self.copyFileToRepository(filepath1)
        raise "Librarian Error 655ACBBD" if !File.exists?(filepath1)
        raise "Librarian Error 7755B7DB" if File.basename(filepath1).include?("'") 
                # We could make the correction here but we want the clients (which manage the file) 
                # to make the renaming themselves if needed
        filepath2 = LibrarianFile::filenameToRepositoryFilepath(File.basename(filepath1))
        raise "Librarian Error 909222C9" if File.exists?(filepath2)
        FileUtils.cp(filepath1, filepath2)
    end

    # LibrarianFile::exists?(filename)
    def self.exists?(filename)
        filepath = LibrarianFile::filenameToRepositoryFilepath(filename)
        File.exists?(filepath)
    end

    # LibrarianFile::fileByFilenameIsSafelyOpenable(filename)
    def self.fileByFilenameIsSafelyOpenable(filename)
        safelyOpeneableExtensions = [".txt", ".jpg", ".jpeg", ".png", ".eml", ".webloc", ".pdf"]
        safelyOpeneableExtensions.any?{|extension| filename.downcase[-extension.size, extension.size] == extension }
    end

    # LibrarianFile::accessFile(filename)
    def self.accessFile(filename)
        if LibrarianFile::fileByFilenameIsSafelyOpenable(filename) then
            filepath = LibrarianFile::filenameToRepositoryFilepath(filename)
            system("open '#{filepath}'")
            if LucilleCore::askQuestionAnswerAsBoolean("Duplicate to Desktop ? ", false) then
                FileUtils.cp(filepath, "/Users/pascal/Desktop")
                puts "File copied to Desktop {#{File.basename(filepath)}}"
            end
        else
            filepath = LibrarianFile::filenameToRepositoryFilepath(filename)
            FileUtils.cp(filepath, "/Users/pascal/Desktop")
            puts "File copied to Desktop {#{File.basename(filepath)}}"
        end
    end

    # LibrarianFile::makeNewTextFileInteractivelyReturnLibrarianFilename()
    def self.makeNewTextFileInteractivelyReturnLibrarianFilename()
        filename = "#{CatalystCommon::l22()}.txt"
        filepath = LibrarianFile::filenameToRepositoryFilepath(filename)
        FileUtils.touch(filepath)
        system("open '#{filepath}'")
        LucilleCore::pressEnterToContinue()
        filename
    end

    # LibrarianFile::textToFilename(text)
    def self.textToFilename(text)
        filename = "#{CatalystCommon::l22()}.txt"
        filepath = LibrarianFile::filenameToRepositoryFilepath(filename)
        File.open(filepath, "w"){|f| f.puts(text) }
        filename
    end
end

class LibrarianDirectory

    # LibrarianDirectory::foldernameToFolderpath(foldername)
    def self.foldernameToFolderpath(foldername)
        "#{LibrarianUtils::pathToLibrarian()}/Directories/#{foldername}"
    end

    # LibrarianDirectory::exists?(foldername)
    def self.exists?(foldername)
        folderpath = LibrarianDirectory::foldernameToFolderpath(foldername)
        File.exists?(folderpath)
    end

    # LibrarianDirectory::copyDirectoryToRepository(folderpath1)
    def self.copyDirectoryToRepository(folderpath1)
        raise "Librarian Error 9F5F3754" if !File.exists?(folderpath1)
        raise "Librarian Error D6D2099B" if File.basename(folderpath1).include?("'")
                # We could make the correction here but we want the clients (which manage the directory) 
                # to make the renaming themselves if needed
        folderpath2 = LibrarianDirectory::foldernameToFolderpath(File.basename(folderpath1))
        raise "Librarian Error 58A61FB9" if File.exists?(folderpath2)
        LucilleCore::copyFileSystemLocation(folderpath1, folderpath2)
    end

    # LibrarianDirectory::openFolder(foldername)
    def self.openFolder(foldername)
        folderpath = LibrarianDirectory::foldernameToFolderpath(foldername)
        return if !File.exists?(folderpath)
        system("open '#{folderpath}'")
    end
end
