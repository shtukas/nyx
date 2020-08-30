
# encoding: utf-8

class NyxGalaxyFinder

    # NyxGalaxyFinder::locationIsUnisonTmp(location)
    def self.locationIsUnisonTmp(location)
        mark = ".unison.tmp"
        location[-mark.size, mark.size] == mark
    end

    # NyxGalaxyFinder::locationIsTarget(location, uniquestring)
    def self.locationIsTarget(location, uniquestring)
        return false if NyxGalaxyFinder::locationIsUnisonTmp(location)
        File.basename(location).include?(uniquestring)
    end

    # NyxGalaxyFinder::locationIsElement(location)
    def self.locationIsElement(location)
        return false if NyxGalaxyFinder::locationIsUnisonTmp(location)
        File.basename(location).start_with?("NyxDir-") or File.basename(location).start_with?("NyxFile-")
    end

    # NyxGalaxyFinder::scanroots()
    def self.scanroots()
        ["/Users/pascal/Galaxy"]
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

    # NyxGalaxyFinder::elementsLocationsEnumerator()
    def self.elementsLocationsEnumerator()
        Enumerator.new do |locations|
            NyxGalaxyFinder::locationEnumerator(NyxGalaxyFinder::scanroots()).each{|location|
                next if !NyxGalaxyFinder::locationIsElement(location)
                locations << location
            }
        end
    end

    # NyxGalaxyFinder::scansurvey()
    def self.scansurvey()
        # We do this for caching NyxDirs
        NyxGalaxyFinder::locationEnumerator(NyxGalaxyFinder::scanroots())
            .each{|location|
                if NyxGalaxyFinder::locationIsElement(location) then
                    KeyValueStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{File.basename(location)}", location)
                end
            }
        nil
    end

    # NyxGalaxyFinder::uniqueStringToLocationOrNullUseTheForce(uniquestring)
    def self.uniqueStringToLocationOrNullUseTheForce(uniquestring)
        NyxGalaxyFinder::locationEnumerator(NyxGalaxyFinder::scanroots())
            .each{|location|
                if !NyxGalaxyFinder::locationIsUnisonTmp(location) and File.basename(location).start_with?("NyxDir-") then
                    KeyValueStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{File.basename(location)}", location) # Capturing the NyxDirs en passant
                end
                if !NyxGalaxyFinder::locationIsUnisonTmp(location) and File.basename(location).start_with?("NyxFile-") then
                    KeyValueStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{File.basename(location)[0, 44]}", location) # Capturing the NyxFile name en passant
                end
                if NyxGalaxyFinder::locationIsTarget(location, uniquestring) then
                    KeyValueStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}", location)
                    return location
                end
            }
        nil
    end

    # NyxGalaxyFinder::uniqueStringToLocationOrNullUseCacheOnly(uniquestring)
    def self.uniqueStringToLocationOrNullUseCacheOnly(uniquestring)
        location = KeyValueStore::getOrNull(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}")
        return nil if location.nil?
        return nil if !File.exists?(location)
        location
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

