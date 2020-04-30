
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
    Mercury::dequeueFirstValueOrNull(channel)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)

    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)
=end

require_relative "../Catalyst-Common/Catalyst-Common.rb"

# -----------------------------------------------------------------

class OpenCycles

    # OpenCycles::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # -----------------------------
    # IO (1)

    # OpenCycles::pathToItems()
    def self.pathToItems()
        "#{CATALYST_COMMON_CATALYST_FOLDERPATH}/OpenCycles/Items"
    end

    # -----------------------------
    # IO (2)

    # OpenCycles::ensureStandardFilenames()
    def self.ensureStandardFilenames()
        OpenCycles::locations()
            .each{|location|
                if File.basename(location).include?("'") then
                    location2 = "#{File.dirname(location)}/#{File.basename(location).gsub("'", ",")}"
                    FileUtils.mv(location, location2)
                    location = location2
                end
                next if File.basename(location)[0, 3] == "202"
                location2 = "#{File.dirname(location)}/#{OpenCycles::timeStringL22()} #{File.basename(location)}"
                FileUtils.mv(location, location2)
            }
    end

    # -----------------------------
    # Data

    # OpenCycles::setDescription(location, description)
    def self.setDescription(location, description)
        descriptionKeySuffix = location.gsub("OpenCycles", "Lucille") # Backward compatibility after the fork
        KeyValueStore::set(nil, "3bbaacf8-2114-4d85-9738-0d4784d3bbb2:#{location}", descriptionKeySuffix)
    end

    # OpenCycles::getBestDescription(location)
    def self.getBestDescription(location)
        descriptionKeySuffix = location.gsub("OpenCycles", "Lucille") # Backward compatibility after the fork
        description = KeyValueStore::getOrNull(nil, "3bbaacf8-2114-4d85-9738-0d4784d3bbb2:#{descriptionKeySuffix}")
        return description if description
        File.basename(location)
    end

    # OpenCycles::locations()
    def self.locations()
        Dir.entries(OpenCycles::pathToItems())
            .reject{|filename| filename[0, 1] == "." }
            .sort
            .map{|filename| "#{OpenCycles::pathToItems()}/#{filename}" }
    end

    # -----------------------------
    # Operations

    # OpenCycles::openLocation(location)
    def self.openLocation(location)
        openableFileExtensions = [
            ".txt",
            ".jpg",
            ".png",
            ".eml",
            ".webm",
            ".jpeg",
            ".webloc"
        ]

        return if !File.exists?(location)
        if File.directory?(location) then
            system("open '#{location}'")
            return
        end

        if File.file?(location) and location[-4, 4] == ".txt" and IO.read(location).strip.lines.to_a.size == 1 and IO.read(location).strip.start_with?("http") then
            url = IO.read(location).strip
            if ENV["COMPUTERLUCILLENAME"] == "Lucille18" then
                system("open '#{url}'")
            else
                system("open -na 'Google Chrome' --args --new-window '#{url}'")
            end
            return
        end

        if File.file?(location) and openableFileExtensions.any?{|extension| location[-extension.size, extension.size] == extension } then
            system("open '#{location}'")
            return
        end
    end

    # OpenCycles::transformLocationFileIntoLocationFolder(location)
    def self.transformLocationFileIntoLocationFolder(location)
        return File.basename(location) if !File.file?(location)
        locationbasename = File.basename(location)
        location2basename = OpenCycles::timeStringL22()

        location2 = "#{CATALYST_COMMON_CATALYST_FOLDERPATH}/OpenCycles/Items/#{location2basename}" # The new receptacle for the file
        FileUtils.mkdir(location2)
        LucilleCore::copyFileSystemLocation(location, location2)

        loop {
            description = OpenCycles::getBestDescription(location)
            break if description.nil?
            OpenCycles::setDescription(location2, description)
            break
        }

        LucilleCore::removeFileSystemLocation(location)

        channel = "0b5b0b54-ea17-40f6-b3f7-d0bfaa641470-open-cycles-to-ifcs-renaming"
        message = {
            "old" => locationbasename,
            "new" => location2basename
        }
        Mercury::postValue(channel, message)

        location2
    end

    # OpenCycles::selectLocationOrNull()
    def self.selectLocationOrNull()
        locations = OpenCycles::locations()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("locations:", locations, lambda {|location| OpenCycles::getBestDescription(location) })
    end

end

class OpenCyclesXUserInterface

    # OpenCyclesXUserInterface::doneLucilleLocation(location)
    def self.doneLucilleLocation(location)
        CatalystCommon::copyLocationToCatalystBin(location)
        LucilleCore::removeFileSystemLocation(location)
    end

    # OpenCyclesXUserInterface::locationDive(location)
    def self.locationDive(location)
        loop {
            system("clear")
            puts "location: #{location}"
            puts "description: #{OpenCycles::getBestDescription(location)}"
            options = [
                "open",
                "destroy",
                "set description",
                "transmute into folder"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "open" then
                OpenCycles::openLocation(location)
            end
            if option == "destroy" then
                OpenCyclesXUserInterface::doneLucilleLocation(location)
                return
            end
            if option == "set description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                OpenCycles::setDescription(location, description)
            end
            if option == "transmute into folder" then
                OpenCycles::transformLocationFileIntoLocationFolder(location)
            end
        }
    end
end
