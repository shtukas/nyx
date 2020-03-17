# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/SectionsType0141.rb"
# SectionsType0141::contentToSections(reminaingLines: Array[String])

=begin

A part is a subset of the file starting with an header of the form:  
    @F6D5C243FE28-[sectionname]

The presence of "@F6D5C243FE28" ensures that the part is detected as such
The section name allow for differenceiations of the parts
The part that contains the todo sections we want is called (hardcoded): @F6D5C243FE28-A-TODO


Struct3 {
    "parts" : Array[String] # Different parts of the file, with their headers
    "todo"  : Array[String] 
        # Individual strings are sections # Multiline unique todo item
}

=end

LUCILLE_CALENDAR_FILE_PART_PATTERN = "@F6D5C243FE28"
LUCILLE_CALENDAR_FILE_TODO_WORK_PART_PATTERN = '@F6D5C243FE28-TODO-WORK---------------------------------------------------------'

class NSXLucilleCalendarFileUtils

    # NSXLucilleCalendarFileUtils::getLucilleCalendarPatternForThisPeriodOrNull()
    def self.getLucilleCalendarPatternForThisPeriodOrNull()
        isCoreWorkingHours = lambda{
            [1,2,3,4,5].include?(Time.new.wday) and Time.new.hour >= 10 and Time.new.hour < 16 
        }
        isCoreEveningHours = lambda{
            [0,6].include?(Time.new.wday) or Time.new.hour >= 16
        }
        if isCoreWorkingHours.call() then
            return LUCILLE_CALENDAR_FILE_TODO_WORK_PART_PATTERN
        end
        if isCoreEveningHours.call() then
            return '@F6D5C243FE28-TODO-HOME---------------------------------------------------------'
        end
        nil
    end

    # NSXLucilleCalendarFileUtils::lucilleCalendarFilenames()
    def self.lucilleCalendarFilenames()
        Dir.entries("/Users/pascal/Desktop")
            .select{|filename| filename.start_with?("Calendar") and filename.size == 35 }
            .sort
    end

    # NSXLucilleCalendarFileUtils::lucilleCalendarFilepaths()
    def self.lucilleCalendarFilepaths()
        NSXLucilleCalendarFileUtils::lucilleCalendarFilenames()
            .map{|filename| "/Users/pascal/Desktop/#{filename}" }
    end

    # NSXLucilleCalendarFileUtils::lucilleFilepathToStruct3(filepath)
    def self.lucilleFilepathToStruct3(filepath)
        struct3 = {}
        # We need to map reduce the lines of the files as parts
        parts = IO.read(filepath)
                    .strip
                    .lines
                    .reduce([]){|parts, line|
                        if line.include?(LUCILLE_CALENDAR_FILE_PART_PATTERN) then
                            parts << line
                        else
                            if parts.size > 0 then
                                parts[parts.size-1] = parts[parts.size-1] + line
                            else
                                parts = [line]
                            end
                        end
                        parts
                    }
                    .map{|part| part.strip }
        todo = []
        lucilleCalendarFilePattern = NSXLucilleCalendarFileUtils::getLucilleCalendarPatternForThisPeriodOrNull()
        if lucilleCalendarFilePattern then
            todo = parts
                .select{|part| part.include?(NSXLucilleCalendarFileUtils::getLucilleCalendarPatternForThisPeriodOrNull()) }
                .map{|part| part.lines.drop(1).join() }
                .map{|part| SectionsType0141::contentToSections(part.lines.to_a) }
                .flatten
                .map{|section| section.strip }
        end
        {
            "parts" => parts,
            "todo" => todo
        }
    end

    # NSXLucilleCalendarFileUtils::struct3TransformUpdatePartsWithTodo(struct3)
    def self.struct3TransformUpdatePartsWithTodo(struct3)
        lucilleCalendarFilePattern = NSXLucilleCalendarFileUtils::getLucilleCalendarPatternForThisPeriodOrNull()
        return struct3 if lucilleCalendarFilePattern.nil?
        parts1 = [ lucilleCalendarFilePattern + "\n\n" + struct3["todo"].join("\n\n") ]
        parts2 = struct3["parts"].reject{|part| part.include?(lucilleCalendarFilePattern) }
        {
            "parts" => parts1 + parts2,
            "todo" => struct3["todo"]
        }
    end

    # NSXLucilleCalendarFileUtils::struct3TransformApplyNextTransformationToStruct3(struct3)
    def self.struct3TransformApplyNextTransformationToStruct3(struct3)
        if struct3["todo"].size > 0 then
            struct3["todo"][0] = NSXMiscUtils::applyNextTransformationToContent(struct3["todo"][0])
            struct3["todo"][0] = NSXLucilleCalendarFileUtils::recursivelyRemoveEmptyLineIfInSecondPosition(struct3["todo"][0])
        end
        struct3 = NSXLucilleCalendarFileUtils::struct3TransformUpdatePartsWithTodo(struct3)
        struct3
    end

    # NSXLucilleCalendarFileUtils::commitStruct3ToDiskAtFilepath(struct3, filepath)
    def self.commitStruct3ToDiskAtFilepath(struct3, filepath)
        File.open(filepath, "w") {|f| f.puts(struct3["parts"].join("\n\n")) }
    end

    # NSXLucilleCalendarFileUtils::applyNextTransformationToFilepath(filepath)
    def self.applyNextTransformationToFilepath(filepath)
        return if !File.exists?(filepath)
        CatalystCommon::copyLocationToCatalystBin(filepath)
        struct3 = NSXLucilleCalendarFileUtils::lucilleFilepathToStruct3(filepath)
        struct3 = NSXLucilleCalendarFileUtils::struct3TransformApplyNextTransformationToStruct3(struct3)
        NSXLucilleCalendarFileUtils::commitStruct3ToDiskAtFilepath(struct3, "/Users/pascal/Desktop/Calendar-#{LucilleCore::timeStringL22()}.txt")
        FileUtils.rm(filepath)
    end

    # NSXLucilleCalendarFileUtils::reduceMultipleStruct3s(struct3s)
    def self.reduceMultipleStruct3s(struct3s)
        init = {
            "parts" => [],
            "todo"  => []
        }
        struct3 = struct3s.reduce(init){|struct3acc, struct3item|
            struct3item["parts"].each{|part|
                if !struct3acc["parts"].include?(part) then
                    struct3acc["parts"] << part
                end
            }
            struct3acc
        }
        todo = struct3["parts"]
            .select{|part| part.include?(LUCILLE_CALENDAR_FILE_TODO_WORK_PART_PATTERN) }
            .map{|part| part.lines.drop(1).join() }
            .map{|part| SectionsType0141::contentToSections(part.lines.to_a) }
            .flatten
            .map{|section| section.strip }
        struct3["todo"] = todo
        struct3 = NSXLucilleCalendarFileUtils::struct3TransformUpdatePartsWithTodo(struct3)
        struct3
    end

    # NSXLucilleCalendarFileUtils::reduceMultipleFilesIntoOne(filepaths)
    def self.reduceMultipleFilesIntoOne(filepaths)
        binArchivesFolderpath = CatalystCommon::newBinArchivesFolderpath()
        filepaths.each{|filepath|
            FileUtils.cp(filepath, "#{binArchivesFolderpath}/#{File.basename(filepath)}")
        }
        struct3s = filepaths.map{|filepath| NSXLucilleCalendarFileUtils::lucilleFilepathToStruct3(filepath) }
        struct3 = NSXLucilleCalendarFileUtils::reduceMultipleStruct3s(struct3s)
        NSXLucilleCalendarFileUtils::commitStruct3ToDiskAtFilepath(struct3, "/Users/pascal/Desktop/Calendar-#{LucilleCore::timeStringL22()}.txt")
        filepaths.each{|filepath|
            FileUtils.rm(filepath)
        }
    end

    # NSXLucilleCalendarFileUtils::reduceFilesToOneIfMultiple()
    def self.reduceFilesToOneIfMultiple()
        filepaths = NSXLucilleCalendarFileUtils::lucilleCalendarFilepaths()
        return if filepaths.size < 2
        NSXLucilleCalendarFileUtils::reduceMultipleFilesIntoOne(filepaths)
    end

    # NSXLucilleCalendarFileUtils::lucilleCalendarFilename()
    def self.lucilleCalendarFilename()
        NSXLucilleCalendarFileUtils::reduceFilesToOneIfMultiple()
        filenames = NSXLucilleCalendarFileUtils::lucilleCalendarFilenames()
        if filenames.size != 1 then
            raise "[error 025bbf08] NSXLucilleCalendarFileUtils::lucilleCalendarFilename()"
        end
        filenames[0]
    end

    # NSXLucilleCalendarFileUtils::getUniqueStruct3FilepathPair()
    def self.getUniqueStruct3FilepathPair()
        filename = NSXLucilleCalendarFileUtils::lucilleCalendarFilename()
        filepath = "/Users/pascal/Desktop/#{filename}"
        {
            "struct3" => NSXLucilleCalendarFileUtils::lucilleFilepathToStruct3(filepath),
            "filepath" => filepath
        }
    end

    # NSXLucilleCalendarFileUtils::recursivelyRemoveEmptyLineIfInSecondPosition(text)
    def self.recursivelyRemoveEmptyLineIfInSecondPosition(text)
        lines = text.lines.to_a
        return text if lines.size <= 2
        if lines[1].strip.size==0 then
            lines[1] = nil
            text = lines.compact.join()
            return NSXLucilleCalendarFileUtils::recursivelyRemoveEmptyLineIfInSecondPosition(text)
        end
        text
    end

end
