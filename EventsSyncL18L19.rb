
# encoding: UTF-8

require 'drb/drb'

# EventsSyncL18L19::ping()
# EventsSyncL18L19::sync(): Integer # returns the number of files transfered. 

class EventsSyncL18L19
    def self.ping()
        begin
            DRbObject.new(nil, "druby://Lucille19.local:24868").ping()
        rescue
            "server doesn't seem to be online"
        end
    end
    def self.sync()
        begin
            l19Filepaths = DRbObject.new(nil, "druby://Lucille19.local:24868").filepaths()
            l18Filepaths = EventsManager::filepaths()
            ( l18Filepaths - l19Filepaths ).each{|filepath|
                # Sending the file from L18 to L19
                # puts "Sending   #{filepath}"
                DRbObject.new(nil, "druby://Lucille19.local:24868").l18Tol19(filepath, IO.read(filepath))
            }
            ( l19Filepaths - l18Filepaths ).each{|filepath|
                # Receiving the file from L19 to L18
                # puts "Receiving #{filepath}"
                filecontents = DRbObject.new(nil, "druby://Lucille19.local:24868").l19Tol18(filepath)
                if !File.exists?(File.dirname(filepath)) then
                    FileUtils.mkdir(File.dirname(filepath))
                end
                File.open(filepath, "w"){|f| f.write(filecontents) }
            }
            ( l18Filepaths - l19Filepaths ).size + ( l19Filepaths - l18Filepaths ).size
        rescue
            0
        end
    end
end
