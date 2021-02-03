
# encoding: UTF-8

class NyxGalaxyFinder

    # NyxGalaxyFinder::locationIsUnisonTmp(location)
    def self.locationIsUnisonTmp(location)
        mark = ".unison.tmp"
        location[-mark.size, mark.size] == mark
    end

    # NyxGalaxyFinder::rootScans()
    def self.rootScans()
        [
            "/Users/pascal/Desktop",
            "/Users/pascal/Galaxy"
        ]
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

    # NyxGalaxyFinder::locationIsTarget(location, uniquestring)
    def self.locationIsTarget(location, uniquestring)
        return false if NyxGalaxyFinder::locationIsUnisonTmp(location)
        File.basename(location).include?(uniquestring)
    end

    # NyxGalaxyFinder::extractNX141MarkerFromFilenameOrNull(filename)
    def self.extractNX141MarkerFromFilenameOrNull(filename)
        # From the convention 
        # NX141-[*], where [*] is a string of unspecified length with no space and no dot.
        correction = lambda {|str|
            if str.include?(' ') then
                return correction.call(str[0, str.size-1])
            end
            if str.include?('.') then
                return correction.call(str[0, str.size-1])
            end
            str        
        }
        if filename.include?('NX141-') then
            extraction = filename[filename.index('NX141-'), filename.size]
            return correction.call(extraction)
        end
        nil
    end

    # NyxGalaxyFinder::uniqueStringToLocationOrNullUseTheForce(uniquestring)
    def self.uniqueStringToLocationOrNullUseTheForce(uniquestring)
        NyxGalaxyFinder::locationEnumerator(NyxGalaxyFinder::rootScans())
            .each{|location|
                if (mark = NyxGalaxyFinder::extractNX141MarkerFromFilenameOrNull(File.basename(location))) then
                    KeyValueStore::set(nil, "e402f085-6390-4950-b11d-78ee93ecbc41:#{mark}", location)
                end
                if NyxGalaxyFinder::locationIsTarget(location, uniquestring) then
                    KeyValueStore::set(nil, "e402f085-6390-4950-b11d-78ee93ecbc41:#{uniquestring}", location)
                    return location
                end
            }
        nil
    end

    # NyxGalaxyFinder::uniqueStringToLocationOrNull(uniquestring)
    def self.uniqueStringToLocationOrNull(uniquestring)
        maybefilepath = KeyValueStore::getOrNull(nil, "e402f085-6390-4950-b11d-78ee93ecbc41:#{uniquestring}")
        if maybefilepath and File.exists?(maybefilepath) and File.basename(maybefilepath).include?(uniquestring) then
            return maybefilepath
        end
        maybefilepath = NyxGalaxyFinder::uniqueStringToLocationOrNullUseTheForce(uniquestring)
        if maybefilepath then
            KeyValueStore::set(nil, "e402f085-6390-4950-b11d-78ee93ecbc41:#{uniquestring}", maybefilepath)
        end
        maybefilepath
    end
end
