#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'json'
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
require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
require_relative "Commons.rb"
# -------------------------------------------------------------------------------------

TODAY_PATH_TO_DATA_FILE = "/Users/pascal/Desktop/Today+Calendar.txt"

# Today::section_is_not_empty(section)
# Today::contents_to_sections(reminaing_lines,sections)
# Today::section_to_string(section)
# Today::section_to_uuid(section)
# Today::sectionToLength8UUID(section)
# Today::todaySectionsUUIDs()
# Today::removeSectionFromFile(uuid)
# Today::flockGeneralUpgrade(flock)

class Today

    def self.agentuuid()
        "f989806f-dc62-4942-b484-3216f7efbbd9"
    end

    # -------------------------------------------------------------------------------------
    def self.section_is_not_empty(section)
        section.any?{|line| line.strip.size>0 }
    end

    def self.contents_to_sections(reminaing_lines, sections)
        return sections.select{|section| Today::section_is_not_empty(section) } if reminaing_lines.size==0
        line = reminaing_lines.shift
        if line.start_with?('[]') then
            sections << [line]
            return Today::contents_to_sections(reminaing_lines,sections)
        end
        sections = [[]] if sections.size==0
        sections.last << line
        Today::contents_to_sections(reminaing_lines,sections)
    end

    def self.section_to_string(section)
        section.join().strip
    end

    def self.section_to_uuid(section)
        Digest::SHA1.hexdigest Today::section_to_string(section)
    end

    # -------------------------------------------------------------------------------------
    def self.sectionToLength8UUID(section)
        Today::section_to_uuid(section)[0, 8]
    end

    def self.todaySectionsUUIDs()
        todaycontents = IO.read(TODAY_PATH_TO_DATA_FILE).split('@calendar')[0].strip
        Today::contents_to_sections(todaycontents.lines.to_a,[]).map{|section|
            Today::sectionToLength8UUID(section)
        }
    end

    def self.removeSectionFromFile(uuid)
        if Today::todaySectionsUUIDs().include?(uuid) then
            time = Time.new
            targetFolder = "#{CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}/"
            FileUtils.mkpath(targetFolder)
            FileUtils.cp(TODAY_PATH_TO_DATA_FILE,"#{targetFolder}/Today+Calendar.txt")

            todaycontents = IO.read(TODAY_PATH_TO_DATA_FILE).split('@calendar')[0].strip
            calendarcontents = IO.read(TODAY_PATH_TO_DATA_FILE).split('@calendar')[1].strip
            todaysections1 = Today::contents_to_sections(todaycontents.lines.to_a, [])
            todaysections2 = todaysections1.select{|section|
                Today::sectionToLength8UUID(section) != uuid
            }
            File.open(TODAY_PATH_TO_DATA_FILE, 'w') {|f|
                todaysections2.each{|section|
                    f.puts(Today::section_to_string(section))
                }
                f.puts ""
                f.puts "@calendar"
                f.puts ""
                f.puts calendarcontents
            }
        end
    end

    def self.interface()
        
    end

    def self.flockGeneralUpgrade(flock)
        objects = []
        todaycontents = IO.read(TODAY_PATH_TO_DATA_FILE).split('@calendar')[0].strip
        Today::contents_to_sections(todaycontents.lines.to_a,[]).each_with_index{|section,idx|
            uuid = Today::sectionToLength8UUID(section)
            metric = 0.840 + 0.010*Math.exp(-idx.to_f/10)
            announce = "today: #{section.join()}".strip
            objects << {
                "uuid" => uuid,
                "agent-uid" => self.agentuuid(),
                "metric" => metric,
                "announce" => announce,
                "commands" => ['done', ">stream", ">open-projects"],
                "item-data" => {
                    "section" => section.join()
                }
            }
        }
        flock = FlockPureTransformations::removeObjectsFromAgent(flock, self.agentuuid())
        flock["objects"] = flock["objects"] + objects
        [ flock, [] ] # We do not emit any event because the objects are generated on the fly
    end

    def self.upgradeFlockUsingObjectAndCommand(flock, object, command)
        if command=='done' then
            Today::removeSectionFromFile(object['uuid'])
            flock = FlockPureTransformations::removeObjectIdentifiedByUUID(flock, object['uuid'])
        end
        if command=='>stream' then
            return [flock, []]
            description = object["item-data"]["section"]
            folderpath = "#{CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER}/#{LucilleCore::timeStringL22()}"
            FileUtils.mkpath folderpath
            File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
            Today::removeSectionFromFile(object['uuid'])
        end
        if command=='>open-projects' then
            return [flock, []]
            description = object["item-data"]["section"]
            folderpath = "#{CATALYST_COMMON_PATH_TO_OPEN_PROJECTS_DATA_FOLDER}/#{LucilleCore::timeStringL22()}"
            FileUtils.mkpath folderpath
            File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
            Today::removeSectionFromFile(object['uuid'])
        end
        return [flock, []] # we do not need to emit events because the objects are transcient
    end
end