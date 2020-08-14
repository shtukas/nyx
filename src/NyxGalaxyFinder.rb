
# encoding: utf-8

class NyxGalaxyFinder

    # NyxGalaxyFinder::locationIsUnisonTmp(location)
    def self.locationIsUnisonTmp(location)
        mark = ".unison.tmp"
        location[-mark.size, mark.size] == mark
    end

    # NyxGalaxyFinder::allPossibleStandardScanRoots()
    def self.allPossibleStandardScanRoots()
        roots = []
        roots << "/Users/pascal/Galaxy"
        roots
    end

    # NyxGalaxyFinder::locationIsTarget(location, uniquestring)
    def self.locationIsTarget(location, uniquestring)
        return false if NyxGalaxyFinder::locationIsUnisonTmp(location)
        File.basename(location).include?(uniquestring)
    end

    # NyxGalaxyFinder::locationEnumerator(roots)
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

    # NyxGalaxyFinder::uniqueStringToLocationOrNullUseTheForce(uniquestring)
    def self.uniqueStringToLocationOrNullUseTheForce(uniquestring)
        NyxGalaxyFinder::locationEnumerator(NyxGalaxyFinder::allPossibleStandardScanRoots())
            .each{|location|
                if !NyxGalaxyFinder::locationIsUnisonTmp(location) and File.basename(location).start_with?("NyxPod-") and File.basename(location).size == 43 then
                    KeyValueStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{File.basename(location)}", location)
                end
                if NyxGalaxyFinder::locationIsTarget(location, uniquestring) then
                    KeyValueStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}", location)
                    return location
                end
            }
        nil
    end

    # NyxGalaxyFinder::uniqueStringToLocationOrNull(uniquestring)
    def self.uniqueStringToLocationOrNull(uniquestring)
        maybefilepath = KeyValueStore::getOrNull(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}")
        if maybefilepath and File.exists?(maybefilepath) and NyxGalaxyFinder::locationIsTarget(maybefilepath, uniquestring) then
            return maybefilepath
        end
        maybefilepath = NyxGalaxyFinder::uniqueStringToLocationOrNullUseTheForce(uniquestring)
        if maybefilepath then
            KeyValueStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}", maybefilepath)
        end
        maybefilepath
    end

end

