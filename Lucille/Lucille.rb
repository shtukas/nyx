
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

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

DATABANK_FOLDER_PATH = "/Users/pascal/Galaxy/DataBank"
CATALYST_FOLDERPATH = "#{DATABANK_FOLDER_PATH}/Catalyst"
BIN_TIMELINE_FOLDERPATH = "#{CATALYST_FOLDERPATH}/Bin-Timeline"

class Lucille

    # Lucille::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # -----------------------------
    # IO (1)

    # Lucille::pathToItems()
    def self.pathToItems()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items"
    end

    # Lucille::pathToMetadata()
    def self.pathToMetadata()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Metadata"
    end

    # Lucille::pathToTimelines()
    def self.pathToTimelines()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Timelines"
    end

    # -----------------------------
    # IO (2)

    # Lucille::applyNextTransformationToContent(content)
    def self.applyNextTransformationToContent(content)

        positionOfFirstNonSpaceCharacter = lambda{|line, size|
            return (size-1) if !line.start_with?(" " * size)
            positionOfFirstNonSpaceCharacter.call(line, size+1)
        }

        lines = content.strip.lines.to_a
        return content if lines.empty?
        slineWithIndex = lines
            .reject{|line| line.strip == "" }
            .each_with_index
            .map{|line, i| [line, i] }
            .reduce(nil) {|selectedLineWithIndex, cursorLineWithIndex|
                if selectedLineWithIndex.nil? then
                    cursorLineWithIndex
                else
                    if (positionOfFirstNonSpaceCharacter.call(selectedLineWithIndex.first, 1) < positionOfFirstNonSpaceCharacter.call(cursorLineWithIndex.first, 1)) and (selectedLineWithIndex[1] == cursorLineWithIndex[1]-1) then
                        cursorLineWithIndex
                    else
                        selectedLineWithIndex
                    end
                end
            }
        sline = slineWithIndex.first
        lines
            .reject{|line| line == sline }
            .join()
            .strip
    end

    # Lucille::garbageCollection()
    def self.garbageCollection()
        Lucille::locations()
            .each{|location|
                next if location[-4, 4] != ".txt"
                content = IO.read(location)
                next if content.nil?
                next if content.strip.size > 0
                FileUtils.rm(location)
            }
    end

    # Lucille::ensurel22Filenames()
    def self.ensurel22Filenames()
        Lucille::locations()
            .each{|location|
                next if File.basename(location)[0, 3] == "202"
                location2 = "#{File.dirname(location)}/#{Lucille::timeStringL22()} #{File.basename(location)}"
                FileUtils.mv(location, location2)
            }
    end

    # Lucille::deleteLucilleLocation(location)
    def self.deleteLucilleLocation(location)
        Lucille::moveLocationToCatalystBin(location)
        LucilleCore::removeFileSystemLocation(location)
        location2 = "/Users/pascal/Desktop/#{File.basename(location)}"
        if File.exists?(location2) then
            LucilleCore::removeFileSystemLocation(location2)
        end
        location3 = "#{Lucille::pathToTimelines()}/#{File.basename(location)}.timeline.txt"
        if File.exists?(location3) then
            LucilleCore::removeFileSystemLocation(location3)
        end
    end

    # -----------------------------
    # Data

    # Lucille::locations()
    def self.locations()
        Dir.entries(Lucille::pathToItems())
            .reject{|filename| filename[0, 1] == "." }
            .sort
            .map{|filename| "#{Lucille::pathToItems()}/#{filename}" }
    end

    # Lucille::timelines()
    def self.timelines()
        Lucille::locations()
                .map{|location| Lucille::getTimeline(location) }
                .uniq
                .sort
    end

    # Lucille::setTimeline(location, timeline)
    def self.setTimeline(location, timeline)
        filepath = "#{Lucille::pathToTimelines()}/#{File.basename(location)}.timeline.txt"
        File.open(filepath, "w"){|f| f.puts(timeline) }
    end

    # Lucille::getTimeline(location)
    def self.getTimeline(location)
        filepath = "#{Lucille::pathToTimelines()}/#{File.basename(location)}.timeline.txt"
        return "[Inbox]" if !File.exists?(filepath)
        IO.read(filepath).strip
    end

    # -----------------------------
    # Operations

    # Lucille::openLocation(location)
    def self.openLocation(location)
        openableFileExtensions3 = [
            ".txt",
            ".jpg"
        ]

        openableFileExtensions4 = [
            ".webm",
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

        if File.file?(location) and openableFileExtensions3.include?(location[-4, 4]) then
            system("open '#{location}'")
            return
        end
        if File.file?(location) and openableFileExtensions4.include?(location[-5, 5]) then
            system("open '#{location}'")
            return
        end
    end

    # Lucille::moveLocationToCatalystBin(location)
    def self.moveLocationToCatalystBin(location)
        return if location.nil?
        return if !File.exists?(location)
        folder1 = "#{BIN_TIMELINE_FOLDERPATH}/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m-%d")}/#{Time.new.strftime("%Y-%m-%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{Lucille::timeStringL22()}"
        FileUtils.mkdir(folder3)
        FileUtils.mv(location, folder3)
    end

    # -------------------------------------------------------
    # Activity Management (driven by In Flight Control System)

    # Lucille::startLocation(location)
    def self.startLocation(location)
        KeyValueStore::setFlagTrue(nil, "50e4fe12-de3d-4def-915b-8924c9195a51:#{location}")
    end

    # Lucille::stopLocation(location)
    def self.stopLocation(location)
        KeyValueStore::setFlagFalse(nil, "50e4fe12-de3d-4def-915b-8924c9195a51:#{location}")
    end

    # Lucille::isLocationRunning(location)
    def self.isLocationRunning(location)
        KeyValueStore::flagIsTrue(nil, "50e4fe12-de3d-4def-915b-8924c9195a51:#{location}")
    end

end






