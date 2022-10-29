# encoding: UTF-8

class GridFire

    # GridFire::exportObjectAtLocation(object, location)
    def self.exportObjectAtLocation(object, location)
        state = object["states"].last
        GridState::exportStateAtFolder(object["states"].last, location)
    end

    # GridFire::exportChildrenAtLocation(object, location)
    def self.exportChildrenAtLocation(object, location)
        Nx7::children(object).each{|child|
            description = child["description"]
            safedescription = CommonUtils::sanitiseStringForFilenaming(description)
            filename = "#{safedescription}.nyx7"
            filepath = "#{location}/#{filename}"
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(child))}
        }
    end

    # GridFire::processNyx7(filepath1)
    def self.processNyx7(filepath1)
        location2 = filepath1.gsub(".nyx7", "")
        return if !File.exists?(location2)
        object = JSON.parse(IO.read(filepath1))
        object = Nx7::getItemOrNull(object["uuid"])
        if object.nil? then
            puts "I could not find the network equivalent of location1: '#{location1}', uuid: '#{object}'"
            puts "Exiting"
            exit
        end
        if object["states"].last["type"] == "null" and Nx7::children(object).size == 0 then

        end
        if object["states"].last["type"] != "null" and Nx7::children(object).size == 0 then
            GridFire::exportObjectAtLocation(object, location2)
        end
        if object["states"].last["type"] == "null" and Nx7::children(object).size > 0 then
            GridFire::exportChildrenAtLocation(object, location2)
        end
        if object["states"].last["type"] != "null" and Nx7::children(object).size > 0 then
            location3 = "#{location2}-state"
            location4 = "#{location2}-children"
            if !File.exists?(location3) then
                FileUtils.mkdir(location3)
            end
            if !File.exists?(location4) then
                FileUtils.mkdir(location4)
            end
            GridFire::exportObjectAtLocation(object, location3)
            GridFire::exportChildrenAtLocation(object, location4)
        end
    end

    # GridFire::propagateChangesToDiskScanRoot(root)
    def self.propagateChangesToDiskScanRoot(root)
        Find.find(root) do |path|
            if path[-5, 5] == ".nyx7" then
                filepath1 = path
                puts "process: #{filepath1}"
                GridFire::processNyx7(filepath1)
            end
        end
    end

    # GridFire::run()
    def self.run()
        [
            "#{Config::userHomeDirectory()}/Galaxy/DataHub", 
            "#{Config::userHomeDirectory()}/Galaxy/OpenCycles"
        ].each{|root|
            GridFire::propagateChangesToDiskScanRoot(root)
        }
    end
end
