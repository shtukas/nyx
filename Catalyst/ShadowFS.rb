# require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/ShadowFS.rb"
=begin

The operator is an object that has meet the following signatures

    .commitBlob(blob: BinaryData) : Hash
    .filepathToHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean
    .shouldCommitFile(filepath) : Boolean
        # This is an addition relatively to AionCore, this function decides whether or not
        # the file should be commited as regular ( "aionType" : "file" ) or ( "aionType" : "shadow-file" )

ShadowFS::commitLocationReturnHash(operator, location)
ShadowFS::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)

ShadowFSFsck::structureCheckAionHash(operator, nhash)

=end

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'find'

# ------------------------------------------------------------------------

=begin

```
{
    "aionType" : "file"
    "name"     : String
    "size"     : Integer
    "hash"     : Hash
    "parts"    : Array[Hash] # Hashes of the binary blobs of the file
}

{
    "aionType" : "shadow-file"
    "name"     : String
}

{
    "aionType" : "directory"
    "name"     : String
    "items" : Array[Hash] # Hashes of serialised Aion objects
}

{
    "aionType" : "indefinite"
    "name"     : String
}
```
=end

class ShadowFS

    # ShadowFS::macOSIconFilename(): String
    def self.macOSIconFilename()
        "Icon\r"
    end

    # ShadowFS::macOSDSStoreFilename(): String
    def self.macOSDSStoreFilename()
        '.DS_Store'
    end

    # ShadowFS::getAionObjectByHash(operator, nhash)
    def self.getAionObjectByHash(operator, nhash)
        aionObject = JSON.parse(operator.readBlobErrorIfNotFound(nhash))
        aionObject
    end

    # ShadowFS::locationsNamesInsideFolder(folderpath): Array[String]
    def self.locationsNamesInsideFolder(folderpath)
        Dir.entries(folderpath)
            .reject{|filename| [".", ".."].include?(filename) }
            .reject{|filename|  [ShadowFS::macOSIconFilename(), ShadowFS::macOSDSStoreFilename()].include?(filename) }
            .sort
    end

    # ShadowFS::locationPathsInsideFolder(folderpath): Array[String]
    def self.locationPathsInsideFolder(folderpath)
        ShadowFS::locationsNamesInsideFolder(folderpath).map{|filename| "#{folderpath}/#{filename}" }
    end

    # ShadowFS::commitFileReturnPartsHashs(operator, filepath)
    def self.commitFileReturnPartsHashs(operator, filepath)
        raise "[ShadowFS error: 8338057a]" if !File.exists?(filepath)
        raise "[ShadowFS error: e216e1f3]" if !File.file?(filepath)
        hashes = []
        partSizeInBytes = 1024*1024 # 1 MegaBytes
        f = File.open(filepath)
        while ( blob = f.read(partSizeInBytes) ) do
            hashes << operator.commitBlob(blob)
        end
        f.close()
        hashes
    end

    # ShadowFS::commitFileReturnAionObject(operator, filepath): AionObject(aionType:file)
    def self.commitFileReturnAionObject(operator, filepath)
        if operator.shouldCommitFile(filepath) then
            {
                "aionType" => "file",
                "name"     => File.basename(filepath),
                "size"     => File.size(filepath),
                "hash"     => operator.filepathToHash(filepath),
                "parts"    => ShadowFS::commitFileReturnPartsHashs(operator, filepath)
            }
        else
            {
                "aionType" => "shadow-file",
                "name"     => File.basename(filepath)
            }
        end
    end

    # ShadowFS::commitDirectoryReturnAionObject(operator, folderpath)
    def self.commitDirectoryReturnAionObject(operator, folderpath)
        raise "[ShadowFS error: 8aa94546]" if !File.exists?(folderpath)
        raise "[ShadowFS error: ff9603a2]" if !File.directory?(folderpath)
        {
            "aionType" => "directory",
            "name"     => File.basename(folderpath),
            "items"    => ShadowFS::locationPathsInsideFolder(folderpath).map{|l| ShadowFS::commitLocationReturnHash(operator, l) }
        }
    end

    # ShadowFS::commitLocationReturnAionObject(operator, location)
    def self.commitLocationReturnAionObject(operator, location)
        if File.symlink?(location) then
            return {
                "aionType" => "indefinite",
                "name"     => File.basename(location)
            }
        end
        File.file?(location) ? ShadowFS::commitFileReturnAionObject(operator, location) : ShadowFS::commitDirectoryReturnAionObject(operator, location)
    end

    # ShadowFS::commitLocationReturnHash(operator, location)
    def self.commitLocationReturnHash(operator, location)
        aionObject = ShadowFS::commitLocationReturnAionObject(operator, location)
        blob = JSON.generate(aionObject)
        operator.commitBlob(blob)
    end

    # ShadowFS::exportAionObjectAtFolder(operator, aionObject, targetReconstructionFolderpath)
    def self.exportAionObjectAtFolder(operator, aionObject, targetReconstructionFolderpath)
        if aionObject["aionType"]=="file" then
            targetFilepath = "#{targetReconstructionFolderpath}/#{aionObject["name"]}"
            File.open(targetFilepath, "w"){|f|  
                aionObject["parts"].each{|nhash|
                    f.write(operator.readBlobErrorIfNotFound(nhash))
                }
            }
        end
        if aionObject["aionType"]=="directory" then
            targetSubFolderpath = "#{targetReconstructionFolderpath}/#{aionObject["name"]}"
            if !File.exists?(targetSubFolderpath) then
                FileUtils.mkpath(targetSubFolderpath)
            end
            aionObject["items"].each{|nhash|
                ShadowFS::exportHashAtFolder(operator, nhash, targetSubFolderpath)
            }
        end
        if aionObject["aionType"]=="indefinite" then
            targetFilepath = "#{targetReconstructionFolderpath}/#{aionObject["name"]}"
            FileUtils.touch(targetFilepath)
        end
    end

    # ShadowFS::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)
    def self.exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)
        aionObject = ShadowFS::getAionObjectByHash(operator, nhash)
        ShadowFS::exportAionObjectAtFolder(operator, aionObject, targetReconstructionFolderpath)
    end
end

class ShadowFSFsck

    # ShadowFSFsck::aionObjectCheck(operator, aionObject)
    def self.aionObjectCheck(operator, aionObject)
        if aionObject["aionType"] == "file" then
            return aionObject["parts"].all?{|nhash| operator.datablobCheck(nhash) }
        end
        if aionObject["aionType"] == "shadow-file" then
            return true
        end
        if aionObject["aionType"] == "directory" then
            return aionObject["items"].all?{|namedAionHash| ShadowFSFsck::structureCheckAionHash(operator, namedAionHash) }
        end
        if aionObject["aionType"] == "indefinite" then
            return true
        end
    end

    # ShadowFSFsck::structureCheckAionHash(operator, nhash)
    def self.structureCheckAionHash(operator, nhash)
        aionObject = nil
        begin
            aionObject = ShadowFS::getAionObjectByHash(operator, nhash)
        rescue Exception => e
            return false
        end
        ShadowFSFsck::aionObjectCheck(operator, aionObject)
    end
end

class ShadowFSOperator

    def initialize()

    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        KeyValueStore::set(nil, "SHA256-#{Digest::SHA256.hexdigest(blob)}", blob)
        nhash
    end

    def filepathToHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = KeyValueStore::getOrNull(nil, nhash)
        raise "[ShadowFSOperator error: fc1dd1aa]" if blob.nil?
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

    def shouldCommitFile(filepath)
        false
    end
end
