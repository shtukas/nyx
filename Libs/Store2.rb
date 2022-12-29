# encoding: UTF-8

# Store2 is a sets store

class Store2 

    # Store2::repositoryFolderPath()
    def self.repositoryFolderPath()
        "#{Config::pathToDataCenter()}/Store2"
    end

    # Store2::putElementAtSet(setId, elementId)
    def self.putElementAtSet(setId, elementId)
        setfolderpath = "#{Store2::repositoryFolderPath()}/#{setId}"
        if !File.exists?(setfolderpath) then
            FileUtils.mkdir(setfolderpath)
        end
        elementfilepath = "#{setfolderpath}/#{elementId}"
        return if File.exists?(elementfilepath)
        FileUtils.touch(elementfilepath)
    end

end
