class SyncConflicts

    # .sync-conflict-20

    # SyncConflicts::getConflictFileOrNull()
    def self.getConflictFileOrNull()
        Find.find(Config::pathToDataCenter()) do |path|
            if path[-9, 9] == ".DS_Store" then
                FileUtils.rm(path)
                next
            end
            if File.basename(path).include?(".sync-conflict-20") and !File.basename(path).start_with?(".") then
                return path
            end
        end
        nil
    end
end
