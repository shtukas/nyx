
# encoding: UTF-8

$AlexandraDidactSynchronizationCatalystDataRsync = <<COMMAND
/usr/local/bin/rsync --xattrs --times --recursive --omit-dir-times --links --hard-links --delete --delete-excluded --verbose --human-readable --itemize-changes \
    "/Users/pascal/Galaxy/DataBank/Didact/Catalyst/" \
    "/Volumes/Infinity/Data/Pascal/Ur-Didact/Catalyst"
COMMAND

$AlexandraDidactSynchronizationNyxDataRsync = <<COMMAND
/usr/local/bin/rsync --xattrs --times --recursive --omit-dir-times --links --hard-links --delete --delete-excluded --verbose --human-readable --itemize-changes \
    "/Users/pascal/Galaxy/DataBank/Didact/Nyx/" \
    "/Volumes/Infinity/Data/Pascal/Ur-Didact/Nyx"
COMMAND

class AlexandraDidactSynchronization

    # AlexandraDidactSynchronization::run()
    def self.run()

        # At the moment, objects are held in a sqlite database. We simply override it.
        puts "Update objects database on drive"
        FileUtils.cp(Librarian6ObjectsLocal::databaseFilepath(), Librarian7ObjectsInfinity::databaseFilepath())

        puts "Rsync Catalyst data"
        system($AlexandraDidactSynchronizationCatalystDataRsync) or raise "(error: 7bf44899-8bb2-47f2-be7b-c38e95b8543c)"

        puts "Rsync Nyx data"
        system($AlexandraDidactSynchronizationNyxDataRsync) or raise "(error: bc0ee679-d4cf-4efc-8ebf-bc5d83150bfe)"

        puts "Process DatablobsInfinityBufferOut"
        Find.find("#{Config::pathToLocalDidact()}/DatablobsInfinityBufferOut") do |path|
            next if !File.file?(path)
            next if path[-5, 5] != ".data"
            puts "Uploading blob: #{path}"
            blob = IO.read(path)
            InfinityFsckBlobsService::putBlob(blob)
            FileUtils.rm(path)
        end

    end
end