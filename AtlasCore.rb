
# encoding: utf-8

# require_relative "AtlasCore.rb"

# --------------------------------------------

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "1ac4eb69"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'json'

require 'date'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'find'

require_relative "LucilleCore.rb"

require_relative "KeyValueStore.rb"
=begin

    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)

=end

# -------------------------------------------------------

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
                    KeyValueStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}", location)
                    return location
                end
            }
        nil
    end

    # AtlasCore::uniqueStringToLocationOrNull(uniquestring)
    def self.uniqueStringToLocationOrNull(uniquestring)
        maybefilepath = KeyValueStore::getOrNull(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}")
        if maybefilepath and File.exists?(maybefilepath) and AtlasCore::locationIsTarget(maybefilepath, uniquestring) then
            return maybefilepath
        end
        maybefilepath = AtlasCore::uniqueStringToLocationOrNullUseTheForce(uniquestring)
        if maybefilepath then
            KeyValueStore::set(nil, "932fce73-2582-468b-bacc-ebdb4f140654:#{uniquestring}", maybefilepath)
        end
        maybefilepath
    end

end

