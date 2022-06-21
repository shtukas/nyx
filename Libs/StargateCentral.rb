class StargateCentral

    # StargateCentral::pathToCentral()
    def self.pathToCentral()
        "/Volumes/Infinity/Data/Pascal/Stargate-Central"
    end

    # StargateCentral::pathToEventStreamFile()
    def self.pathToEventStreamFile()
        "#{StargateCentral::pathToCentral()}/event-stream.sqlite3"
    end

    # -----------------------------------------------------------------
    # Datablobs

    # StargateCentral::propagateDatablobs(folderpath1, folderpath2)
    def self.propagateDatablobs(folderpath1, folderpath2)
        Find.find(folderpath1) do |path|
            next if File.basename(path)[-5, 5] != ".data"
            filename = File.basename(path)
            targetfolderpath = "#{folderpath2}/#{filename[7, 2]}"
            targetfilepath = "#{targetfolderpath}/#{filename}"
            next if File.exist?(targetfilepath)
            if !File.exists?(targetfolderpath) then
                FileUtils.mkdir(targetfolderpath)
            end
            puts "copying datablob: #{filename}"
            FileUtils.cp(path, targetfilepath)
        end
    end

    # StargateCentral::propagateDatablobsWithPrimaryDeletion(folderpath1, folderpath2)
    def self.propagateDatablobsWithPrimaryDeletion(folderpath1, folderpath2)
        Find.find(folderpath1) do |path|
            next if File.basename(path)[-5, 5] != ".data"
            filename = File.basename(path)
            targetfolderpath = "#{folderpath2}/#{filename[7, 2]}"
            targetfilepath = "#{targetfolderpath}/#{filename}"
            if File.exist?(targetfilepath) then
                FileUtils.rm(path)
                next
            end
            if !File.exists?(targetfolderpath) then
                FileUtils.mkdir(targetfolderpath)
            end
            puts "copying datablob: #{filename}"
            FileUtils.cp(path, targetfilepath)
            FileUtils.rm(path)
        end
    end

    # -----------------------------------------------------------------
    # EventLog

    # StargateCentral::writeEventToStream(uuid, unixtime, event)
    def self.writeEventToStream(uuid, unixtime, event)
        #puts "StargateCentral::writeEventToStream(#{uuid}, #{unixtime}, #{JSON.pretty_generate(event)})"
        db = SQLite3::Database.new(StargateCentral::pathToEventStreamFile())
        db.execute "delete from _events_ where _uuid_=?", [uuid]
        db.execute "insert into _events_ (_uuid_, _unixtime_, _event_) values (?, ?, ?)", [uuid, unixtime, JSON.generate(event)]
        db.close
    end

    # StargateCentral::getRecords()
    def self.getRecords()
        db = SQLite3::Database.new(StargateCentral::pathToEventStreamFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _events_ order by _unixtime_=?") do |row|
            answer << row
        end
        db.close
        answer
    end

    # StargateCentral::deleteRecord(uuid)
    def self.deleteRecord(uuid)
        db = SQLite3::Database.new(OutGoingEventsToCentral::pathToDatabaseFile())
        db.execute "delete from _events_ where _uuid_=?", [uuid]
        db.close
    end
end
