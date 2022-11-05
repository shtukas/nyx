
# encoding: UTF-8

class Nx8

    # Nx8::fsck(item)
    def self.fsck(item)
        if item["mikuType"] != "Nx8" then
            raise "Incorrect mikuType for function"
        end
        if item["locations"].nil? then
            raise "Could not find the `locations` attribute" 
        end
        item["locations"].each{|filepath|
            filepath = Nx8::addGalaxyPrefixToLocation(filepath)
            if !File.exists?(filepath) then
                raise "Location '#{filepath}' not found in #{JSON.pretty_generate(item)}"
            end
            nx7 = Nx5Ext::readFileAsAttributesOfObject(filepath)
            if item["uuid"] != nx7["uuid"] then
                raise "Location '#{filepath}' is pointing at a different uuid than the one in #{JSON.pretty_generate(item)}"
            end
        }
    end

    # Nx8::removeGalaxyPrefixFromLocation(location)
    def self.removeGalaxyPrefixFromLocation(location)
        location
            .gsub(Config::pathToGalaxy(), "")
    end

    # Nx8::addGalaxyPrefixToLocation(location)
    def self.addGalaxyPrefixToLocation(location)
        "#{Config::pathToGalaxy()}/#{location}"
    end

    # -----------------------------------------------------------------
    # IO

    # Nx8::items()
    def self.items()
        folderpath = "#{Config::pathToDataCenter()}/Nx8"
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # Nx8::commit(item)
    def self.commit(item)
        item["locations"] = item["locations"]
                                .select{|filepath| File.exists?(Nx8::addGalaxyPrefixToLocation(filepath)) }
        #puts "item: #{JSON.pretty_generate(item)}"
        Nx8::fsck(item)
        filepath = "#{Config::pathToDataCenter()}/Nx8/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # Nx8::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        filepath = "#{Config::pathToDataCenter()}/Nx8/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # -----------------------------------------------------------------
    # Data

    # Nx8::toString(item)
    def self.toString(item)
        "(node) #{item["description"]}"
    end

    # -----------------------------------------------------------------
    # Operations

    # Nx8::landing(nx8)
    def self.landing(nx8)
        nx7 = Nx7::getItemOrNull(nx8["uuid"])
        if nx7.nil? then
            puts "I could not find a Nx7 for Nx8, description: '#{nx8["description"]}'"
            LucilleCore::pressEnterToContinue()
            return
        end
        Nx7::landing(nx7)
    end

    # Nx8::syncLocations(nx8)
    def self.syncLocations(nx8)
        nx8["locations"]
            .map{|location| Nx8::addGalaxyPrefixToLocation(location) }
            .combination(2)
            .to_a
            .each{|filepath1, filepath2|
                if Nx7::nx7InstanceIsOpen(filepath1) and Nx7::nx7InstanceIsOpen(filepath2) then
                    puts "I have the same Nx7 open twice!"
                    puts "    filepath1: #{filepath1}"
                    puts "    filepath2: #{filepath2}"
                    exit
                end
            }

        nx8["locations"]
            .map{|location| Nx8::addGalaxyPrefixToLocation(location) }
            .combination(2)
            .to_a
            .each{|filepath1, filepath2|
                if Nx7::nx7InstanceIsOpen(filepath1) or Nx7::nx7InstanceIsOpen(filepath2) then
                    return
                end
            }

        nx8["locations"]
            .map{|location| Nx8::addGalaxyPrefixToLocation(location) }
            .combination(2)
            .to_a
            .each{|filepath1, filepath2|
                Nx5Ext::contentsMirroring(filepath1, filepath2)
            }
    end

    # Nx8::updateNx8FromNx7(nx7Filepath, verbose)
    def self.updateNx8FromNx7(nx7Filepath, verbose)
        nx7 = Nx5Ext::readFileAsAttributesOfObject(nx7Filepath)
        nx8 = Nx8::getItemOrNull(nx7["uuid"])
        if nx8.nil? then
            nx8 = nx7
            nx8["mikuType"] = "Nx8"
            nx8["locations"] = [Nx8::removeGalaxyPrefixFromLocation(nx7Filepath)]
            if verbose then
                puts "nx7Filepath: #{nx7Filepath}"
                puts "Creating a new Nx8"
                puts JSON.pretty_generate(nx8)
            end
            Nx8::commit(nx8)
            return
        end
        nx8["locations"] = (nx8["locations"] + [Nx8::removeGalaxyPrefixFromLocation(nx7Filepath)]).uniq
        if verbose then
            puts "nx7Filepath: #{nx7Filepath}"
            puts "locations: #{JSON.pretty_generate(nx8["locations"])}"
        end
        Nx8::commit(nx8)
        Nx8::syncLocations(nx8)
    end

    # Nx8::updateNx8WithLocations(uuid, locations)
    def self.updateNx8WithLocations(uuid, locations)
        nx8 = Nx8::getItemOrNull(uuid)
        return if nx8.nil?
        nx8["locations"] = (nx8["locations"] + locations.map{|location| Nx8::removeGalaxyPrefixFromLocation(location) }).uniq
        Nx8::commit(nx8)
        Nx8::syncLocations(nx8)
    end

    # Nx8::scanGalaxyAndUpdate(verbose)
    def self.scanGalaxyAndUpdate(verbose)
        Find.find(Config::pathToGalaxy()) do |path|
            if path[-4, 4] == ".Nx7" then
                filepath1 = path
                if verbose then
                    puts "Nx8::scanGalaxyAndUpdate(#{verbose}), filepath1: #{filepath1}"
                end
                Nx8::updateNx8FromNx7(filepath1, verbose)
            end
        end
    end
end
