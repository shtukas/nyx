#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'drb/drb'

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require_relative "Commons.rb"

require 'colorize'

# -------------------------------------------------------------------------------------

STREAM_PERFECT_NUMBER = 6

# StreamClassification::getItemClassificationOrNull(uuid)
# StreamClassification::setItemClassification(uuid, classification)
# StreamClassification::updateItemClassification(uuid, classification, totalTimeSpan)
# StreamClassification::uuidToMetric(uuid)
# StreamClassification::extractUnClassifiedFolderpaths(folderpaths)
# StreamClassification::resolveClassificationForThisFolderpath(uuid)
# StreamClassification::getNumberOfClassificationForThisHour()
# StreamClassification::increaseNumberOfClassificationForThisHour()
# StreamClassification::dataManagementClassifying()

# classification: ["quicky", "medium", "project"]

class StreamClassification
    def self.getItemClassificationOrNull(uuid)
        classification = KeyValueStore::getOrNull(nil, "3dbfc3a1-4434-42b7-8e27-ced389fd2178:#{uuid}")
        return "quicky" if ![nil, "quicky", "medium", "project"].include?(classification) # because data got corrupted once
        classification
    end

    def self.setItemClassification(uuid, classification)
        KeyValueStore::set(nil, "3dbfc3a1-4434-42b7-8e27-ced389fd2178:#{uuid}", classification)
    end

    def self.updateItemClassification(uuid, classification, totalTimeSpan)
        if classification.nil? then
            StreamClassification::setItemClassification(uuid, "quicky")
        end
        if ( classification == "quicky" ) and ( totalTimeSpan > 3600*2 ) then
            StreamClassification::setItemClassification(uuid, "medium")
        end
        if ( classification == "medium" ) and ( totalTimeSpan > 3600*5 ) then
            StreamClassification::setItemClassification(uuid, "project") 
        end
    end

    def self.uuidToMetric(uuid)
        classification = StreamClassification::getItemClassificationOrNull(uuid)
        low, high = 0.0, 0.2 if classification.nil?
        low, high = 0.1, 0.4 if classification=="project"
        low, high = 0.3, 0.6 if classification=="medium"
        low, high = 0.5, 0.8 if classification=="quicky"
        DRbObject.new(nil, "druby://:10423").metric2(uuid, 7, 3, low, high, 2)
    end

    def self.extractUnClassifiedFolderpaths(folderpaths)
        folderpaths.select{|folderpath| 
            uuid = Stream::folderpath2uuid(folderpath)
            StreamClassification::getItemClassificationOrNull(uuid).nil? 
        }
    end

    def self.resolveClassificationForThisFolderpath(folderpath, shouldOpenFolder = true)
        puts "Stream: resolving clasification for #{folderpath}"
        LucilleCore::pressEnterToContinue()
        if shouldOpenFolder then
            system("open '#{folderpath}'")
        end
        classification = LucilleCore::interactivelySelectEntityFromListOfEntities_EnsureChoice("classification", ["quicky", "medium", "project"])  
        uuid = Stream::folderpath2uuid(folderpath)
        StreamClassification::setItemClassification(uuid, classification)
    end

    def self.getNumberOfClassificationForThisHour()
        KeyValueStore::getOrDefaultValue(nil, "0051e8da-68c6-44df-a3bb-51fcbcd6ed49:#{Time.new.to_s[0,13]}", "0").to_i
    end

    def self.increaseNumberOfClassificationForThisHour()
        newcount = StreamClassification::getNumberOfClassificationForThisHour()+1
        KeyValueStore::set(nil, "0051e8da-68c6-44df-a3bb-51fcbcd6ed49:#{Time.new.to_s[0,13]}", newcount)
    end

end

# Stream::folderpaths(itemsfolderpath)
# Stream::getItemDescription(folderpath)
# Stream::folderpath2uuid(folderpath)
# Stream::getUUIDs()
# Stream::simplifyURLCarryingString(string)
# Stream::naturalTargetUnderLocation(location): (type, address) , where type is "file" or "url"
# Stream::folderpathToCatalystObject(folderpath, indx, streamName)
# Stream::performObjectClosing(object)
# Stream::objectCommandHandler(object, command)
# Stream::getCatalystObjectsFromDisk()
# Stream::getCatalystObjects()

