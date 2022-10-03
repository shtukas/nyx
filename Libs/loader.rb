
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

require 'drb/drb'

# ------------------------------------------------------------

checkLocation = lambda{|location|
    if !File.exists?(location) then
        puts "I cannot see location: #{location.green}"
        exit
    end
} 

checkLocation.call("#{ENV['HOME']}/x-space/xcache-v1-days")
checkLocation.call("#{ENV['HOME']}/Desktop/NxTodos")
checkLocation.call("#{ENV['HOME']}/Galaxy/LucilleOS/Libraries/Ruby-Libraries")
checkLocation.call("#{ENV['HOME']}/Galaxy/DataHub")
checkLocation.call("#{ENV['HOME']}/Galaxy/DataBank/Stargate")
checkLocation.call("#{ENV['HOME']}/Galaxy/DataBank/Stargate/config.json")
checkLocation.call("#{ENV['HOME']}/Galaxy/DataBank/Stargate/items.sqlite3")
checkLocation.call("#{ENV['HOME']}/Galaxy/DataBank/Stargate/primary-structure")
checkLocation.call("#{ENV['HOME']}/Galaxy/StargateMultiInstanceShared3")
checkLocation.call("#{ENV['HOME']}/Galaxy/StargateMultiInstanceShared3/shared-config.json")
checkLocation.call("#{ENV['HOME']}/Galaxy/DataBank/Stargate/DataStore1OutGoingBuffer")

filepath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/network-links.sqlite3"
if !File.exists?(filepath) then
    db = SQLite3::Database.new(filepath)
    db.busy_timeout = 117
    db.busy_handler { |count| true }
    db.results_as_hash = true
    db.execute("create table _links_ (_eventuuid_ text primary key, _eventTime_ float, _sourceuuid_ text, _operation_ text, _targetuuid_ text)", [])
    db.close
end

filepath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/network-arrows.sqlite3"
if !File.exists?(filepath) then
    db = SQLite3::Database.new(filepath)
    db.busy_timeout = 117
    db.busy_handler { |count| true }
    db.results_as_hash = true
    db.execute("create table _arrows_ (_eventuuid_ text primary key, _eventTime_ float, _sourceuuid_ text, _operation_ text, _targetuuid_ text)", [])
    db.close
end

# ------------------------------------------------------------

require_relative "Config.rb"

require "#{Config::userHomeDirectory()}/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "#{Config::userHomeDirectory()}/Galaxy/LucilleOS/Libraries/Ruby-Libraries/XCache.rb"
=begin
    XCache::set(key, value)
    XCache::getOrNull(key)
    XCache::getOrDefaultValue(key, defaultValue)
    XCache::destroy(key)

    XCache::setFlag(key, flag)
    XCache::getFlag(key)

    XCache::filepath(key)
=end

require "#{Config::userHomeDirectory()}/Galaxy/LucilleOS/Libraries/Ruby-Libraries/XCacheSets.rb"
=begin
    XCacheSets::values(setuuid: String): Array[Value]
    XCacheSets::set(setuuid: String, valueuuid: String, value)
    XCacheSets::getOrNull(setuuid: String, valueuuid: String): nil | Value
    XCacheSets::destroy(setuuid: String, valueuuid: String)
=end

require "#{Config::userHomeDirectory()}/Galaxy/LucilleOS/Libraries/Ruby-Libraries/AionCore.rb"
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

AionFsck::structureCheckAionHash(operator, nhash)

=end

require "#{Config::userHomeDirectory()}/Galaxy/LucilleOS/Libraries/Ruby-Libraries/Mercury2.rb"
=begin
    Mercury2::put(channel, value)
    Mercury2::readFirstOrNull(channel)
    Mercury2::dequeue(channel)
    Mercury2::empty?(channel)
=end

# ------------------------------------------------------------

require_relative "Anniversaries.rb"
require_relative "AionTransforms.rb"
require_relative "Ax39.rb"

require_relative "Bank.rb"
require_relative "BankAccountDoneForToday.rb"

require_relative "Catalyst.rb"
require_relative "CatalystListing.rb"
require_relative "CommonUtils.rb"
require_relative "CompositeElizabeth.rb"
require_relative "Cx22.rb"
require_relative "Cx23.rb"

require_relative "DoNotShowUntil.rb"
# DoNotShowUntil::setUnixtime(uid, unixtime)
# DoNotShowUntil::isVisible(uid)
require_relative "Dx8UnitsUtils.rb"
require_relative "DataStore1.rb"

require_relative "EnergyGrid.rb"

require_relative "Galaxy.rb"

require_relative "Interpreting.rb"
require_relative "ItemStore.rb"
require_relative "InternetStatus.rb"
require_relative "ItemsEventsLog.rb"

require_relative "FileSystemCheck.rb"

require_relative "Machines.rb"

require_relative "Nyx.rb"
require_relative "NxBallsService.rb"
require_relative "Nx113.rb"
require_relative "NyxNodes.rb"
require_relative "Nx11E.rb"
require_relative "NxTodos.rb"
require_relative "NetworkShapeAroundNode.rb"
require_relative "NxDeleted.rb"
require_relative "NxLines.rb"
require_relative "NetworkEdges.rb"

require_relative "PrimitiveFiles.rb"
require_relative "ProgrammableBooleans.rb"
require_relative "PolyActions.rb"
require_relative "PolyFunctions.rb"
require_relative "PolyPrograms.rb"

require_relative "SectionsType0141.rb"
require_relative "Search.rb"
require_relative "SystemEvents.rb"
require_relative "Stargate.rb"
require_relative "SQLiteDataStore2.rb"

require_relative "The99Percent.rb"
require_relative "Items.rb"
require_relative "ThreadsX.rb"
require_relative "TheLibrarian.rb"

require_relative "UniqueStringsFunctions.rb"
require_relative "Upload.rb"

require_relative "Waves.rb"

require_relative "XCacheDatablobs.rb"
require_relative "XCacheValuesWithExpiry.rb"

# ------------------------------------------------------------

$bank_database_semaphore = Mutex.new
$dnsu_database_semaphore = Mutex.new
$commline_semaphore = Mutex.new
$owner_items_mapping_database_semaphore = Mutex.new
$links_database_semaphore = Mutex.new
$arrows_database_semaphore = Mutex.new
$system_events_out_buffer = Mutex.new

# ------------------------------------------------------------

$CatalystGroupMonitor1 = CatalystGroupMonitor.new()
$CatalystAlfred1 = CatalystAlfred.new()

# ------------------------------------------------------------

if $RunNonEssentialThreads then
    ThreadsX::nxBallsMonitoringAndNotification()
    ThreadsX::outBufferToCommsLine()
    if Config::get("instanceId") == "Lucille20-pascal" then 
        ThreadsX::startViennaImport()
    end
end

# ------------------------------------------------------------