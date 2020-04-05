
# encoding: UTF-8
$BOB_AGENTS_IDENTITIES = []

class NSXAtlasReferenceUtils

    # NSXAtlasReferenceUtils::referenceToLocationOrNull(atlasReference)
    def self.referenceToLocationOrNull(atlasReference)
        filelocation = `atlas locate #{atlasReference}`.strip
        filelocation.size>0 ? filelocation : nil
    end

    # NSXAtlasReferenceUtils::referenceToFileContentsOrNull(atlasReference)
    def self.referenceToFileContentsOrNull(atlasReference)
        location = NSXAtlasReferenceUtils::referenceToLocationOrNull(atlasReference)
        return nil if location.nil?
        return nil if !File.exists?(location)
        IO.read(location)
    end

end
