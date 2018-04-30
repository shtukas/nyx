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

require_relative "Commons.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

# -------------------------------------------------------------------------------------

TODAY_PATH_TO_DATA_FILE = "/Galaxy/DataBank/Today+Calendar.txt"

# Today::section_is_not_empty(section)
# Today::contents_to_sections(reminaing_lines,sections)
# Today::section_to_string(section)
# Today::section_to_uuid(section)
# Today::sectionToLength8UUID(section)
# Today::todaySectionsUUIDs()
# Today::removeSectionFromFile(uuid)
# Today::getCatalystObjects()

class Today

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
            targetFolder = "#{CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y-%m")}/#{time.strftime("%Y-%m-%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}/"
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

    def self.getCatalystObjects()
        objects = []
        todaycontents = IO.read(TODAY_PATH_TO_DATA_FILE).split('@calendar')[0].strip
        Today::contents_to_sections(todaycontents.lines.to_a,[]).each_with_index{|section,idx|
            uuid = Today::sectionToLength8UUID(section)
            metric = 0.840 + 0.010*Math.exp(-idx.to_f/10)
            announce = section.size>1 ? "today:\n#{section.first(4).map{|line| "        #{line}" }.join}".strip : "today: #{section.first}".strip
            objects << {
                "uuid" => uuid,
                "metric" => metric,
                "announce" => announce,
                "commands" => ['done'],
                "command-interpreter" => lambda{|object, command|
                    if command=='done' then
                        Today::removeSectionFromFile(object['uuid'])
                    end
                }
            }
        }  
        objects
    end

end
