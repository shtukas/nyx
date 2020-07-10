
# encoding: UTF-8

# require_relative "LibrarianAion.rb"

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

require_relative "AionCore.rb"
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
        blob = NyxBlobs::getBlobOrNull(nhash)
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

class LibrarianAionOperator

    # LibrarianAionOperator::locationToNamedHash(location)
    def self.locationToNamedHash(location)
        AionCore::commitLocationReturnHash(LibrarianAionElizabeth.new(), location)
    end

    # LibrarianAionOperator::namedHashExportAtFolder(namedHash, folderpath)
    def self.namedHashExportAtFolder(namedHash, folderpath)
        AionCore::exportHashAtFolder(LibrarianAionElizabeth.new(), namedHash, folderpath)
    end
end

class LibrarianDeskOperator

    # LibrarianDeskOperator::deskFolderpathForQuark(quark)
    def self.deskFolderpathForQuark(quark)
        "#{RealEstate::getDeskFolderpath()}/#{quark["uuid"]}"
    end

    # LibrarianDeskOperator::deskFolderpathForQuarkCreateIfNotExists(quark)
    def self.deskFolderpathForQuarkCreateIfNotExists(quark)
        deskFolderPathForQuark = LibrarianDeskOperator::deskFolderpathForQuark(quark)
        if !File.exists?(deskFolderPathForQuark) then
            FileUtils.mkpath(deskFolderPathForQuark)
            namedhash = quark["namedhash"]
            LibrarianAionOperator::namedHashExportAtFolder(namedhash, deskFolderPathForQuark)
            # If the deskFolderPathForQuark folder contains just one folder named after the quark itself
            # Then this means that we are exporting a previously imported deskFolderPathForQuark.
            # In such a case we are going to remove the extra folder by moving thigs up...
            if File.exists?("#{deskFolderPathForQuark}/#{quark["uuid"]}") then
                FileUtils.mv("#{deskFolderPathForQuark}/#{quark["uuid"]}", "#{deskFolderPathForQuark}/#{quark["uuid"]}-lifting")
                FileUtils.mv("#{deskFolderPathForQuark}/#{quark["uuid"]}-lifting", RealEstate::getDeskFolderpath())
                LucilleCore::removeFileSystemLocation(deskFolderPathForQuark)
                FileUtils.mv("#{deskFolderPathForQuark}-lifting", deskFolderPathForQuark)
            end
        end
        deskFolderPathForQuark
    end

    # LibrarianDeskOperator::commitDeskChangesToPrimaryRepository()
    def self.commitDeskChangesToPrimaryRepository()
        Quarks::quarks()
            .each{|quark|
                next if quark["type"] != "aion-point"
                deskFolderPathForQuark = LibrarianDeskOperator::deskFolderpathForQuark(quark)
                next if !File.exists?(deskFolderPathForQuark)
                namedhash = LibrarianAionOperator::locationToNamedHash(deskFolderPathForQuark)
                next if namedhash == quark["namedhash"]
                quark["namedhash"] = namedhash
                puts JSON.pretty_generate(quark)
                Quarks::commitQuarkToDisk(quark)
                LucilleCore::removeFileSystemLocation(deskFolderPathForQuark)
            }
    end
end
