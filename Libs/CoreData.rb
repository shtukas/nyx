
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
        CoreDataUtils::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = CoreDataUtils::getBlobOrNull(nhash)
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

class CoreDataUtils

    # CoreDataUtils::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/CoreData"
    end

    # CoreDataUtils::datablobsRoot()
    def self.datablobsRoot()
        "#{CoreDataUtils::path()}/DataBlobs2"
    end

    # CoreDataUtils::objectsRoot()
    def self.objectsRoot()
        "#{CoreDataUtils::path()}/Objects"
    end

    # CoreDataUtils::filepathToContentHash(filepath)
    def self.filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    # CoreDataUtils::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        folderpath = "#{CoreDataUtils::datablobsRoot()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # CoreDataUtils::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        folderpath = "#{CoreDataUtils::datablobsRoot()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        filepath = "#{folderpath}/#{nhash}.data"
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end

    # User Interface

    # CoreDataUtils::commitObject(object): String, Object UUID
    def self.commitObject(object)
        uuid = object["uuid"]
        trace = Digest::SHA256.hexdigest(uuid)
        folderpath = "#{CoreDataUtils::objectsRoot()}/#{trace[0, 2]}/#{trace[2, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{trace}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }
        nil
    end

    # CoreDataUtils::getObjectOrNull(uuid)
    def self.getObjectOrNull(uuid)
        trace = Digest::SHA256.hexdigest(uuid)
        folderpath = "#{CoreDataUtils::objectsRoot()}/#{trace[0, 2]}/#{trace[2, 2]}"
        filepath = "#{folderpath}/#{trace}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

end

class CoreData

    # CoreData::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = SecureRandom.uuid
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # CoreData::issueTextDataObjectUsingText(text)
    def self.issueTextDataObjectUsingText(text)
        coredataobject = {
            "uuid" => SecureRandom.uuid,
            "type" => "text",
            "text" => text
        }
        CoreDataUtils::commitObject(coredataobject)
        return coredataobject["uuid"]
    end

    # CoreData::issueUrlPointDataObjectUsingUrl(url)
    def self.issueUrlPointDataObjectUsingUrl(url)
        coredataobject = {
            "uuid" => SecureRandom.uuid,
            "type" => "url",
            "url"  => url
        }
        CoreDataUtils::commitObject(coredataobject)
        return coredataobject["uuid"]
    end

    # CoreData::issueAionPointDataObjectUsingLocation(location)
    def self.issueAionPointDataObjectUsingLocation(location)
        nhash = AionCore::commitLocationReturnHash(CoreDataElizabeth.new(), location)
        coredataobject = {
            "uuid"  => SecureRandom.uuid,
            "type"  => "aion-point",
            "nhash" => nhash
        }
        CoreDataUtils::commitObject(coredataobject)
        return coredataobject["uuid"]
    end

    # CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()
    def self.interactivelyCreateANewDataObjectReturnIdOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("axiom type", ["text", "url", "location"])
        return nil if type.nil?
        if type == "text" then
            text = CoreData::editTextSynchronously("")
            coredataobject = {
                "uuid" => SecureRandom.uuid,
                "type" => "text",
                "text" => text
            }
            CoreDataUtils::commitObject(coredataobject)
            return coredataobject["uuid"]
        end

        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            return CoreData::issueUrlPointDataObjectUsingUrl(url)
        end

        if type == "location" then
            locationNameOnDesktop = LucilleCore::askQuestionAnswerAsString("location of desktop (empty to abort): ")
            return nil if locationNameOnDesktop == ""
            location = "/Users/pascal/Desktop/#{locationNameOnDesktop}"
            return CoreData::issueAionPointDataObjectUsingLocation(location)
        end

        raise "[fd1be202-ce29-419b-8a9f-40b91a3beb65, type: #{type}]"
    end

    # CoreData::contentTypeOrNull(id: String)
    def self.contentTypeOrNull(id)
        return nil if id.nil?
        object = CoreDataUtils::getObjectOrNull(id)
        return nil if object.nil?
        object["type"]
    end

    # CoreData::fsck(uuid: String) : Boolean
    def self.fsck(uuid)
        return true if uuid.nil?
        object = CoreDataUtils::getObjectOrNull(uuid)
        return false if object.nil?
        if object["type"] == "text" then
            return true
        end
        if object["type"] == "url" then
            return true
        end
        if object["type"] == "aion-point" then
            nhash = object["nhash"]
            return AionFsck::structureCheckAionHash(CoreDataElizabeth.new(), nhash)
        end
        raise "4ecddee2-0d4c-4e26-ab41-c6da2fd91b4e: non standard variant for uuid: #{uuid}, #{object}"
    end

    # CoreData::accessWithOptionToEdit(uuid: String)
    def self.accessWithOptionToEdit(uuid)
        return if uuid.nil?
        object = CoreDataUtils::getObjectOrNull(uuid)
        if object.nil? then
            puts "Could not find data object for uuid #{uuid}"
            LucilleCore::pressEnterToContinue()
            return
        end
        if object["type"] == "text" then
            puts object["text"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if object["type"] == "url" then
            Utils::openUrlUsingSafari(object["url"])
            return
        end
        if object["type"] == "aion-point" then
            AionCore::exportHashAtFolder(CoreDataElizabeth.new(), object["nhash"], "/Users/pascal/Desktop")
            return
        end
        raise "(2201ddcd-cb33-4faf-9388-e4ebb6e7f28f, uuid: #{uuid})"
    end

end
