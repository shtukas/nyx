class StargateCentral

    # StargateCentral::pathToCentral()
    def self.pathToCentral()
        "/Volumes/Infinity/Data/Pascal/Stargate-Central"
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

    # StargateCentral::syncDatablobs()
    def self.syncDatablobs()
        puts "Data Propagation (LocalDatablobsBufferOut to StargateCentral)"
        StargateCentral::propagateDatablobsWithPrimaryDeletion(LocalDatablobsBufferOut::repositoryFolderpath(), "#{StargateCentral::pathToCentral()}/DatablobsDepth1")
    end

    # -----------------------------------------------------------------
    # EventLog

    # StargateCentral::propagateEventLog(folderpath1, folderpath2)
    def self.propagateEventLog(folderpath1, folderpath2)
        Find.find(folderpath1) do |path|
            next if File.basename(path)[-11, 11] != ".event.json"
            filename = File.basename(path)
            indexname = File.basename(File.dirname(path))
            targetfolderpath = "#{folderpath2}/#{indexname}"
            targetfilepath = "#{targetfolderpath}/#{filename}"
            next if File.exist?(targetfilepath)
            if !File.exists?(targetfolderpath) then
                FileUtils.mkdir(targetfolderpath)
            end
            puts "copying event: #{filename}"
            FileUtils.cp(path, targetfilepath)
        end
    end

    # StargateCentral::syncEventLogs()
    def self.syncEventLogs()

        puts "Events Propagation (LocalEventLog to StargateCentral)"
        StargateCentral::propagateEventLog(EventLog::pathToLocalEventLog(), "#{StargateCentral::pathToCentral()}/EventLog")

        puts "Events Propagation (StargateCentral to LocalEventLog)"
        StargateCentral::propagateEventLog("#{StargateCentral::pathToCentral()}/EventLog", EventLog::pathToLocalEventLog())
    end
end
