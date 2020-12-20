
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

    # GalaxyFinder::locationEnumerator(roots)
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

    # GalaxyFinder::uniqueStringToLocationOrNullUseTheForce(uniquestring)
    def self.uniqueStringToLocationOrNullUseTheForce(uniquestring)
        GalaxyFinder::locationEnumerator(GalaxyFinder::scanroots())
            .each{|location|
                next if GalaxyFinder::locationIsUnisonTmp(location)

                # We used to have NGX15s as Nyx objects. We got rid of them after migrating all of them to filesystem-unique-string quarks
                # We keep this short cut for convenience as many filesystem-unique-string carry NGX15 references as mark
                if File.basename(location).start_with?("NGX15-") then
                    basename = File.basename(location)
                    (6..basename.size).each{|indx|
                        KeyValueStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{basename[0, indx]}", location)
                    }
                end

                # NX141 is the default mark when a filesystem-unique-string quark is created
                if File.basename(location).index("NX141-") then
                    basename  = File.basename(location)
                    position  = basename.index("NX141-")
                    nx141name = basename[position+16]
                    KeyValueStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{nx141name}", location)
                end

                if File.basename(location).include?(uniquestring) then
                    KeyValueStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}", location)
                    return location
                end
            }
        nil
    end

    # GalaxyFinder::uniqueStringToLocationOrNull(uniquestring)
    def self.uniqueStringToLocationOrNull(uniquestring)
        maybefilepath = KeyValueStore::getOrNull(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}")
        if maybefilepath and File.exists?(maybefilepath) and File.basename(maybefilepath).include?(uniquestring) then
            return maybefilepath
        end
        maybefilepath = GalaxyFinder::uniqueStringToLocationOrNullUseTheForce(uniquestring)
        if maybefilepath then
            KeyValueStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}", maybefilepath)
        end
        maybefilepath
    end
end

