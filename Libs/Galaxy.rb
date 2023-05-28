
# encoding: UTF-8

class Galaxy

    # Galaxy::locationEnumerator(roots)
    def self.locationEnumerator(roots)
        Enumerator.new do |filepaths|
            roots.each{|root|
                if File.exist?(root) then
                    begin
                        Find.find(root) do |path|
                            next if File.basename(path)[0, 1] == "."
                            next if path.include?("target")
                            next if path.include?("project")
                            next if path.include?("node_modules")
                            next if path.include?("static")
                            filepaths << path
                        end
                    rescue
                    end
                end
            }
        end
    end

    # Galaxy::fsBeaconToFilepathOrNull(beaconId)
    def self.fsBeaconToFilepathOrNull(beaconId)
        roots = [
            "#{Config::userHomeDirectory()}/Galaxy"
        ]
        Galaxy::locationEnumerator(roots).each{|filepath|
            if File.basename(filepath)[-14, 14] == ".nyx.fs-beacon" then
                beacon = JSON.parse(IO.read(filepath))
                if beacon["beaconId"] == beaconId then
                    return filepath
                end
            end
        }
        nil
    end
end
