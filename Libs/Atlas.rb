
class Atlas

    # Atlas::locationIsUnisonTmp(location)
    def self.locationIsUnisonTmp(location)
        mark = ".unison.tmp"
        location[-mark.size, mark.size] == mark
    end

    # Atlas::scanroots()
    def self.scanroots()
        roots = []
        roots << "#{Config::userHomeDirectory()}/Desktop"
        roots << "#{Config::userHomeDirectory()}/Galaxy"
        roots
    end

    # Atlas::locationIsTarget(location, uniquestring)
    def self.locationIsTarget(location, uniquestring)
        return false if Atlas::locationIsUnisonTmp(location)
        File.basename(location).include?(uniquestring)
    end

    # Atlas::locationEnumerator(roots)
    def self.locationEnumerator(roots)
        Enumerator.new do |filepaths|
            roots.each{|root|
                if File.exist?(root) then
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

    # Atlas::uniqueStringToLocationOrNullUseTheForce(uniquestring)
    def self.uniqueStringToLocationOrNullUseTheForce(uniquestring)
        Atlas::locationEnumerator(Atlas::scanroots())
            .each{|location|
                if Atlas::locationIsTarget(location, uniquestring) then
                    XCache::set("932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}", location)
                    return location
                end
            }
        nil
    end

    # Atlas::uniqueStringToLocationOrNull(uniquestring)
    def self.uniqueStringToLocationOrNull(uniquestring)
        filepath = XCache::getOrNull("932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}")
        if filepath and File.exist?(filepath) and Atlas::locationIsTarget(filepath, uniquestring) then
            return filepath
        end
        filepath = Atlas::uniqueStringToLocationOrNullUseTheForce(uniquestring)
        if filepath then
            XCache::set("932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}", filepath)
        end
        filepath
    end

end
