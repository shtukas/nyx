
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

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

    # Projects::makeProject(uuid, description, items)
    def self.makeProject(uuid, description, items)
        {
            "uuid"         => uuid,
            "creationtime" => Time.new.to_f,
            "description"  => description,
            "items"        => items
        }
    end

    # Projects::issueProject(uuid, description, items)
    def self.issueProject(uuid, description, items)
        item = Projects::makeProject(uuid, description, items)
        Projects::save(item)
    end

    # Projects::selectProjectOrNull()
    def self.selectProjectOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("item:", Projects::items(), lambda {|item| item["description"] })
    end

end



