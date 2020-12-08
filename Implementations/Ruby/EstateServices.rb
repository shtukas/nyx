
# encoding: UTF-8

class EstateServices

    # EstateServices::today()
    def self.today()
        DateTime.now.to_date.to_s
    end

    # EstateServices::getFirstDiveFirstLocationAtLocation(location)
    def self.getFirstDiveFirstLocationAtLocation(location)
        if File.file?(location) then
            location
        else
            locations = Dir.entries(location)
                .select{|filename| filename!='.' and filename!='..' }
                .sort
                .map{|filename| "#{location}/#{filename}" }
            if locations.size==0 then
                location
            else
                locationsdirectories = locations.select{|location| File.directory?(location) }
                if locationsdirectories.size>0 then
                    EstateServices::getFirstDiveFirstLocationAtLocation(locationsdirectories.first)
                else
                    locations.first
                end
            end
        end
    end

    # EstateServices::getLocationFileBiggerThan10MegaBytesOrNull(location)
    def self.getLocationFileBiggerThan10MegaBytesOrNull(location)
        if File.file?(location) then
            if File.size(location) > 1024*1024*10 then
                return location
            else
                return nil
            end
        end
        Dir.entries(location)
            .select{|filename| filename != '.' and filename != '..' }
            .sort
            .map{|filename| "#{location}/#{filename}" }
            .map{|location_| EstateServices::getLocationFileBiggerThan10MegaBytesOrNull(location_) }
            .compact
            .first
    end

    # EstateServices::getFilepathAgeInDays(filepath)
    def self.getFilepathAgeInDays(filepath)
        (Time.new.to_i - File.mtime(filepath).to_i).to_f/86400
    end
end