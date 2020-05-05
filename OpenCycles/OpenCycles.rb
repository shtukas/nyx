
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
        AetherKVStore::set(aetherfilepath, "payloadType", "aionpoint")
        AetherKVStore::set(aetherfilepath, "472ec67c0dd6", text)
    end

    # --------------------------------------
    # This is a copy of the Lucille function
    # --------------------------------------
    # OpenCycles::setPayloadType(uuid, payloadType)
    def self.setPayloadType(uuid, payloadType)
        aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "payloadType", payloadType)
    end

    # --------------------------------------
    # This is a copy of the Lucille function
    # --------------------------------------
    # OpenCycles::getPayloadType(uuid)
    def self.getPayloadType(uuid)
        aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
        AetherKVStore::getOrNull(aetherfilepath, "payloadType")
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

    # --------------------------------------
    # This is a copy of the Lucille function
    # --------------------------------------
    # OpenCycles::exportAionContentAtDesktop(uuid)
    def self.exportAionContentAtDesktop(uuid)
        exportfolderpath = "/Users/pascal/Desktop/#{uuid}"
        return if File.exists?(exportfolderpath)
        FileUtils.mkdir(exportfolderpath)
        aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
        AetherAionOperations::exportReferenceAtFolder(aetherfilepath, "1815ea639314", exportfolderpath)
    end

    # --------------------------------------
    # This is a copy of the Lucille function
    # --------------------------------------
    # OpenCycles::openItemReadOnly(uuid)
    def self.openItemReadOnly(uuid)
        payloadType = OpenCycles::getPayloadType(uuid)
        if payloadType == "aionpoint" then
            OpenCycles::exportAionContentAtDesktop(uuid)
        end
        if payloadType == "text" then
            aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
            text = AetherKVStore::getOrNull(aetherfilepath, "472ec67c0dd6")
            tmpfilepath = "/tmp/#{uuid}.txt"
            File.open(tmpfilepath, "w") {|f| f.puts(text) }
            system("open '#{tmpfilepath}'")
        end
        if payloadType == "url" then
            aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
            url = AetherKVStore::getOrNull(aetherfilepath, "67c2db721728")
            system("open '#{url}'")
        end
    end

    # --------------------------------------
    # This is a copy of the Lucille function
    # --------------------------------------
    # OpenCycles::intelligentReadOnlyOpen(uuid)
    def self.intelligentReadOnlyOpen(uuid) # Boolean # returns whether or not the intelligent opening did work
        payloadType = OpenCycles::getPayloadType(uuid)
        if payloadType == "aionpoint" then
            exportfolderpath = "/tmp/#{OpenCycles::timeStringL22()}"
            FileUtils.mkdir(exportfolderpath)
            aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
            AetherAionOperations::exportReferenceAtFolder(aetherfilepath, "1815ea639314", exportfolderpath)
            getBestDescendantFileInsideFolderOrNull = lambda{|folderpath|
                locations = LucilleCore::locationsAtFolder(folderpath)
                if locations.size == 1 then
                    location = locations[0]
                    if File.directory?(location) then
                        getBestDescendantFileInsideFolderOrNull.call(location)
                    else
                        if [".txt", ".png", ".jpg", ".jpeg", ".pdf"].any?{|ext| location[-ext.size, ext.size] == ext } then
                            location
                        else
                            nil
                        end
                    end
                else
                    nil
                end
            }
            filepath = getBestDescendantFileInsideFolderOrNull.call(exportfolderpath)
            if filepath then
                system("open '#{filepath}'")
                return true
            else
                return false
            end
        end
        if payloadType == "text" then
            OpenCycles::openItemReadOnly(uuid)
            return true
        end
        if payloadType == "url" then
            OpenCycles::openItemReadOnly(uuid)
            return true
        end
    end

    # --------------------------------------
    # This is a copy of the Lucille function
    # --------------------------------------
    # OpenCycles::bestOpen(uuid)
    def self.bestOpen(uuid)
        status = OpenCycles::intelligentReadOnlyOpen(uuid)
        if !status then
            OpenCycles::openItemReadOnly(uuid)
        end
    end

    # OpenCycles::editContent(uuid)
    def self.editContent(uuid)

        payloadType = OpenCycles::getPayloadType(uuid)

        if payloadType == "aionpoint" then
            exportfolderpath = "/Users/pascal/Desktop/#{uuid}"
            while File.exists?(exportfolderpath) do
                puts "-> I am seeing a folder [#{uuid}] on the Desktop"
                puts "-> It might be from a previous export"
                puts "-> Please delete it or rename it to continue with edition"
                LucilleCore::pressEnterToContinue()
            end
            FileUtils.mkdir(exportfolderpath)
            puts "-> When edition is done I am going to import #{exportfolderpath}"
            aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
            AetherAionOperations::exportReferenceAtFolder(aetherfilepath, "1815ea639314", exportfolderpath)
            puts "-> Edition in progress... Next step will be the import."
            LucilleCore::pressEnterToContinue()
            AetherAionOperations::importLocationAgainstReference(aetherfilepath, "1815ea639314", exportfolderpath)
            puts "-> Put copying the target to Catalyst Bin Timeline"
            CatalystCommon::copyLocationToCatalystBin(exportfolderpath)
            puts "-> Deleting the target"
            LucilleCore::removeFileSystemLocation(exportfolderpath)
        end

        if payloadType == "text" then
            aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
            text = AetherKVStore::getOrNull(aetherfilepath, "472ec67c0dd6")
            text = CatalystCommon::editTextUsingTextmate(text)
            AetherKVStore::set(aetherfilepath, "472ec67c0dd6", text)
        end

        if payloadType == "url" then
            aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
            url = AetherKVStore::getOrNull(aetherfilepath, "67c2db721728")
            url = CatalystCommon::editTextUsingTextmate(url).strip
            AetherKVStore::set(aetherfilepath, "67c2db721728", url)
        end
    end

    # OpenCycles::terminateItem(uuid)
    def self.terminateItem(uuid)
        aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
        CatalystCommon::copyLocationToCatalystBin(aetherfilepath)
        FileUtils.rm(aetherfilepath)
    end

    # OpenCycles::recastAsIFCSItem(uuid)
    def self.recastAsIFCSItem(uuid)
        # OpenCycles has
        #    [TheLucilleTypeAetherCarrier]
        # IFCS expect
        #    [TheLucilleTypeAetherCarrier]
        #    position    : Float
        aetherfilepath = OpenCycles::uuid2aetherfilepath(uuid)
        AetherKVStore::set(aetherfilepath, "payloadType", "aionpoint")
        ifcsreport = `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs-items-report`
        puts ifcsreport
        position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
        AetherKVStore::set(aetherfilepath, "position", position)
        ifcsfilepath = "/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles/Items/#{File.basename(aetherfilepath)}"
        FileUtils.mv(aetherfilepath, ifcsfilepath)
    end

    # -----------------------------
    # User Interface

    # OpenCycles::selectItemOrNull()
    def self.selectItemOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("item:", OpenCycles::uuids().sort, lambda {|uuid| "[#{OpenCycles::getPayloadType(uuid)}] #{OpenCycles::getDescription(uuid)}"  })
    end

    # OpenCycles::itemDive(uuid)
    def self.itemDive(uuid)
        loop {
            system("clear")
            puts "uuid: #{uuid}"
            puts "description: #{OpenCycles::getDescription(uuid)}"
            options = [
                "open",
                "edit",
                "destroy",
                "set description",
                ">ifcs"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "open" then
                OpenCycles::exportAionContentAtDesktop(uuid)
            end
            if option == "edit" then
                OpenCycles::editContent(uuid)
            end
            if option == "destroy" then
                OpenCycles::terminateItem(uuid)
                return
            end
            if option == "set description" then
                text = OpenCycles::getDescription(uuid)
                text = CatalystCommon::editTextUsingTextmate(text)
                OpenCycles::setDescription(uuid, text)
            end
            if option == ">ifcs" then
                OpenCycles::recastAsIFCSItem(uuid)
                return
            end
        }
    end
end
