
# encoding: UTF-8

# require_relative "Librarian.rb"

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

# require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/AionCore.rb"
=begin

The operator is an object that has meet the following signatures

    .commitBlob(blob: BinaryData) : Hash
    .filepathToContentHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        KeyValueStore::set(nil, "SHA256-#{Digest::SHA256.hexdigest(blob)}", blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = KeyValueStore::getOrNull(nil, nhash)
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end

end

AionCore::commitLocationReturnHash(operator, location)
AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)

AionFsck::structureCheckAionHash(operator, nhash)

=end

require_relative "Common.rb"
require_relative "NyxBlobs.rb"

# -----------------------------------------------------------------

class LibrarianUtils
    # LibrarianUtils::pathToLibrarian()
    def self.pathToLibrarian()
        "#{CatalystCommon::catalystDataCenterFolderpath()}/Librarian"
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
        if !File.exists?(folderpath) then
            puts "Folder '#{foldername}'. Could not be found."
            LucilleCore::pressEnterToContinue()
        end
        system("open '#{folderpath}'")
    end
end

=begin

LibrarianAionElizabeth is the class that explain to 
Aion how to compute hashes and where to store and 
retrive the blobs to and from.

=end

class LibrarianAionElizabeth

    def initialize()

    end

    def commitBlob(blob)
        NyxBlobs::put(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = NyxBlobs::getBlobOrNull(namedhash)
        raise "[LibrarianAionElizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end

end

class LibrarianAion

    # LibrarianAion::locationToNamedHash(location)
    def self.locationToNamedHash(location)
        AionCore::commitLocationReturnHash(LibrarianAionElizabeth.new(), location)
    end

    # LibrarianAion::namedHashExportAtFolder(namedHash, folderpath)
    def self.namedHashExportAtFolder(namedHash, folderpath)
        AionCore::exportHashAtFolder(LibrarianAionElizabeth.new(), folderpath)
    end
end
