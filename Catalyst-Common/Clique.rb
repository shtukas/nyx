
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

require_relative "Catalyst-Common.rb"

# -----------------------------------------------------------------

class Clique

    # Clique::pathToCliques()
    def self.pathToCliques()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Cliques/Items"
    end

    # Clique::cliques()
    def self.cliques()
        Dir.entries(Clique::pathToCliques())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{Clique::pathToCliques()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|c1, c2| c1["creationtime"] <=> c2["creationtime"] }
    end

    # Clique::getCliqueByUUIDOrNUll(uuid)
    def self.getCliqueByUUIDOrNUll(uuid)
        filepath = "#{Clique::pathToCliques()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Clique::save(clique)
    def self.save(clique)
        uuid = clique["uuid"]
        File.open("#{Clique::pathToCliques()}/#{uuid}.json", "w"){|f| f.puts(JSON.pretty_generate(clique)) }
    end

    # Clique::destroy(clique)
    def self.destroy(clique)
        uuid = clique["uuid"]
        filepath = "#{Clique::pathToCliques()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # Clique::makeClique(uuid, description, items)
    def self.makeClique(uuid, description, items)
        {
            "uuid"         => uuid,
            "creationtime" => Time.new.to_f,
            "description"  => description,
            "items"        => items
        }
    end

    # Clique::issueClique(uuid, description, items)
    def self.issueClique(uuid, description, items)
        clique = Clique::makeClique(uuid, description, items)
        Clique::save(clique)
    end

    # Clique::selectCliqueOrNull()
    def self.selectCliqueOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("clique:", Clique::cliques(), lambda {|clique| clique["description"] })
    end

end



