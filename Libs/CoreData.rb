
# encoding: UTF-8


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
        KeyValueStore::set(nil, nhash, blob)
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

class CoreDataElizabeth

    def initialize()

    end

    def commitBlob(blob)
        CoreData::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = CoreData::getBlobOrNull(nhash)
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

=begin

CoreData objects

{
    "uuid"  : String
    "type"  : "text"
    "text"  : String, Text
}

{
    "uuid"  : String
    "type"  : "url"
    "url"   : String, URL
}

{
    "uuid"  : String
    "type"  : "aion-point"
    "nhash" : String, Hash
}

=end

class CoreData

    # CoreData::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/CoreData"
    end

    # CoreData::datablobsRoot()
    def self.datablobsRoot()
        "#{CoreData::path()}/DataBlobs2"
    end

    # CoreData::objectsRoot()
    def self.objectsRoot()
        "#{CoreData::path()}/Objects"
    end

    # CoreData::filepathToContentHash(filepath)
    def self.filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    # CoreData::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        folderpath = "#{CoreData::datablobsRoot()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # CoreData::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        folderpath = "#{CoreData::datablobsRoot()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        filepath = "#{folderpath}/#{nhash}.data"
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end

    # User Interface

    # CoreData::commitObject(object)
    def self.commitObject(object)
        trace = Digest::SHA256.hexdigest(object["uuid"])
        folderpath = "#{CoreData::objectsRoot()}/#{trace[0, 2]}/#{trace[2, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{trace}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }
        trace
    end

    # CoreData::getObjectOrNull(trace)
    def self.getObjectOrNull(trace)
        folderpath = "#{CoreData::objectsRoot()}/#{trace[0, 2]}/#{trace[2, 2]}"
        filepath = "#{folderpath}/#{trace}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

end