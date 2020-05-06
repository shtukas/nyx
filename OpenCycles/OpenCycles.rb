
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

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/CoreData.rb"
=begin

    CoreDataFile::copyFileToRepository(filepath)
    CoreDataFile::filenameToFilepath(filename)
    CoreDataFile::filenameIsCurrent(filename)
    CoreDataFile::openOrCopyToDesktop(filename)
    CoreDataFile::deleteFile(filename)

    CoreDataDirectory::copyFolderToRepository(folderpath)
    CoreDataDirectory::foldernameToFolderpath(foldername)
    CoreDataDirectory::openFolder(foldername)
    CoreDataDirectory::deleteFolder(foldername)

=end

require_relative "../Catalyst-Common/Catalyst-Common.rb"

# -----------------------------------------------------------------

class OpenCycles

    # OpenCycles::pathToClaims()
    def self.pathToClaims()
        "/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles/Claims"
    end

    # OpenCycles::claims()
    def self.claims()
        Dir.entries(OpenCycles::pathToClaims())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{OpenCycles::pathToClaims()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|c1, c2| c1["creationtime"] <=> c2["creationtime"] }
    end

    # OpenCycles::getClaimByUUIDOrNUll(uuid)
    def self.getClaimByUUIDOrNUll(uuid)
        filepath = "#{OpenCycles::pathToClaims()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # OpenCycles::save(claim)
    def self.save(claim)
        uuid = claim["uuid"]
        File.open("#{OpenCycles::pathToClaims()}/#{uuid}.json", "w"){|f| f.puts(JSON.pretty_generate(claim)) }
    end

    # OpenCycles::destroy(claim)
    def self.destroy(claim)
        uuid = claim["uuid"]
        filepath = "#{OpenCycles::pathToClaims()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # OpenCycles::makeClaim(uuid, description, target)
    def self.makeClaim(uuid, description, target)
        {
            "uuid"         => uuid,
            "creationtime" => Time.new.to_f,
            "description"  => description,
            "target"       => target
        }
    end

    # OpenCycles::issueClaim(uuid, description, target)
    def self.issueClaim(uuid, description, target)
        claim = OpenCycles::makeClaim(uuid, description, target)
        OpenCycles::save(claim)
    end

    # OpenCycles::selectClaimOrNull()
    def self.selectClaimOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("claim:", OpenCycles::claims(), lambda {|claim| claim["description"] })
    end

    # OpenCycles::claimDive(claim)
    def self.claimDive(claim)
        loop {
            system("clear")
            puts "uuid: #{claim["uuid"]}"
            puts "description: #{claim["description"]}"
            options = [
                "open",
                "destroy",
                "set description",
                ">ifcs"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "open" then
                CatalystCommon::openCatalystStandardTarget(claim["target"])
            end
            if option == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this claim? ") then
                    OpenCycles::destroy(claim)
                end
                return
            end
            if option == "set description" then
                claim["description"] = CatalystCommon::editTextUsingTextmate(claim["description"])
                OpenCycles::save(claim)
            end
            if option == ">ifcs" then
                OpenCycles::issueIfcsClaim(claim)
                return
            end
        }
    end

    # OpenCycles::issueIfcsClaim(claim)
    def self.issueIfcsClaim(claim)
    end
end