class Stream

    @@naturalTargets = {}

    def self.folderpaths(itemsfolderpath)
        Dir.entries(itemsfolderpath)
            .select{|filename| filename[0,1]!='.' }
            .sort
            .map{|filename| "#{itemsfolderpath}/#{filename}" }
    end

    def self.getItemDescription(folderpath)
        uuid = IO.read("#{folderpath}/.uuid").strip
        description = KeyValueStore::getOrDefaultValue(nil, "c441a43a-bb70-4850-b23c-1db5f5665c9a:#{uuid}", "#{folderpath}")
    end

    def self.folderpath2uuid(folderpath)
        if !File.exist?("#{folderpath}/.uuid") then
            File.open("#{folderpath}/.uuid", 'w'){|f| f.puts(SecureRandom.hex(4)) }
        end
        IO.read("#{folderpath}/.uuid").strip
    end

    def self.getUUIDs()
        ["strm1", "strm2"].map{|streamName|
            Stream::folderpaths("#{CATALYST_COMMON_PATH_TO_STREAM_DOMAIN_FOLDER}/#{streamName}")
            .map{|folderpath| Stream::folderpath2uuid(folderpath) }
        }.flatten
    end

    def self.simplifyURLCarryingString(string)
        return string if /http/.match(string).nil?
        [/^\{\s\d*\s\}/, /^\[\]/, /^line:/, /^todo:/, /^url:/, /^\[\s*\d*\s*\]/]
            .each{|regex|
                if ( m = regex.match(string) ) then
                    string = string[m.to_s.size, string.size].strip
                    return Stream::simplifyURLCarryingString(string)
                end
            }
        string
    end

    def self.naturalTargetUnderLocation(location)
        value = @@naturalTargets[location]
        return value if value
        value =
            if File.file?(location) then
                ["file", location]
            else
                nonDotFilespaths = Dir.entries(location)
                    .select{|filename| filename[0,1]!="." }
                    .map{|filename| "#{location}/#{filename}" }
                if nonDotFilespaths.size==1 then
                    filepath = nonDotFilespaths[0]
                    if filepath[-4,4]==".txt" then
                        if IO.read(filepath).strip.lines.to_a.size==1 then
                            line = IO.read(filepath).strip
                            line = Stream::simplifyURLCarryingString(line)
                            if line.start_with?("http") then
                                ["url", line]
                            else
                                ["line", line]
                            end
                        else
                            ["file", filepath]
                        end
                    elsif filepath[-7,7]==".webloc" and !filepath.include?("'") then
                        ["file", filepath]
                    else
                        ["file", location]
                    end
                else
                    ["file", location]
                end
            end
        @@naturalTargets[location] = value
        value
    end

    def self.naturalTargetToDisplayName(pair)
        return pair[1] if pair[0]=="line"
        return pair[1] if pair[0]=="url"
        target = pair[1]
        return File.basename(target) if target[-7,7]==".webloc" 
        target
    end

    def self.folderpathToCatalystObject(folderpath, indx, streamName)
        uuid = Stream::folderpath2uuid(folderpath)
        description = Stream::getItemDescription(folderpath)
        classification = StreamClassification::getItemClassificationOrNull(uuid)
        isRunning = DRbObject.new(nil, "druby://:10423").isRunning(uuid)
        metric = isRunning ? 2 : StreamClassification::uuidToMetric(uuid) * Math.exp(-indx.to_f/20)
        commands = ( isRunning ? ['stop'] : ['start'] ) + ["folder", "completed", "set-description", "rotate", ">medium", ">project", ">lib"]
        announce = "stream: #{Stream::naturalTargetToDisplayName(Stream::naturalTargetUnderLocation(folderpath))}#{ classification ? " { #{classification} }" : "" } (#{"%.2f" % ( DRbObject.new(nil, "druby://:10423").getEntityTotalTimespanForPeriod(uuid, 7).to_f/3600 )} hours)"
        if isRunning then
            announce = announce.green
        end
        {
            "uuid" => uuid,
            "metric" => metric,
            "announce" => "#{announce}",
            "commands" => commands,
            "default-expression" => ( commands[0] == "start" ? "start" : "" ),
            "command-interpreter" => lambda{|object, command| Stream::objectCommandHandler(object, command) },
            "item-folderpath" => folderpath,
            "item-stream-name" => streamName           
        }
    end

    def self.performObjectClosing(object)
        uuid = object['uuid']
        if DRbObject.new(nil, "druby://:10423").isRunning(uuid) then
            DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(uuid)
        end
        timespan = DRbObject.new(nil, "druby://:10423").getEntityTotalTimespanForPeriod(uuid, 7)
        if timespan>0 then
            classification = StreamClassification::getItemClassificationOrNull(uuid)
            streamName = object["item-stream-name"]
            folderpaths = Stream::folderpaths("#{CATALYST_COMMON_PATH_TO_STREAM_DOMAIN_FOLDER}/#{streamName}")
                .select{|folderpath|
                    StreamClassification::getItemClassificationOrNull(Stream::folderpath2uuid(folderpath))==classification
                }
                .first(STREAM_PERFECT_NUMBER)
            if folderpaths.size>0 then
                count = [STREAM_PERFECT_NUMBER, folderpaths.size].min
                folderpaths.each{|xfolderpath| 
                    next if xfolderpath == object['item-folderpath']
                    xuuid = Stream::folderpath2uuid(xfolderpath)
                    xtimespan =  timespan.to_f/count
                    puts "Putting #{xtimespan} seconds for #{xuuid}"
                    DRbObject.new(nil, "druby://:10423").addTimeSpan(xuuid, xtimespan)
                }
            end
        end
        time = Time.new
        targetFolder = "#{CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y-%m")}/#{time.strftime("%Y-%m-%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}/"
        puts "Source: #{object['item-folderpath']}"
        puts "Target: #{targetFolder}"
        FileUtils.mkpath(targetFolder)
        FileUtils.mv("#{object['item-folderpath']}",targetFolder)
        LucilleCore::removeFileSystemLocation(object['item-folderpath'])
    end

    def self.objectCommandHandlerCore(object, command)
        uuid = object['uuid']
        StreamClassification::updateItemClassification(
            uuid, 
            StreamClassification::getItemClassificationOrNull(uuid), 
            DRbObject.new(nil, "druby://:10423").getEntityTotalTimespan(uuid))
        if command=='rotate' then
            sourcelocation = object["item-folderpath"]
            targetfolderpath  = "#{CATALYST_COMMON_PATH_TO_STREAM_DOMAIN_FOLDER}/strm2/#{LucilleCore::timeStringL22()}"
            FileUtils.mv(sourcelocation, targetfolderpath)
        end
        if command=='folder' then
            system("open '#{object['item-folderpath']}'")
        end
        if command=='start' then
            DRbObject.new(nil, "druby://:10423").start(uuid)
            system("open '#{Stream::naturalTargetUnderLocation(object["item-folderpath"])[1]}'")
        end
        if command=='stop' then
            DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(uuid)
        end
        if command=="completed" then
            Stream::performObjectClosing(object)
        end
        if command=='set-description' then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            KeyValueStore::set(nil, "c441a43a-bb70-4850-b23c-1db5f5665c9a:#{uuid}", "#{description}")
        end
        if command=='>medium' then
            DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(uuid)
            StreamClassification::setItemClassification(uuid, "medium")
        end
        if command=='>project' then
            DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(uuid)
            StreamClassification::setItemClassification(uuid, "project")
        end
        if command=='>lib' then
            isRunning = DRbObject.new(nil, "druby://:10423").isRunning(uuid)
            if isRunning then
                puts "The items is currently running..."
                if !LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to close it and carry on with the librarian archiving? ") then
                    return
                end
                DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(uuid)
            end
            sourcefolderpath = object['item-folderpath']
            atlasreference = "atlas-#{SecureRandom.hex(8)}"
            puts "atlas reference: #{atlasreference}"
            staginglocation = "/Users/pascal/Desktop/#{atlasreference}"
            LucilleCore::copyFileSystemLocation(sourcefolderpath, staginglocation)
            puts "Stream folder moved to the staging folder (Desktop), edit and press [Enter]"
            LucilleCore::pressEnterToContinue()
            LibrarianExportedFunctions::librarianUserInterface_makeNewPermanodeInteractive(staginglocation, nil, nil, atlasreference, nil, nil)
            targetparentlocation = R136CoreUtils::getNewUniqueDataTimelineIndexSubFolderPathReadyToUse()
            LucilleCore::copyFileSystemLocation(staginglocation, targetparentlocation)
            LucilleCore::removeFileSystemLocation(staginglocation)
            Stream::performObjectClosing(object)
        end
    end

    def self.objectCommandHandler(object, command)
        status = Stream::objectCommandHandlerCore(object, command)
        KeyValueStore::set(nil, "7DC2D872-1045-41B8-AE85-9F81F7699B7A", JSON.generate(Stream::getCatalystObjectsFromDisk()))
        status
    end

    def self.getCatalystObjectsFromDisk()
        ["strm1", "strm2"].map{|streamName|
            folderpaths = Stream::folderpaths("#{CATALYST_COMMON_PATH_TO_STREAM_DOMAIN_FOLDER}/#{streamName}")
            folderpaths.zip((0..folderpaths.size)).map{|folderpath, indx|
                Stream::folderpathToCatalystObject(folderpath, indx, streamName)
            }
        }.flatten
    end

    def self.getCatalystObjects()
        JSON.parse(KeyValueStore::getOrDefaultValue(nil, "7DC2D872-1045-41B8-AE85-9F81F7699B7A", "[]"))
            .map{|object| 
                object["command-interpreter"] = lambda{|object, command| Stream::objectCommandHandler(object, command) } # overriding this after deserialistion 
                object
            }
    end
end

# -------------------------------------------------------------------------------------

LucilleCore::assert(Stream::simplifyURLCarryingString("{ 1223 } [] line: todo: [ 173] http://www.mit.edu/~xela/tao.html")=="http://www.mit.edu/~xela/tao.html")

KeyValueStore::set(nil, "7DC2D872-1045-41B8-AE85-9F81F7699B7A", JSON.generate(Stream::getCatalystObjectsFromDisk()))

# -------------------------------------------------------------------------------------

