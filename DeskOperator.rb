
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

require_relative "Miscellaneous.rb"
require_relative "NyxBlobs.rb"

# -----------------------------------------------------------------

class DeskOperator

    # DeskOperator::deskFolderpathForSpin(spin)
    def self.deskFolderpathForSpin(spin)
        "#{EstateServices::getDeskFolderpath()}/#{spin["targetuuid"]}"
    end

    # DeskOperator::deskFolderpathForSpinCreateIfNotExists(spin)
    def self.deskFolderpathForSpinCreateIfNotExists(spin)
        desk_folderpath_for_spin = DeskOperator::deskFolderpathForSpin(spin)
        if !File.exists?(desk_folderpath_for_spin) then
            FileUtils.mkpath(desk_folderpath_for_spin)
            namedhash = spin["namedhash"]
            LibrarianOperator::namedHashExportAtFolder(namedhash, desk_folderpath_for_spin)
            # If the desk_folderpath_for_spin folder contains just one folder named after the spin itself
            # Then this means that we are exporting a previously imported desk_folderpath_for_spin.
            # In such a case we are going to remove the extra folder by moving thigs up...
            if File.exists?("#{desk_folderpath_for_spin}/#{spin["targetuuid"]}") then
                FileUtils.mv("#{desk_folderpath_for_spin}/#{spin["targetuuid"]}", "#{desk_folderpath_for_spin}/#{spin["targetuuid"]}-lifting")
                FileUtils.mv("#{desk_folderpath_for_spin}/#{spin["targetuuid"]}-lifting", EstateServices::getDeskFolderpath())
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_spin)
                FileUtils.mv("#{desk_folderpath_for_spin}-lifting", desk_folderpath_for_spin)
            end
        end
        desk_folderpath_for_spin
    end

    # DeskOperator::commitDeskChangesToPrimaryRepository()
    def self.commitDeskChangesToPrimaryRepository()
        Spins::spins()
            .each{|spin|
                next if spin["type"] != "aion-point"
                desk_folderpath_for_spin = DeskOperator::deskFolderpathForSpin(spin)
                next if !File.exists?(desk_folderpath_for_spin)
                namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(desk_folderpath_for_spin)
                if namedhash == spin["namedhash"] then
                    LucilleCore::removeFileSystemLocation(desk_folderpath_for_spin)
                    next
                end
                # We issue a new spin for the same target
                spin = Spins::issueAionPoint(spin["targetuuid"], namedhash)
                puts JSON.pretty_generate(spin)
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_spin)
            }
    end
end
