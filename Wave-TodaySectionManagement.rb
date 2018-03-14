#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require 'json'

=begin

  -- reading the string and building the object
     dataset = IO.read($dataset_location)
     JSON.parse(dataset)

  -- printing the string
     file.puts JSON.pretty_generate(dataset)

=end

require 'date'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'find'

require_relative "CatalystCore.rb"

PATH_TO_CALENDAR_FILE = "/Galaxy/DataBank/Today+Calendar.txt"

class TodaySectionManagement

    # -------------------------------------------------------------------------------------
    # TodaySectionManagement::section_is_not_empty(section)
    def self.section_is_not_empty(section)
        section.any?{|line| line.strip.size>0 }
    end

    # TodaySectionManagement::contents_to_sections(reminaing_lines,sections)
    def self.contents_to_sections(reminaing_lines, sections)
        return sections.select{|section| TodaySectionManagement::section_is_not_empty(section) } if reminaing_lines.size==0
        line = reminaing_lines.shift
        if line.start_with?('[]') then
            sections << [line]
            return TodaySectionManagement::contents_to_sections(reminaing_lines,sections)
        end
        sections = [[]] if sections.size==0
        sections.last << line
        TodaySectionManagement::contents_to_sections(reminaing_lines,sections)
    end

    # TodaySectionManagement::section_to_string(section)
    def self.section_to_string(section)
        section.join().strip
    end

    # TodaySectionManagement::section_to_uuid(section)
    def self.section_to_uuid(section)
        Digest::SHA1.hexdigest TodaySectionManagement::section_to_string(section)
    end

    # -------------------------------------------------------------------------------------
    # TodaySectionManagement::sectionToLength8UUID(section)
    def self.sectionToLength8UUID(section)
        TodaySectionManagement::section_to_uuid(section)[0, 8]
    end

    # TodaySectionManagement::ensureFolder(path)
    def self.ensureFolder(path)
        if !File.exists?(path) then
            FileUtils.mkpath(path)
        end        
    end

    # TodaySectionManagement::ensureFileAndContents(path, contents)
    def self.ensureFileAndContents(path, contents)
        if File.exists?(path) and IO.read(path)==contents then
            return 
        end
        File.open(path, 'w') {|f| f.write(contents) }
    end

    # TodaySectionManagement::ensureFileNonContentsOverride(path, contents)
    def self.ensureFileNonContentsOverride(path, contents)
        if File.exists?(path) then
            return 
        end
        File.open(path, 'w') {|f| f.write(contents) }
    end

    # TodaySectionManagement::todayPlusCalendarFileSectionsUUIDs()
    def self.todayPlusCalendarFileSectionsUUIDs()
        todaycontents = IO.read(PATH_TO_CALENDAR_FILE).split('@calendar')[0].strip
        TodaySectionManagement::contents_to_sections(todaycontents.lines.to_a,[]).map{|section|
            TodaySectionManagement::sectionToLength8UUID(section)
        }
    end

    # TodaySectionManagement::foldersUUIDs()
    def self.foldersUUIDs()
        todayPlusCalendarRoot = "/Galaxy/DataBank/Catalyst/Wave/02-OpsLine-Active/Today+Calendar-Items"
        Dir.entries(todayPlusCalendarRoot).select{|filename| filename[0, 1] != '.' }
    end

    # TodaySectionManagement::performSync()
    def self.performSync()
        todayPlusCalendarRoot = "/Galaxy/DataBank/Catalyst/Wave/02-OpsLine-Active/Today+Calendar-Items"
        
        # ----------------------------------------------------------------
        todaycontents = IO.read(PATH_TO_CALENDAR_FILE).split('@calendar')[0].strip
        TodaySectionManagement::contents_to_sections(todaycontents.lines.to_a,[]).each_with_index{|section,idx|
            uuid = TodaySectionManagement::sectionToLength8UUID(section)
            TodaySectionManagement::ensureFolder("#{todayPlusCalendarRoot}/#{uuid}")
            TodaySectionManagement::ensureFileAndContents("#{todayPlusCalendarRoot}/#{uuid}/catalyst-uuid",uuid)
            if File.exists?("#{todayPlusCalendarRoot}/#{uuid}/catalyst-schedule.json") and ( schedule = JSON.parse(IO.read("#{todayPlusCalendarRoot}/#{uuid}/catalyst-schedule.json")) ) and schedule['do-not-show-until-datetime'] and (schedule['do-not-show-until-datetime'] > Time.new.to_s) then

            else
                schedule = {
                  "uuid"     => "(#{uuid})",
                  "type"     => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
                  "@"        => "new",
                  "unixtime" => 1510077314,
                  "metric"   => 1.300 + Math.atan(-idx)/1000,
                  "default-commands" => ['+0.666 hours']
                }
                TodaySectionManagement::ensureFileNonContentsOverride("#{todayPlusCalendarRoot}/#{uuid}/catalyst-schedule.json", JSON.pretty_generate(schedule))
            end

            TodaySectionManagement::ensureFileAndContents("#{todayPlusCalendarRoot}/#{uuid}/catalyst-description.txt", section.join)
            TodaySectionManagement::ensureFileAndContents("#{todayPlusCalendarRoot}/#{uuid}/catalyst-origin.txt", 'Today+Calendar')
        }

        # ----------------------------------------------------------------
        (TodaySectionManagement::foldersUUIDs() - TodaySectionManagement::todayPlusCalendarFileSectionsUUIDs()).each{|uuid|
            LucilleCore::removeFileSystemLocation("#{todayPlusCalendarRoot}/#{uuid}")
        }
    end

    # TodaySectionManagement::removeSectionFromFile(uuid)
    def self.removeSectionFromFile(uuid)
        if TodaySectionManagement::todayPlusCalendarFileSectionsUUIDs().include?(uuid) then
            time = Time.new
            targetFolder = "#{WaveTimelineUtils::catalystArchiveOpsLineFolderPath()}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}/"
            FileUtils.mkpath(targetFolder)
            FileUtils.cp(PATH_TO_CALENDAR_FILE,"#{targetFolder}/Today+Calendar.txt")

            todaycontents = IO.read(PATH_TO_CALENDAR_FILE).split('@calendar')[0].strip
            calendarcontents = IO.read(PATH_TO_CALENDAR_FILE).split('@calendar')[1].strip
            todaysections1 = TodaySectionManagement::contents_to_sections(todaycontents.lines.to_a, [])
            todaysections2 = todaysections1.select{|section|
                TodaySectionManagement::sectionToLength8UUID(section) != uuid
            }
            File.open(PATH_TO_CALENDAR_FILE, 'w') {|f| 
                todaysections2.each{|section|
                    f.puts(TodaySectionManagement::section_to_string(section))
                }
                f.puts ""
                f.puts "@calendar"
                f.puts ""
                f.puts calendarcontents
            }
        end
    end
end

