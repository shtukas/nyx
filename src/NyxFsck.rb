
# encoding: UTF-8

class NyxFsck

    # NyxFsck::processNGX15(datapoint)
    def self.processNGX15(datapoint)
        code = datapoint["ngx15"]
        puts "Finding #{code}"
        location = GalaxyFinder::uniqueStringToLocationOrNull(code)
        if location.nil? then
            puts "Failing to find: #{code}"
            puts JSON.pretty_generate(datapoint)
            puts "[error: 76957559-8830-400d-b4fb-6e00081446a0]"
            return false
        end
        return true
    end

    # NyxFsck::processQuark(quark)
    def self.processQuark(quark)
        leptonfilename = quark["leptonfilename"]
        leptonfilepath = LeptonsFunctions::leptonFilenameToFilepath(leptonfilename)
        File.exists?(leptonfilepath)
    end

    # NyxFsck::processObject(object, runhash)
    def self.processObject(object, runhash)

        if object["nyxNxSet"] == "b66318f4-2662-4621-a991-a6b966fb4398" then
            # Asteroid
            puts "fsck asteroid: #{object["uuid"]}"
            return true
        end

        if object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4" then
            # Wave
            puts "fsck wave: #{object["uuid"]}"
            return true
        end

        if object["nyxNxSet"] == "0f555c97-3843-4dfe-80c8-714d837eba69" then
            # Datapoint
            puts "fsck NGX15: #{object["uuid"]}"
            return NyxFsck::processNGX15(object)
        end

        if object["nyxNxSet"] == "d65674c7-c8c4-4ed4-9de9-7c600b43eaab" then
            # Quark
            puts "fsck quark: #{object["uuid"]}"
            return NyxFsck::processQuark(object)
        end

        if object["nyxNxSet"] == "abb20581-f020-43e1-9c37-6c3ef343d2f5" then
            # OpsNode
            puts "fsck operational listing: #{object["uuid"]}"
            return true
        end

        if object["nyxNxSet"] == "f1ae7449-16d5-41c0-a89e-f2a8e486cc99" then
            # EncyclopaediaNode
            puts "fsck encyclopaedia node: #{object["uuid"]}"
            return true
        end

        if object["nyxNxSet"] == "9644bd94-a917-445a-90b3-5493f5f53ffb" then
            # DataContainer
            puts "fsck data container: #{object["uuid"]}"
            return true
        end

        puts JSON.pretty_generate(object)
        puts "[error: eed35593-c378-4715-bbb7-5cbefbcd47ce]"
        false
    end

    # NyxFsck::main(runhash)
    def self.main(runhash)
        NyxObjects2::getAllObjects().each{|object|
            next if KeyValueStore::flagIsTrue(nil, "#{runhash}:#{object["uuid"]}")
            status = NyxFsck::processObject(object, runhash)
            return false if !status
            KeyValueStore::setFlagTrue(nil, "#{runhash}:#{object["uuid"]}")
        }
        true
    end
end
