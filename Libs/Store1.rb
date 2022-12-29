# encoding: UTF-8

# Store1 is a contents addressable store.

class Store1

    # Store1::repositoryFolderPath()
    def self.repositoryFolderPath()
        "#{Config::pathToDataCenter()}/Store1"
    end

    # Store1::put(datablob) # nhash
    def self.put(datablob) # nhash
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        filename = "#{nhash}.data"
        folderpath = "#{Store1::repositoryFolderPath()}/#{nhash[7, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkdir(folderpath)
        end
        filepath = "#{folderpath}/#{filename}"
        File.open(filepath, "w"){|f| f.write(datablob) }

        # -------------------------------------
        nhash_check = "SHA256-#{Digest::SHA256.hexdigest(Store1::getOrNull(nhash))}"
        if nhash_check != nhash then
            raise "(error: 43070006-dcaf-48b7-ac43-025ed2351336) something incredibly wrong just happened"
        end
        # -------------------------------------

        nhash
    end

    # Store1::getOrNull(nhash)
    def self.getOrNull(nhash)
        filename = "#{nhash}.data"
        folderpath = "#{Store1::repositoryFolderPath()}/#{nhash[7, 2]}"
        filepath = "#{folderpath}/#{filename}"
        return nil if !File.exists?(filepath)
        blob = IO.read(filepath)

        # -------------------------------------
        nhash_check = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        if nhash_check != nhash then
            raise "(error: 38cb55a1-c7d4-49cd-9e22-3d0673e51bf2) something incredibly wrong just happened"
        end
        # -------------------------------------

        blob
    end
end

class Store1Elizabeth

    def initialize()
    end

    def putBlob(datablob)
        Store1::put(datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Store1::getOrNull(nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 585b8f91-4369-4dd7-a134-f00d9e7f4391) could not find blob, nhash: #{nhash}"
        raise "(error: 987f8b3e-ff09-4b6a-9809-da6732b39be1, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: d97f7216-afeb-40bd-a37c-0d5966e6a0d0) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
