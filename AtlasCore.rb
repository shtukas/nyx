
# encoding: utf-8

class AtlasCore

    # AtlasCore::locationIsUnisonTmp(location)
    def self.locationIsUnisonTmp(location)
        mark = ".unison.tmp"
        location[-mark.size, mark.size] == mark
    end

    # AtlasCore::allPossibleStandardScanRoots()
    def self.allPossibleStandardScanRoots()
        roots = []
        roots << "/Users/pascal/Galaxy"
        roots << "/Volumes/EnergyGrid/Data/Pascal/Galaxy"
        roots
    end

    # AtlasCore::locationIsTarget(location, uniquestring)
    def self.locationIsTarget(location, uniquestring)
        return false if AtlasCore::locationIsUnisonTmp(location)
        File.basename(location).include?(uniquestring)
    end

    # AtlasCore::locationEnumerator(roots)
    def self.locationEnumerator(roots)
        Enumerator.new do |filepaths|
            roots.each{|root|
                if File.exists?(root) then
                    begin
                        Find.find(root) do |path|
                            filepaths << path
                        end
                    rescue
                    end
                end
            }
        end
    end

    # AtlasCore::uniqueStringToLocationOrNullUseTheForce(uniquestring)
    def self.uniqueStringToLocationOrNullUseTheForce(uniquestring)
        AtlasCore::locationEnumerator(AtlasCore::allPossibleStandardScanRoots())
            .each{|location|
                if AtlasCore::locationIsTarget(location, uniquestring) then
                    KeyToStringOnDiskStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}", location)
                    return location
                end
            }
        nil
    end

    # AtlasCore::uniqueStringToLocationOrNull(uniquestring)
    def self.uniqueStringToLocationOrNull(uniquestring)
        maybefilepath = KeyToStringOnDiskStore::getOrNull(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}")
        if maybefilepath and File.exists?(maybefilepath) and AtlasCore::locationIsTarget(maybefilepath, uniquestring) then
            return maybefilepath
        end
        maybefilepath = AtlasCore::uniqueStringToLocationOrNullUseTheForce(uniquestring)
        if maybefilepath then
            KeyToStringOnDiskStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}", maybefilepath)
        end
        maybefilepath
    end

end

