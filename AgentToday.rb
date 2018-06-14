#!/usr/bin/ruby

# encoding: UTF-8
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
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "Today",
        "agent-uid"       => "f989806f-dc62-4942-b484-3216f7efbbd9",
        "general-upgrade" => lambda { AgentToday::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentToday::processObjectAndCommandFromCli(object, command) },
        "interface"       => lambda{ AgentToday::interface() }
    }
)

TODAY_PATH_TO_DATA_FILE = "/Users/pascal/Desktop/Today.txt"
TODAY_SEPARATION_TOKEN = "@notes"

# AgentToday::section_is_not_empty(section)
# AgentToday::contents_to_sections(reminaing_lines,sections)
# AgentToday::section_to_string(section)
# AgentToday::section_to_uuid(section)
# AgentToday::sectionToLength8UUID(section)
# AgentToday::todaySectionsUUIDs()
# AgentToday::removeSectionFromFile(uuid)
# AgentToday::generalFlockUpgrade()

class AgentToday

    def self.agentuuid()
        "f989806f-dc62-4942-b484-3216f7efbbd9"
    end

    # -------------------------------------------------------------------------------------
    def self.section_is_not_empty(section)
        section.any?{|line| line.strip.size>0 }
    end

    def self.contents_to_sections(reminaing_lines, sections)
        return sections.select{|section| AgentToday::section_is_not_empty(section) } if reminaing_lines.size==0
        line = reminaing_lines.shift
        if line.start_with?('[]') then
            sections << [line]
            return AgentToday::contents_to_sections(reminaing_lines,sections)
        end
        sections = [[]] if sections.size==0
        sections.last << line
        AgentToday::contents_to_sections(reminaing_lines,sections)
    end

    def self.section_to_string(section)
        section.join().strip
    end

    def self.section_to_uuid(section)
        Digest::SHA1.hexdigest AgentToday::section_to_string(section)
    end

    # -------------------------------------------------------------------------------------
    def self.sectionToLength8UUID(section)
        AgentToday::section_to_uuid(section)[0, 8]
    end

    def self.todaySectionsUUIDs()
        todaycontents = IO.read(TODAY_PATH_TO_DATA_FILE).split(TODAY_SEPARATION_TOKEN)[0].strip
        AgentToday::contents_to_sections(todaycontents.lines.to_a,[]).map{|section|
            AgentToday::sectionToLength8UUID(section)
        }
    end

    def self.removeSectionFromFile(uuid)
        if AgentToday::todaySectionsUUIDs().include?(uuid) then
            targetFolder = CommonsUtils::newBinArchivesFolderpath()
            FileUtils.cp(TODAY_PATH_TO_DATA_FILE,"#{targetFolder}/#{File.basename(TODAY_PATH_TO_DATA_FILE)}")
            todaycontents = IO.read(TODAY_PATH_TO_DATA_FILE).split(TODAY_SEPARATION_TOKEN)[0].strip
            calendarcontents = IO.read(TODAY_PATH_TO_DATA_FILE).split(TODAY_SEPARATION_TOKEN)[1].strip
            todaysections1 = AgentToday::contents_to_sections(todaycontents.lines.to_a, [])
            todaysections2 = todaysections1.select{|section|
                AgentToday::sectionToLength8UUID(section) != uuid
            }
            File.open(TODAY_PATH_TO_DATA_FILE, 'w') {|f|
                todaysections2.each{|section|
                    f.puts(AgentToday::section_to_string(section))
                }
                f.puts ""
                f.puts "#{TODAY_SEPARATION_TOKEN}"
                f.puts ""
                f.puts calendarcontents
            }
        end
    end

    def self.interface()
        
    end

    def self.generalFlockUpgrade()
        objects = []
        todaycontents = IO.read(TODAY_PATH_TO_DATA_FILE).split(TODAY_SEPARATION_TOKEN)[0].strip
        AgentToday::contents_to_sections(todaycontents.lines.to_a,[]).each_with_index{|section,idx|
            uuid = AgentToday::sectionToLength8UUID(section)
            metric = 0.840 + 0.010*Math.exp(-idx.to_f/10)
            announce = "today: #{section.join()}".strip
            objects << {
                "uuid" => uuid,
                "agent-uid" => self.agentuuid(),
                "metric" => metric,
                "announce" => announce,
                "commands" => ['done', ">stream"],
                "item-data" => {
                    "section" => section.join()
                }
            }
        }
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        TheFlock::addOrUpdateObjects(objects)
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command=='done' then
            AgentToday::removeSectionFromFile(object['uuid'])
        end
        if command=='>stream' then
            return []
            description = object["item-data"]["section"]
            folderpath = "#{CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER}/#{LucilleCore::timeStringL22()}"
            FileUtils.mkpath folderpath
            File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
            AgentToday::removeSectionFromFile(object['uuid'])
        end
    end
end