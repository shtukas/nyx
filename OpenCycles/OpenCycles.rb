
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)

    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Mercury.rb"
=begin
    Mercury::postValue(channel, value)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)

    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Aether.rb"
=begin
    AetherGenesys::makeNewPoint(filepath)
    AetherKVStore::set(filepath, key, value)
    AetherKVStore::getOrNull(filepath, key)
    AetherKVStore::keys(filepath)
    AetherKVStore::destroy(filepath, key)
    AetherAionOperations::importLocationAgainstReference(filepath, xreference, location)
    AetherAionOperations::exportReferenceAtFolder(filepath, xreference, targetReconstructionFolderpath)
=end

require_relative "../Catalyst-Common/Catalyst-Common.rb"

# -----------------------------------------------------------------

class OpenCycles

    # OpenCycles::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # -----------------------------
    # IO

    # OpenCycles::pathToItems()
    def self.pathToItems()
        "#{CATALYST_COMMON_CATALYST_FOLDERPATH}/OpenCycles/I2tems"
    end

    # OpenCycles::uuid2aetherfilepath(uuid)
    def self.uuid2aetherfilepath(uuid)
        aetherfilename = "#{uuid}.data"
        "/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles/I2tems/#{aetherfilename}"
    end

    # OpenCycles::newItemPayloadText(text)
    def self.newItemPayloadText(text)
        uuid = OpenCycles::timeStringL22()
        aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
        AetherGenesys::makeNewPoint(aetherfilepath)
        AetherKVStore::set(aetherfilepath, "uuid", uuid)
        AetherKVStore::set(aetherfilepath, "description", text.lines.first.strip)
        filepath = "/tmp/#{uuid}"
        File.open(filepath, "w") {|f| f.puts(text) }
        AetherAionOperations::importLocationAgainstReference(aetherfilepath, "1815ea639314", filepath)
    end

    # -----------------------------
    # Data

    # OpenCycles::uuids()
    def self.uuids()
        Dir.entries(OpenCycles::pathToItems())
            .select{|filename| filename[-5, 5] == ".data" }
            .map{|filename| filename[0, 22] }
    end

    # OpenCycles::setDescription(uuid, description)
    def self.setDescription(uuid, description)
        aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "uuid", description)
    end

    # OpenCycles::getDescription(uuid)
    def self.getDescription(uuid)
        aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
        AetherKVStore::getOrNull(aetherfilepath, "description")
    end

    # -----------------------------
    # Operations

    # OpenCycles::exportContentsAtDesktop(uuid)
    def self.exportContentsAtDesktop(uuid)
        targetfolderpath = "/Users/pascal/Desktop/#{uuid}"
        return if File.exists?(targetfolderpath)
        FileUtils.mkdir(targetfolderpath)
        aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
        AetherAionOperations::exportReferenceAtFolder(aetherfilepath, "1815ea639314", targetfolderpath)
    end

    # OpenCycles::terminateItem(uuid)
    def self.terminateItem(uuid)
        aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
        CatalystCommon::copyLocationToCatalystBin(aetherfilepath)
        FileUtils.rm(aetherfilepath)
    end

    # OpenCycles::recastAsIFCSItem(uuid)
    def self.recastAsIFCSItem(uuid)
        # IFCS expect
        #    uuid        :
        #    description :
        #    payloadType :
        #    position    : Float
        # OpenCycles has
        #    uuid
        #    description
        aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "payloadType", "aionpoint")
        ifcsreport = `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs-items-report`
        puts ifcsreport
        position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
        AetherKVStore::set(aetherfilepath, "position", position)
        ifcsfilepath = "/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/Items/#{File.basename(aetherfilepath)}"
        FileUtils.mv(aetherfilepath, ifcsfilepath)
    end

    # -----------------------------
    # User Interface

    # OpenCycles::selectItemOrNull()
    def self.selectItemOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("item:", OpenCycles::uuids(), lambda {|uuid| OpenCycles::getDescription(uuid) })
    end

    # OpenCycles::itemDive(uuid)
    def self.itemDive(uuid)
        loop {
            system("clear")
            puts "uuid: #{uuid}"
            puts "description: #{OpenCycles::getDescription(uuid)}"
            options = [
                "open",
                "destroy",
                "set description",
                ">ifcs"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "open" then
                OpenCycles::exportContentsAtDesktop(uuid)
            end
            if option == "destroy" then
                OpenCycles::terminateItem(uuid)
                return
            end
            if option == "set description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                OpenCycles::setDescription(uuid, description)
            end
            if option == ">ifcs" then
                OpenCycles::recastAsIFCSItem(uuid)
                return
            end
        }
    end
end
