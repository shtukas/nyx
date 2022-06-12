
# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'
require 'time'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
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

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/XCache.rb"
=begin
    XCache::set(key, value)
    XCache::getOrNull(key)
    XCache::getOrDefaultValue(key, defaultValue)
    XCache::destroy(key)

    XCache::setFlag(key, flag)
    XCache::getFlag(key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/XCacheSets.rb"
=begin
    XCacheSets::values(setuuid: String): Array[Value]
    XCacheSets::set(setuuid: String, valueuuid: String, value)
    XCacheSets::getOrNull(setuuid: String, valueuuid: String): nil | Value
    XCacheSets::destroy(setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/AionCore.rb"
=begin

The operator is an object that has meet the following signatures

    .commitBlob(blob: BinaryData) : Hash
    .filepathToContentHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def commitBlob(blob)
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

AionFsck::structureCheckAionHash(operator, nhash)

=end

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/Mercury.rb"
=begin
    Mercury::postValue(channel, value)
    Mercury::dequeueFirstValueOrNull(channel)
=end

# ------------------------------------------------------------

require_relative "Ax1Text.rb"
require_relative "Anniversaries.rb"
require_relative "AionTransforms.rb"
require_relative "Architect.rb"

require_relative "Bank.rb"

require_relative "Catalyst.rb"
require_relative "Config.rb"
require_relative "CommonUtils.rb"
require_relative "CompositeElizabeth.rb"
require_relative "Commands.rb"
require_relative "CircleNavigation.rb"

require_relative "DoNotShowUntil.rb"
# DoNotShowUntil::setUnixtime(uid, unixtime)
# DoNotShowUntil::isVisible(uid)
require_relative "Dx8UnitsUtils.rb"

require_relative "EditionDesk.rb"
require_relative "EnergyGrid.rb"

require_relative "Galaxy.rb"
require_relative "Genealogy.rb"

require_relative "Interpreting.rb"
require_relative "ItemStore.rb"
require_relative "InternetStatus.rb"
require_relative "Iam.rb"

require_relative "FileSystemCheck.rb"

require_relative "Librarian.rb"
require_relative "LxAction.rb"
require_relative "LxFunction.rb"
require_relative "Landing.rb"

require_relative "NxDataNodes.rb"
require_relative "Nx102Flavors.rb"
require_relative "Nx111.rb"
require_relative "NxTimelines.rb"
require_relative "NyxNetworkSpecialCircumstances.rb"
require_relative "Nyx.rb"
require_relative "NxBallsService.rb"
require_relative "NxArrow.rb"
require_relative "NxRelation.rb"
require_relative "NxPerson.rb"
require_relative "NxCollections.rb"
require_relative "NxNavigation.rb"

require_relative "PrimitiveFiles.rb"
require_relative "ProgrammableBooleans.rb"

require_relative "SectionsType0141.rb"
require_relative "Search.rb"
require_relative "Streaming.rb"

require_relative "Transmutation.rb"
require_relative "TxFloats.rb"
require_relative "TxDateds.rb"
require_relative "TxTodos.rb"
require_relative "The99Percent.rb"
require_relative "TxPlus.rb"

require_relative "UniqueStringsFunctions.rb"

require_relative "XCacheElizabeth.rb"

require_relative "Waves.rb"

require_relative "Zone.rb"

# ------------------------------------------------------------
