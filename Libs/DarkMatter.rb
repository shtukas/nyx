# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

class NegativeSpace

end

class DarkMatter

    # DarkMatter::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        fragment1 = nhash[7, 2]
        fragment2 = nhash[9, 2]
        folderpath = "#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkMatter/2023-06/#{fragment1}/#{fragment2}"
        filepath = "#{folderpath}/#{nhash}.data"
        return nil if !File.exist?(filepath)
        IO.read(filepath)
    end

    # DarkMatter::putBlob(datablob) # nhash
    def self.putBlob(datablob) # nhash
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        puts "DarkMatter put blob: nhash: #{nhash}".green
        fragment1 = nhash[7, 2]
        fragment2 = nhash[9, 2]
        folderpath = "#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkMatter/2023-06/#{fragment1}/#{fragment2}"
        if !File.exist?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(datablob) }
        nhash2 = "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
        if nhash2 != nhash then
            raise "DarkMatter put blob: check of the file failed (nhash: #{nhash})"
            exit
        end
        nhash
    end
end

class DarkMatterElizabeth

    def initialize()
    end

    def putBlob(datablob) # nhash
        DarkMatter::putBlob(datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        DarkMatter::getBlobOrNull(nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        raise "(error: 7e168c83-2720-4299-bdba-de5c3cca9c0a, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: c8b47339-03c3-484c-9207-c2106e88acb7) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
