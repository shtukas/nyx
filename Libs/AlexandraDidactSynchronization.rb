
# encoding: UTF-8

$AlexandraDidactSynchronizationCatalystDataRsync = <<COMMAND
/usr/local/bin/rsync --xattrs --times --recursive --omit-dir-times --links --hard-links --delete --delete-excluded --verbose --human-readable --itemize-changes \
    "/Users/pascal/Galaxy/DataBank/Didact/Catalyst/" \
    "/Volumes/Infinity/Data/Pascal/Ur-Didact/Catalyst"
COMMAND

class AlexandraDidactSynchronization

    # AlexandraDidactSynchronization::run()
    def self.run()

        # --------------------------------------------------------------------------------------

        # Tx46 track the state, more exactly the trace, of a Edition Desk location. This is how we detect which ones have been dead for a while and can be deleted
        # Tx46 = {
        #     "name"     : String
        #     "trace"    : String
        #     "unixtime" : String
        # }

        issueNewTx46 = lambda {|location|
            tx46 = {
                "name"     => File.basename(location),
                "trace"    => Utils::locationTrace(location),
                "unixtime" => Time.new.to_i
            }
            XCache::set("5981674c-998c-4275-9890-b33ee4a6486f:#{location}", JSON.generate(tx46))
            tx46
        }

        getLocationTx46 = lambda{|location|
            item = XCache::getOrNull("5981674c-998c-4275-9890-b33ee4a6486f:#{location}")
            if item then
                tx46 = JSON.parse(item)
                trace = Utils::locationTrace(location)
                if tx46["trace"] != trace then
                    issueNewTx46.call(location)
                else
                    tx46
                end
            else
                issueNewTx46.call(location)
            end   
        }

        LucilleCore::locationsAtFolder(EditionDesk::pathToEditionDesk()).each{|location|
            puts "AlexandraDidactSynchronization: Updating item from location: #{File.basename(location)}"
            EditionDesk::updateItemFromDeskLocationOrNothing(location)
            tx46 = getLocationTx46.call(location)
            #puts "tx46: #{JSON.pretty_generate(tx46)}"
            #puts "last change #{(Time.new.to_i - tx46["unixtime"]).to_f/86400} days ago"
            if (Time.new.to_i - tx46["unixtime"]) > 86400*14 then # 2 weeks
                puts "Last change #{(Time.new.to_i - tx46["unixtime"]).to_f/86400} days ago"
                puts "Deleting Edition Desk location: #{File.basename(location)}"
                LucilleCore::removeFileSystemLocation(location)
            end
        }

        # --------------------------------------------------------------------------------------

        # At the moment, objects are held in a sqlite database. We simply override it.
        puts "Update objects database on drive"
        FileUtils.cp(Librarian6ObjectsLocal::databaseFilepath(), Librarian7ObjectsInfinity::databaseFilepath())

        # --------------------------------------------------------------------------------------

        puts "Rsync Catalyst data"
        system($AlexandraDidactSynchronizationCatalystDataRsync) or raise "(error: 7bf44899-8bb2-47f2-be7b-c38e95b8543c)"

        # --------------------------------------------------------------------------------------

        puts "Process DatablobsInfinityBufferOut"
        Find.find("#{Config::pathToLocalDidact()}/DatablobsInfinityBufferOut") do |path|
            next if !File.file?(path)
            next if path[-5, 5] != ".data"
            blob = IO.read(path)
            nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
            if InfinityDatablobs_PureDrive::getBlobOrNull(nhash) then
                FileUtils.rm(path)
                next
            end
            puts "Uploading blob: #{path}"
            InfinityDatablobs_PureDrive::putBlob(blob)
            FileUtils.rm(path)
        end
    end
end
