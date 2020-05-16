
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoints.rb"
=begin
    DataPoints::save(datapoint)
    DataPoints::getOrNull(uuid)
=end

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

# -----------------------------------------------------------------

class DataPoints

    # DataPoints::pathToRepository()
    def self.pathToRepository()
        "/Users/pascal/Galaxy/DataBank/Catalyst/DataPoints"
    end

    # DataPoints::fsckDataPointExplode(datapoint)
    def self.fsckDataPointExplode(datapoint)
        raise "DataPoints::fsckDataPointExplode [uuid] {#{datapoint}}" if datapoint["uuid"].nil?
        raise "DataPoints::fsckDataPointExplode [creationTimestamp] {#{datapoint}}" if datapoint["creationTimestamp"].nil?
        raise "DataPoints::fsckDataPointExplode [description] {#{datapoint}}" if datapoint["description"].nil?
        raise "DataPoints::fsckDataPointExplode [targets] {#{datapoint}}" if datapoint["targets"].nil?
        raise "DataPoints::fsckDataPointExplode [tags] {#{datapoint}}" if datapoint["tags"].nil?
    end

    # DataPoints::save(datapoint)
    def self.save(datapoint)
        DataPoints::fsckDataPointExplode(datapoint)
        filepath = "#{DataPoints::pathToRepository()}/#{datapoint["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(datapoint)) }
    end

    # DataPoints::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{DataPoints::pathToRepository()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

end
