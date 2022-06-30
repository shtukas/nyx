
# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'
# Digest::SHA256.file(myFile).hexdigest

=begin

class Elizabeth

    def initialize()

    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        XCache::set(nhash, blob)
        nhash
    end

    def getBlobOrNull(nhash)
        XCache::getOrNull(nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = XCache::getOrNull(nhash)
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

=end

class CompositeElizabeth

    def initialize(primaryElizabeth, secondaryElizabeths)
        @primaryElizabeth = primaryElizabeth
        @secondaryElizabeths = secondaryElizabeths
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def putBlob(blob)
        @primaryElizabeth.putBlob(blob)
    end

    def getBlobOrNull(nhash)
        blob = @primaryElizabeth.getBlobOrNull(nhash)
        if blob then
            return blob
        end

        @secondaryElizabeths.each{|elizabeth|
            blob = elizabeth.getBlobOrNull(nhash)
            if blob then
                @primaryElizabeth.putBlob(blob)
                return blob
            end
        }

        nil
    end

    def readBlobErrorIfNotFound(nhash)

        begin
            blob = @primaryElizabeth.readBlobErrorIfNotFound(nhash)
            return blob
        rescue
        end

        @secondaryElizabeths.each{|elizabeth|
            begin
                blob = elizabeth.readBlobErrorIfNotFound(nhash)
                @primaryElizabeth.putBlob(blob)
                return blob
            rescue
            end
        }
        
        raise "(error: b8c63d84-e0ba-4bd7-97c9-68b23d1f26aa, composite elizabeth could not find blob, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 6c838caa-2b40-4c5b-b75a-787ce9c05f15) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
