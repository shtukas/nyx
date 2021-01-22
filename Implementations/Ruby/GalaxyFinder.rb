
# encoding: utf-8

class GalaxyFinder

    # GalaxyFinder::locationIsUnisonTmp(location)
    def self.locationIsUnisonTmp(location)
        mark = ".unison.tmp"
        location[-mark.size, mark.size] == mark
    end

    # GalaxyFinder::scanroots()
    def self.scanroots()
        [
            "/Users/pascal/Desktop",
            "/Users/pascal/Galaxy"
        ]
    end

    # GalaxyFinder::forbiddenPaths()
    def self.forbiddenPaths()
        [
            "/Users/pascal/Galaxy/Software"
        ]
    end

    # GalaxyFinder::locationIsTarget(location, uniquestring)
    def self.locationIsTarget(location, uniquestring)
        return false if GalaxyFinder::locationIsUnisonTmp(location)
        File.basename(location).include?(uniquestring)
    end

    # GalaxyFinder::locationEnumerator(roots)
    def self.locationEnumerator(roots)
        Enumerator.new do |filepaths|
            roots.each{|root|
                if File.exists?(root) then
                    begin
                        Find.find(root) do |path|
                            prune if GalaxyFinder::forbiddenPaths().include?(path)
                            filepaths << path
                        end
                    rescue
                    end
                end
            }
        end
    end

    # GalaxyFinder::extractNX141MarkerFromFilenameOrNull(filename)
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

    # GalaxyFinder::uniqueStringToLocationOrNullUseTheForce(uniquestring)
    def self.uniqueStringToLocationOrNullUseTheForce(uniquestring)
        GalaxyFinder::locationEnumerator(GalaxyFinder::scanroots())
            .each{|location|
                next if GalaxyFinder::locationIsUnisonTmp(location)
                if ( mark = GalaxyFinder::extractNX141MarkerFromFilenameOrNull(File.basename(location)) ) then
                    KeyValueStore::set(nil, "3ecadb11-dfd5-4d02-be89-4565a67e9891:#{mark}", location)
                end
                if GalaxyFinder::locationIsTarget(location, uniquestring) then
                    KeyValueStore::set(nil, "3ecadb11-dfd5-4d02-be89-4565a67e9891:#{uniquestring}", location)
                    return location
                end
            }
        nil
    end

    # GalaxyFinder::uniqueStringToLocationOrNull(uniquestring)
    def self.uniqueStringToLocationOrNull(uniquestring)
        maybefilepath = KeyValueStore::getOrNull(nil, "3ecadb11-dfd5-4d02-be89-4565a67e9891:#{uniquestring}")
        if maybefilepath and File.exists?(maybefilepath) and File.basename(maybefilepath).include?(uniquestring) then
            return maybefilepath
        end
        maybefilepath = GalaxyFinder::uniqueStringToLocationOrNullUseTheForce(uniquestring)
        if maybefilepath then
            KeyValueStore::set(nil, "3ecadb11-dfd5-4d02-be89-4565a67e9891:#{uniquestring}", maybefilepath)
        end
        maybefilepath
    end
end

