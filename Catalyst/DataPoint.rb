
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoint.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/AtlasCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

require_relative "CoreData.rb"

# -----------------------------------------------------------------

class DataPoint

    # --------------------------------------------------
    # Makers

    # DataPoint::selectOneFilepathOnTheDesktopOrNull()
    def self.selectOneFilepathOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.file?(filepath) }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # DataPoint::selectOneFolderpathOnTheDesktopOrNull()
    def self.selectOneFolderpathOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.directory?(filepath) }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("folderpath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # DataPoint::issueDataPointLineInteractively()
    def self.issueDataPointLineInteractively()
        line = LucilleCore::askQuestionAnswerAsString("line: ")
        point = {
            "nyxType"          => "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "uuid"             => SecureRandom.uuid,

            "type" => "line",
            "line" => line
        }
        Nyx::commitToDisk(point)
        point
    end

    # DataPoint::issueDataPointUrlInteractively()
    def self.issueDataPointUrlInteractively()
        url = LucilleCore::askQuestionAnswerAsString("url: ")
        point = {
            "nyxType"           => "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "type" => "url",
            "url"  => url
        }
        Nyx::commitToDisk(point)
        point
    end

    # DataPoint::issueDataPointFileInteractivelyOrNull()
    def self.issueDataPointFileInteractivelyOrNull()
        filepath1 = DataPoint::selectOneFilepathOnTheDesktopOrNull()
        return nil if filepath1.nil?
        filename1 = File.basename(filepath1)
        filename2 = "#{CatalystCommon::l22()}-#{filename1}"
        filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
        FileUtils.mv(filepath1, filepath2)
        CoreDataFile::copyFileToRepository(filepath2)
        point = {
            "nyxType"          => "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "uuid"             => SecureRandom.uuid,

            "type"     => "file",
            "filename" => filename2
        }
        Nyx::commitToDisk(point)
        point
    end

    # DataPoint::issueDataPointFile(filepath)
    def self.issueDataPointFile(filepath1)
        filename1 = File.basename(filepath1)
        filename2 = "#{CatalystCommon::l22()}-#{filename1}"
        filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
        FileUtils.mv(filepath1, filepath2)
        CoreDataFile::copyFileToRepository(filepath2)
        point = {
            "nyxType"           => "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "type"     => "file",
            "filename" => filename2
        }
        Nyx::commitToDisk(point)
        point
    end

    # DataPoint::issueDataPointFolderInteractivelyOrNull()
    def self.issueDataPointFolderInteractivelyOrNull()
        folderpath1 = DataPoint::selectOneFolderpathOnTheDesktopOrNull()
        return nil if folderpath1.nil?
        foldername1 = File.basename(folderpath1)
        foldername2 = "#{CatalystCommon::l22()}-#{foldername1}"
        folderpath2 = "#{File.dirname(folderpath1)}/#{foldername2}"
        FileUtils.mv(folderpath1, folderpath2)
        CoreDataDirectory::copyFolderToRepository(folderpath2)
        point = {
            "nyxType"           => "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "type"       => "folder",
            "foldername" => foldername2
        }
        Nyx::commitToDisk(point)
        point
    end

    # DataPoint::issueDataPointUniqueNameInteractively()
    def self.issueDataPointUniqueNameInteractively()
        uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
        point = {
            "nyxType"           => "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "creationUnixtime" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "type" => "unique-name",
            "name" => uniquename
        }
        Nyx::commitToDisk(point)
        point
    end

    # DataPoint::issueDataPointDirectoryMarkInteractively()
    def self.issueDataPointDirectoryMarkInteractively()
        options = ["mark file already exists", "mark file should be created"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return nil if option.nil?
        if option == "mark file already exists" then
            mark = LucilleCore::askQuestionAnswerAsString("mark: ")
            point = {
                "nyxType"           => "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
                "creationUnixtime" => Time.new.to_f,
                "uuid"              => SecureRandom.uuid,

                "type" => "directory-mark",
                "mark" => mark
            }
            Nyx::commitToDisk(point)
            return point
        end
        if option == "mark file should be created" then
            mark = nil
            loop {
                pointFolderLocation = LucilleCore::askQuestionAnswerAsString("Location to the point folder: ")
                if !File.exists?(pointFolderLocation) then
                    puts "I can't see location '#{pointFolderLocation}'"
                    puts "Let's try that again..."
                    next
                end
                mark = SecureRandom.uuid
                markFilepath = "#{pointFolderLocation}/Nyx-Directory-Mark.txt"
                File.open(markFilepath, "w"){|f| f.write(mark) }
                break
            }
            point = {
                "nyxType"           => "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
                "creationUnixtime" => Time.new.to_f,
                "uuid"              => SecureRandom.uuid,

                "type" => "directory-mark",
                "mark" => mark
            }
            Nyx::commitToDisk(point)
            return point
        end
    end

    # DataPoint::issueNewDataPointInteractivelyOrNull()
    def self.issueNewDataPointInteractivelyOrNull()
        puts "Making a new DataPoint..."
        types = ["line", "url", "file", "folder", "unique-name", "directory-mark"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            return DataPoint::issueDataPointLineInteractively()
        end
        if type == "url" then
            return DataPoint::issueDataPointUrlInteractively()
        end
        if type == "file" then
            return DataPoint::issueDataPointFileInteractivelyOrNull()
        end
        if type == "folder" then
            return DataPoint::issueDataPointFolderInteractivelyOrNull()
        end
        if type == "unique-name" then
            return DataPoint::issueDataPointUniqueNameInteractively()
        end
        if type == "directory-mark" then
            return DataPoint::issueDataPointDirectoryMarkInteractively()
        end
    end

    # DataPoint::locationToFileOrFolderDataPoint(location)
    def self.locationToFileOrFolderDataPoint(location)
        raise "f8e3b314" if !File.exists?(location)
        if File.file?(location) then
            filepath1 = location
            filename1 = File.basename(filepath1)
            filename2 = "#{CatalystCommon::l22()}-#{filename1}"
            filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
            FileUtils.mv(filepath1, filepath2)
            CoreDataFile::copyFileToRepository(filepath2)
            FileUtils.mv(filepath2, filepath1) # putting thing back so that the location doesn't disappear under the nose of the caller
            point = {
                "nyxType"           => "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
                "creationUnixtime" => Time.new.to_f,
                "uuid"              => SecureRandom.uuid,

                "type"     => "file",
                "filename" => filename2
            }
            Nyx::commitToDisk(point)
            point
        else
            folderpath1 = location
            foldername1 = File.basename(folderpath1)
            foldername2 = "#{CatalystCommon::l22()}-#{foldername1}"
            folderpath2 = "#{File.dirname(foldername1)}/#{foldername2}"
            FileUtils.mv(folderpath1, folderpath2)
            CoreDataDirectory::copyFolderToRepository(folderpath2)
            FileUtils.mv(folderpath2, folderpath1) # putting thing back so that the location doesn't disappear under the nose of the caller
            point = {
                "nyxType"           => "data-point-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
                "creationUnixtime" => Time.new.to_f,
                "uuid"              => SecureRandom.uuid,

                "type"       => "folder",
                "foldername" => foldername2
            }
            Nyx::commitToDisk(point)
            point
        end
    end

    # --------------------------------------------------
    # User Interface

    # DataPoint::dataPointToString(point)
    def self.dataPointToString(point)
        if point["type"] == "line" then
            return "[data point] [line] #{point["line"]}"
        end
        if point["type"] == "file" then
            return "[data point] [file] #{point["filename"]}"
        end
        if point["type"] == "url" then
            return "[data point] [url] #{point["url"]}"
        end
        if point["type"] == "folder" then
            return "[data point] [folder] #{point["foldername"]}"
        end
        if point["type"] == "unique-name" then
            return "[data point] [unique name] #{point["name"]}"
        end
        if point["type"] == "directory-mark" then
            return "[data point] [directory mark] #{point["mark"]}"
        end
        raise "DataPoint error 3c7968e4"
    end

    # DataPoint::openDataPoint(point)
    def self.openDataPoint(point)
        if point["type"] == "line" then
            puts point["line"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if point["type"] == "file" then
            CoreDataFile::openOrCopyToDesktop(point["filename"])
            return
        end
        if point["type"] == "url" then
            system("open '#{point["url"]}'")
            return
        end
        if point["type"] == "folder" then
            CoreDataDirectory::openFolder(point["foldername"])
            return
        end
        if point["type"] == "unique-name" then
            uniquename = point["name"]
            location = AtlasCore::uniqueStringToLocationOrNull(uniquename)
            if location then
                puts "opening: #{location}"
                system("open '#{location}'")
            else
                puts "I could not determine the location of unique name: #{uniquename}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if point["type"] == "directory-mark" then
            mark = point["mark"]
            location = AtlasCore::uniqueStringToLocationOrNull(mark)
            if location then
                puts "opening: #{File.dirname(location)}"
                system("open '#{File.dirname(location)}'")
            else
                puts "I could not determine the location of mark: #{mark}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        raise "DataPoint error 160050-490261"
    end

    # DataPoint::diveDataPoint(point)
    def self.diveDataPoint(point)
        puts "-> point:"
        puts JSON.pretty_generate(point)
        puts DataPoint::dataPointToString(point)
        if LucilleCore::askQuestionAnswerAsBoolean("open ? ", true) then
            DataPoint::openDataPoint(point)
        end
    end

    # DataPoint::visitGivenDataPoints(points)
    def self.visitGivenDataPoints(points)
        toStringLambda = lambda { |point| DataPoint::dataPointToString(point) }
        point = LucilleCore::selectEntityFromListOfEntitiesOrNull("Choose point", points, toStringLambda)
        return if point.nil?
        DataPoint::diveDataPoint(point)
    end
end
