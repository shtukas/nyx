# encoding: UTF-8

# Store2 is a sets store

class TodoItems

    # TodoItems::repositoryFolderPath()
    def self.repositoryFolderPath()
        "#{Config::pathToDataCenter()}/TodoItems"
    end

    # TodoItems::commit(object)
    def self.commit(object)
        filepath = "#{TodoItems::repositoryFolderPath()}/#{object["uuid"]}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }
    end

    # TodoItems::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{TodoItems::repositoryFolderPath()}/#{uuid}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

end
