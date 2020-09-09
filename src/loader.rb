
# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'

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

require 'find'

require 'thread'

require "time"

require 'curses'

require 'colorize'

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
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
        KeyValueStore::set(nil, "SHA256-#{Digest::SHA256.hexdigest(blob)}", blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = KeyValueStore::getOrNull(nil, nhash)
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

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/Dionysus1.rb"
=begin

Dionysus1::kvstore_set(filepath, key, value)
Dionysus1::kvstore_getOrNull(filepath, key): null or String
Dionysus1::kvstore_setObject(filepath, key, object)
Dionysus1::kvstore_getObjectOrNull(filepath, key): null or Object
Dionysus1::kvstore_destroy(filepath, key)

Dionysus1::sets_putObject(filepath, _setuuid_, _objectuuid_, _object_)
Dionysus1::sets_getObjectOrNull(filepath, _setuuid_, _objectuuid_): null or Object
Dionysus1::sets_getObjects(filepath, _setuuid_): Array[Object]
Dionysus1::sets_destroy(filepath, _setuuid_, _objectuuid_)

=end

# ------------------------------------------------------------

require_relative "Miscellaneous.rb" # Should come first as containing core definitions

require_relative "Arrows.rb"
require_relative "Asteroids.rb"
require_relative "GalaxyFinder.rb"

require_relative "BackupsMonitor.rb"
require_relative "Bank.rb"
=begin 
    Bank::put(uuid, weight)
    Bank::value(uuid)
=end

require_relative "Calendar.rb"
require_relative "CatalystObjectsOperator.rb"
require_relative "CatalystUI.rb"

require_relative "Curation.rb"

require_relative "DataPortalUI.rb"

require_relative "DisplayUtils.rb"

require_relative "DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

require_relative "EstateServices.rb"

require_relative "GeneralSearch.rb"
require_relative "GenericObjectInterface.rb"
require_relative "GlobalMaintenance.rb"

require_relative "LucilleCore.rb"

require_relative "NSDataPoint.rb"
require_relative "NSDatapointNyxElementLocation.rb"
require_relative "NSDataPointsExtended.rb"
require_relative "NyxGarbageCollection.rb"
require_relative "NyxFsck.rb"
require_relative "NyxObjects.rb"
require_relative "NyxFileSystemElementsMapping.rb"

require_relative "ProgrammableBooleans.rb"

require_relative "Runner.rb"
=begin 
    Runner::isRunning?(uuid)
    Runner::runTimeInSecondsOrNull(uuid) # null | Float
    Runner::start(uuid)
    Runner::stop(uuid) # null | Float
=end

require_relative "SectionsType0141.rb"
require_relative "SelectionLookupDataset.rb"

require_relative "VideoStream.rb"

require_relative "Waves.rb"

# ------------------------------------------------------------





