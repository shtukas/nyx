# encoding: UTF-8

class DataStore4

    # DataStore4::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        filename = nhash
        fragment = "#{nhash[7, 2]}/#{nhash[9, 2]}"
        filepath = "/Users/pascal/Galaxy/DataBank/Stargate-DataCenter/DataStore4/#{fragment}/#{filename}"
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end

    # DataStore4::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filename = nhash
        fragment = "#{nhash[7, 2]}/#{nhash[9, 2]}"
        filepath = "/Users/pascal/Galaxy/DataBank/Stargate-DataCenter/DataStore4/#{fragment}/#{filename}"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end
end

class Elizabeth4

    def initialize()

    end

    def putBlob(datablob)
        DataStore4::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        DataStore4::getBlobOrNull(nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        puts "(error: 59674f1a-d746-4544-951e-f2b3fa73b121) could not find blob, nhash: #{nhash}"
        raise "(error: 133b9867-5d6d-429c-88c2-e1b87081489b, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: e3981133-9909-4765-9f6b-b76324af0ae8) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
