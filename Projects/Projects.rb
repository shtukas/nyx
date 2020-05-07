
# encoding: UTF-8

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

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require_relative "../Catalyst-Common/Catalyst-Common.rb"

# -----------------------------------------------------------------

class Projects

    # Projects::pathToProjects()
    def self.pathToProjects()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Projects/Items"
    end

    # Projects::items()
    def self.items()
        Dir.entries(Projects::pathToProjects())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{Projects::pathToProjects()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|c1, c2| c1["creationtime"] <=> c2["creationtime"] }
    end

    # Projects::getProjectByUUIDOrNUll(uuid)
    def self.getProjectByUUIDOrNUll(uuid)
        filepath = "#{Projects::pathToProjects()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Projects::save(item)
    def self.save(item)
        uuid = item["uuid"]
        File.open("#{Projects::pathToProjects()}/#{uuid}.json", "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # Projects::destroy(item)
    def self.destroy(item)
        uuid = item["uuid"]
        filepath = "#{Projects::pathToProjects()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # Projects::makeProject(uuid, description, schedule, items)
    def self.makeProject(uuid, description, schedule, items)
        {
            "uuid"         => uuid,
            "creationtime" => Time.new.to_f,
            "description"  => description,
            "schedule" => schedule,
            "items"        => items
        }
    end

    # Projects::issueProject(uuid, description, schedule, items)
    def self.issueProject(uuid, description, schedule, items)
        item = Projects::makeProject(uuid, description, schedule, items)
        Projects::save(item)
    end

    # Projects::selectProjectOrNull()
    def self.selectProjectOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("item:", Projects::items(), lambda {|item| item["description"] })
    end

    # -----------------------------------------------------------
    # Run Management

    # Projects::isRunning(uuid)
    def self.isRunning(uuid)
        !KeyValueStore::getOrNull(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}").nil?
    end

    # Projects::runTimeInSecondsOrNull(uuid)
    def self.runTimeInSecondsOrNull(uuid)
        unixtime = KeyValueStore::getOrNull(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}")
        return nil if unixtime.nil?
        Time.new.to_f - unixtime.to_f
    end

    # Projects::start(uuid)
    def self.start(uuid)
        return if Projects::isRunning(uuid)
        KeyValueStore::set(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}", Time.new.to_i)
    end

    # Projects::stop(uuid)
    def self.stop(uuid)
        return if !Projects::isRunning(uuid)
        unixtime = KeyValueStore::getOrNull(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}").to_i
        unixtime = unixtime.to_f
        timespan = Time.new.to_f - unixtime
        timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
        timepoint = {
            "uuid"     => SecureRandom.uuid,
            "unixtime" => Time.new.to_i,
            "timespan" => timespan
        }
        BTreeSets::set(nil, "acc68599-2249-42fc-b6dd-f7db287c73db:#{uuid}", timepoint["uuid"], timepoint)
        KeyValueStore::destroy(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}")
    end

    # Projects::getTimepoints(uuid)
    def self.getTimepoints(uuid)
        BTreeSets::values(nil, "acc68599-2249-42fc-b6dd-f7db287c73db:#{uuid}")
    end

    # Projects::getTimepointsOverThePastNSeconds(uuid, n)
    def self.getTimepointsOverThePastNSeconds(uuid, n)
        timepoints = Projects::getTimepoints(uuid)
        timepoints.select{|timepoint| (Time.new.to_f - timepoint["unixtime"]) <= n  }
    end

    # -----------------------------------------------------------
    # Catalyst Objects Support

end



