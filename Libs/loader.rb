
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

checkLocation.call("#{ENV['HOME']}/Galaxy/DataBank/Stargate-Config.json")
checkLocation.call("#{ENV['HOME']}/Galaxy/DataHub/NxTodos-BufferIn")
checkLocation.call("#{ENV['HOME']}/Galaxy/DataHub/Stargate-DataCenter")
checkLocation.call("#{ENV['HOME']}/Galaxy/Nyx")
checkLocation.call("#{ENV['HOME']}/Galaxy/LucilleOS/Libraries/Ruby-Libraries")
checkLocation.call("#{ENV['HOME']}/x-space/xcache-v1-days")

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

AionFsck::structureCheckAionHashRaiseErrorIfAny(operator, nhash)

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
require_relative "Ax39.rb"

require_relative "Bank.rb"

require_relative "Catalyst.rb"
require_relative "CatalystListing.rb"
require_relative "CommonUtils.rb"
require_relative "CompositeElizabeth.rb"

require_relative "DoNotShowUntil.rb"
# DoNotShowUntil::setUnixtime(uid, unixtime)
# DoNotShowUntil::isVisible(uid)
require_relative "Dx8Units.rb"
require_relative "DatablobStore.rb"

require_relative "Locks.rb"

require_relative "Galaxy.rb"
require_relative "GeneralTimeManagement.rb"

require_relative "Interpreting.rb"
require_relative "ItemStore.rb"
require_relative "InternetStatus.rb"
require_relative "InMemoryStore.rb"

require_relative "FileSystemCheck.rb"

require_relative "LambdX1s.rb"

require_relative "MiscTypesTimeCommitments.rb"

require_relative "NxTops.rb"
require_relative "Nyx.rb"
require_relative "Nx113.rb"
require_relative "NxTodos.rb"
require_relative "NxTriages.rb"
require_relative "NxOndates.rb"
require_relative "NxBalls.rb"
require_relative "NxNetwork.rb"
require_relative "NxNodes.rb"
require_relative "NxWTimeCommitments.rb"
require_relative "NxOTimeCommitments.rb"
require_relative "NxProjects.rb"

require_relative "PrimitiveFiles.rb"
require_relative "ProgrammableBooleans.rb"
require_relative "PolyActions.rb"
require_relative "PolyFunctions.rb"

require_relative "SectionsType0141.rb"
require_relative "Search.rb"
require_relative "Stargate.rb"
require_relative "SyncConflicts.rb"
require_relative "Skips.rb"

require_relative "TxManualCountDowns.rb"
require_relative "The99Percent.rb"
require_relative "TxStratospheres.rb"
require_relative "TheSpeedOfLight.rb"
require_relative "Transmutations.rb"

require_relative "Waves.rb"

# ------------------------------------------------------------

$bank_database_semaphore = Mutex.new
$dnsu_database_semaphore = Mutex.new
$owner_items_mapping_database_semaphore = Mutex.new
$links_database_semaphore = Mutex.new
$arrows_database_semaphore = Mutex.new

# ------------------------------------------------------------

if $RunNonEssentialThreads then

    if Config::thisInstanceId() == "Lucille20-pascal" then 
        Thread.new {
            loop {
                sleep 600
                system("#{File.dirname(__FILE__)}/bin/vienna-import")
            }
        }
    end

    if Config::getOrNull("isLeaderInstance") then
        Thread.new {
            loop {
                sleep 3600
                CatalystListing::listingItems()
            }
        }
    end

    Thread.new {
        loop {
            sleep 12
            The99Percent::line()
            sleep 600
        }
    }

    Thread.new {
        loop {
            filepath = SyncConflicts::getConflictFileOrNull()
            if filepath then
                $SyncConflictInterruptionFilepath = filepath
            end
            sleep 600
        }
    }

    Thread.new {
        loop {
            sleep 120

            NxBalls::items().each{|nxball|
                if (Time.new.to_i - nxball["unixtime"]) > 3600 then
                    CommonUtils::onScreenNotification("catalyst", "NxBall over 1 hour")
                end
            }

            NxWTimeCommitments::runningItems().each{|item|
                if NxWTCTodayTimeLoads::itemLiveTimeThatShouldBeDoneTodayInHours(item) == 0 then
                    CommonUtils::onScreenNotification("catalyst", "wtc is overflowing")
                end
            }

            NxOTimeCommitments::runningItems().each{|item|
                if NxOTimeCommitments::itemLiveTimeThatShouldBeDoneTodayInHours(item) == 0 then
                    CommonUtils::onScreenNotification("catalyst", "otc is overflowing")
                end
            }
        }
    }
end

# ------------------------------------------------------------