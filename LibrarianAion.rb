
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

class LibrarianAionDesk
    # LibrarianAionDesk::folderpathForQuark(quark)
    def self.folderpathForQuark(quark)
        folderpath = "#{CatalystCommon::catalystDataCenterFolderpath()}/Nyx-Desk/#{quark["uuid"]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
            namedhash = quark["namedhash"]
            LibrarianAionOperator::namedHashExportAtFolder(namedhash, folderpath)
        end
        folderpath
    end
end
