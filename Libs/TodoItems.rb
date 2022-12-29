# encoding: UTF-8

# Store2 is a sets store

class TodoItems

    # TodoItems::repositoryFolderPath()
    def self.repositoryFolderPath()
        "#{Config::pathToDataCenter()}/TodoItems"
    end

    # TodoItems::putObjectAtSet(setId, object)
    def self.putObjectAtSet(setId, object)
        setfolderpath = "#{TodoItems::repositoryFolderPath()}/#{setId}"
        if !File.exists?(setfolderpath) then
            FileUtils.mkdir(setfolderpath)
        end
        if object["uuid"].nil? then
            puts "You are trying to put object #{object} at set '#{setId}', but object doesn't have an uuid"
            raise "(error: 2331)"
        end
        objectfilepath = "#{setfolderpath}/#{object["uuid"]}"
        File.open(objectfilepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }
    end

end
