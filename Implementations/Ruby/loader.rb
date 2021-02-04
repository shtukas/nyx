
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

require 'colorize'

require 'sqlite3'

require 'find'

require 'thread'

require "time"

require 'colorize'

# -----------------------------------------------------------------------
# require 'curses' # I commented that out, thereby disabling 
# Miscellaneous::ncurseSelection1410(lambda1, lambda2) ,
# when I introduced pepin 

require 'pepin'

=begin
list = Array[String]
item = Pepin.search(list) # Launches interactive window and returns selected item
=end

# -----------------------------------------------------------------------

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation or nil, setuuid: String, valueuuid: String)
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

# ------------------------------------------------------------

require_relative "Miscellaneous.rb" # Should come first as containing core definitions
require_relative "BackupsMonitor.rb"
require_relative "Bank.rb"
=begin 
    Bank::put(uuid, weight)
    Bank::value(uuid)
=end
require_relative "Calendar.rb"
require_relative "DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)
require_relative "DxThreads.rb"
require_relative "Ordinals.rb"
require_relative "ProgrammableBooleans.rb"
require_relative "Quarks.rb"
require_relative "Runner.rb"
=begin 
    Runner::isRunning?(uuid)
    Runner::runTimeInSecondsOrNull(uuid) # null | Float
    Runner::start(uuid)
    Runner::stop(uuid) # null | Float
=end
require_relative "SectionsType0141.rb"
require_relative "TodoArrows.rb"
require_relative "TodoCoreData.rb"
require_relative "TodoGarbageCollection.rb"
require_relative "TodoPatricia.rb"
require_relative "TodoUIServices.rb"
require_relative "VideoStream.rb"
require_relative "Waves.rb"

# ------------------------------------------------------------

require_relative "Commons.rb"
require_relative "Classifiers.rb"
require_relative "Events.rb"
require_relative "NereidProxyOperator.rb"
require_relative "NX141FSCacheElement.rb"
require_relative "NyxArrows.rb"
require_relative "NyxBinaryBlobsService.rb"
require_relative "NyxFilenameReaderWriter.rb"
require_relative "NyxGalaxyFinder.rb"
require_relative "NyxPatricia.rb"
require_relative "NyxUserInterface.rb"
require_relative "NyxUtils.rb"

# ------------------------------------------------------------

require_relative "Nereid.rb"
=begin
    NereidInterface::interactivelyIssueNewElementOrNull()
    NereidInterface::insertElementComponents(uuid, unixtime, description, type, payload)
    NereidInterface::insertElement(element)
    NereidInterface::toString(input) # input: uuid: String , element Element
    NereidInterface::getElementOrNull(uuid)
    NereidInterface::getElements()
    NereidInterface::landing(input) # input: uuid: String , element Element
    NereidInterface::access(input)
    NereidInterface::edit(input): # new element with same uuid, or null
    NereidInterface::transmuteOrNull(element): # new element with same uuid, or null
    NereidInterface::destroyElement(uuid) # Boolean # Indicates if the destroy was logically successful.

    NereidInterface::setOwnership(uuid, owner)
    NereidInterface::unsetOwnership(uuid, owner)
    NereidInterface::getOwnersForUUID(uuid)
=end
