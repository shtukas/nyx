
# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'
require 'time'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(5) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'colorize'

require 'sqlite3'

require 'find'

require 'thread'

require 'colorize'

require 'drb/drb'

# ------------------------------------------------------------

checkLocation = lambda{|location|
    if !File.exist?(location) then
        puts "I cannot see location: #{location.green}"
        exit
    end
} 

checkLocation.call("#{ENV['HOME']}/Galaxy/Software/Lucille-Ruby-Libraries")
checkLocation.call("#{ENV['HOME']}/x-space/xcache-v1-days")

# ------------------------------------------------------------

require_relative "Config.rb"

require_relative "LucilleCore.rb"

require_relative "XCache.rb"
=begin
    XCache::set(key, value)
    XCache::getOrNull(key)
    XCache::getOrDefaultValue(key, defaultValue)
    XCache::destroy(key)

    XCache::setFlag(key, flag)
    XCache::getFlag(key)

    XCache::filepath(key)
=end

require_relative "AionCore.rb"
=begin

The operator is an object that has meet the following signatures

    .putBlob(blob: BinaryData) : Hash
    .filepathToContentHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        XCache::set("SHA256-#{Digest::SHA256.hexdigest(blob)}", blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
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

AionCore::commitLocationReturnHash(operator, location)
AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)

AionFsck::structureCheckAionHashRaiseErrorIfAny(operator, nhash)

=end

require_relative "Solingen.rb"

# ------------------------------------------------------------

require_relative "Atlas.rb"

require_relative "CommonUtils.rb"
require_relative "CoreDataRefs.rb"

require_relative "Dx8Units.rb"

require_relative "Galaxy.rb"

require_relative "ItemStore.rb"

require_relative "Links.rb"

require_relative "NxNodes.rb"
require_relative "Nyx.rb"
require_relative "NxTaxonomies.rb"
require_relative "NxNotes.rb"

require_relative "ProgrammableBooleans.rb"

require_relative "Search.rb"

require_relative "UniqueStrings.rb"

# ------------------------------------------------------------
