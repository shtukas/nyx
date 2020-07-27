
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

# ------------------------------------------------------------

require_relative "AionCore.rb"
require_relative "Anniversaries.rb"
require_relative "Arrows.rb"
require_relative "Asteroids.rb"
require_relative "AtlasCore.rb"

require_relative "BackupsMonitor.rb"
require_relative "Bank.rb"
=begin 
    Bank::put(uuid, weight)
    Bank::value(uuid)
=end

require_relative "BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation or nil, setuuid: String, valueuuid: String)
=end

require_relative "Calendar.rb"
require_relative "CatalystObjectsOperator.rb"
require_relative "CatalystUI.rb"

require_relative "Curation.rb"

require_relative "DataStore3RemoteControl.rb"
require_relative "DataStoresOrchestration"
require_relative "DataStore2DataStore3DirectionalSyncs.rb"
require_relative "DataPortalUI.rb"
require_relative "DeskOperator.rb"
require_relative "DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)
require_relative "DisplayUtils.rb"
require_relative "Drives.rb"

require_relative "EstateServices.rb"

require_relative "GeneralSearch.rb"

require_relative "KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore.rb"

require_relative "KeyToStringOnDiskStore.rb"
=begin
    KeyToStringOnDiskStore::setFlagTrue(repositorylocation or nil, key)
    KeyToStringOnDiskStore::setFlagFalse(repositorylocation or nil, key)
    KeyToStringOnDiskStore::flagIsTrue(repositorylocation or nil, key)

    KeyToStringOnDiskStore::set(repositorylocation or nil, key, value)
    KeyToStringOnDiskStore::getOrNull(repositorylocation or nil, key)
    KeyToStringOnDiskStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyToStringOnDiskStore::destroy(repositorylocation or nil, key)
=end

require_relative "Librarian.rb"
require_relative "LucilleCore.rb"

require_relative "Miscellaneous.rb"

require_relative "NSDT1Extended.rb"
require_relative "NSDataType0.rb"
require_relative "NSDataType1.rb"
require_relative "NSDataTypeX.rb"
require_relative "NyxBlobs.rb"
require_relative "NyxGarbageCollection.rb"
require_relative "NyxObjects.rb"

require_relative "Page.rb"
require_relative "ProgrammableBooleans.rb"

require_relative "Realms.rb"
require_relative "Runner.rb"
=begin 
    Runner::isRunning?(uuid)
    Runner::runTimeInSecondsOrNull(uuid) # null | Float
    Runner::start(uuid)
    Runner::stop(uuid) # null | Float
=end

require_relative "SectionsType0141.rb"
require_relative "ShadowFS.rb"

require_relative "VideoStream.rb"

require_relative "Waves.rb"

# ------------------------------------------------------------





