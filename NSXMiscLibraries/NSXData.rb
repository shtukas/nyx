
# encoding: UTF-8

class NSXData

    # ---------------------------------------------------------------
    # Setters

    # NSXData::setWritableValue(datarootfolderpath, id, value)
    def self.setWritableValue(datarootfolderpath, id, value)
        id = Digest::SHA1.hexdigest(id)
        pathfragment = "#{id[0,2]}/#{id[2,2]}"
        filepath = "#{datarootfolderpath}/#{pathfragment}/#{id}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.puts(value) }
    end

    # NSXData::addObjectToSet(datarootfolderpath, setid, object)
    def self.addObjectToSet(datarootfolderpath, setid, object)
        if object["uuid"].nil? then
            puts "The following object doesn't have a uuid"
            puts JSON.generate(object)
            raise "Error: 3179cd5d"
        end
        setid = Digest::SHA1.hexdigest(setid)
        pathfragment1 = "#{setid[0,2]}/#{setid[2,2]}"
        folderpath1 = "#{datarootfolderpath}/#{pathfragment1}/#{setid}-set"
        if !File.exists?(folderpath1) then
            FileUtils.mkpath(folderpath1)
        end
        filename = "#{Digest::SHA1.hexdigest(object["uuid"])}.object"
        pathfragment2 = "#{filename[0,2]}/#{filename[2,2]}"
        folderpath2 = "#{folderpath1}/#{pathfragment2}"
        if !File.exists?(folderpath2) then
            FileUtils.mkpath(folderpath2)
        end
        filepath = "#{folderpath2}/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }
    end

    # ---------------------------------------------------------------
    # Getters

    # NSXData::getValueAsStringOrNull(datarootfolderpath, id)
    def self.getValueAsStringOrNull(datarootfolderpath, id)
        id = Digest::SHA1.hexdigest(id)
        pathfragment = "#{id[0,2]}/#{id[2,2]}"
        filepath = "#{datarootfolderpath}/#{pathfragment}/#{id}.data"
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end

    # NSXData::getValueAsStringOrDefaultValue(datarootfolderpath, id, defaultValue)
    def self.getValueAsStringOrDefaultValue(datarootfolderpath, id, defaultValue)
        value = NSXData::getValueAsStringOrNull(datarootfolderpath, id)
        return defaultValue if value.nil?
        value
    end

    # NSXData::getValueAsIntegerOrNull(datarootfolderpath, id)
    def self.getValueAsIntegerOrNull(datarootfolderpath, id)
        value = NSXData::getValueAsStringOrNull(datarootfolderpath, id)
        return nil if value.nil?
        value.to_i
    end

    # NSXData::getValueAsIntegerOrDefaultValue(datarootfolderpath, id, defaultValue)
    def self.getValueAsIntegerOrDefaultValue(datarootfolderpath, id, defaultValue)
        value = NSXData::getValueAsIntegerOrNull(datarootfolderpath, id)
        return defaultValue if value.nil?
        value
    end

    # NSXData::getValueAsObjectOrNull(datarootfolderpath, id)
    def self.getValueAsObjectOrNull(datarootfolderpath, id)
        value = NSXData::getValueAsStringOrNull(datarootfolderpath, id)
        return nil if value.nil?
        JSON.parse(value)
    end

    # NSXData::getSetObjectsEnumerator(datarootfolderpath, setid)
    def self.getSetObjectsEnumerator(datarootfolderpath, setid)
        setid = Digest::SHA1.hexdigest(setid)
        pathfragment1 = "#{setid[0,2]}/#{setid[2,2]}"
        folderpath1 = "#{datarootfolderpath}/#{pathfragment1}/#{setid}-set"
        if !File.exists?(folderpath1) then
            FileUtils.mkpath(folderpath1)
        end
        Enumerator.new do |objects|
            Find.find(folderpath1) do |path|
                next if !File.file?(path)
                next if File.basename(path)[-7, 7] != '.object'
                objects << JSON.parse(IO.read(path))
            end
        end        
    end

end


