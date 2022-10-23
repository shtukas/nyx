# encoding: UTF-8

class TheBook

    # ---------------------------------------------------
    # READS

    # TheBook::mostRecentBookFilepath(pathToRepository)
    def self.mostRecentBookFilepath(pathToRepository)
        LucilleCore::locationsAtFolder(pathToRepository)
            .select{|filepath| File.basename(filepath).start_with?("01-Book") }
            .sort
            .last
    end

    # TheBook::mostRecentBook(pathToRepository)
    def self.mostRecentBook(pathToRepository)
        JSON.parse(IO.read(TheBook::mostRecentBookFilepath(pathToRepository)))
    end

    # TheBook::mutationFilepaths(pathToRepository)
    def self.mutationFilepaths(pathToRepository)
        LucilleCore::locationsAtFolder(pathToRepository)
            .select{|filepath| File.basename(filepath).start_with?("02-Object") }
            .sort
    end

    # ---------------------------------------------------
    # UPDATES

    # TheBook::markBookFolderAsMutated(pathToRepository)
    def self.markBookFolderAsMutated(pathToRepository)
        LucilleCore::locationsAtFolder(pathToRepository)
            .select{|location| File.basename(location).start_with?("00-Mutation-Mark-#{Config::thisInstanceId()}") }
            .each{|filepath| FileUtils.rm(filepath) }

        filename = "00-Mutation-Mark-#{Config::thisInstanceId()}-#{CommonUtils::timeStringL22()}"
        filepath = "#{pathToRepository}/#{filename}"
        FileUtils.touch(filepath)
    end

    # TheBook::bookingTrace(pathToRepository)
    def self.bookingTrace(pathToRepository)
        LucilleCore::locationsAtFolder(pathToRepository)
            .select{|location| File.basename(location).start_with?("00-Mutation-Mark-#{Config::thisInstanceId()}") }
            .join(":")
    end

    # TheBook::commitBookToDisk(pathToRepository, book)
    def self.commitBookToDisk(pathToRepository, book)
        filepath = "#{pathToRepository}/01-Book-#{CommonUtils::timeStringL22()}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(book)) }

        TheBook::markBookFolderAsMutated(pathToRepository)
    end

    # TheBook::commitMutation(pathToRepository, object)
    def self.commitMutation(pathToRepository, object)
        FileSystemCheck::fsck_MikuTypedItem(object, SecureRandom.hex, false)
        filepath = "#{pathToRepository}/02-Object-#{CommonUtils::timeStringL22()}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }

        TheBook::markBookFolderAsMutated(pathToRepository)
    end

    # TheBook::importsMutations(pathToRepository)
    def self.importsMutations(pathToRepository)
        mutationFilepaths = TheBook::mutationFilepaths(pathToRepository)
        return if mutationFilepaths.empty?

        # The original book
        book1 = TheBook::mostRecentBook(pathToRepository)

        # The book with updates in
        book2 = mutationFilepaths
                    .reduce(book1){|runningbook, filepath|
                        item = JSON.parse(IO.read(filepath))
                        runningbook[item["uuid"]] = item
                        runningbook
                    }

        # The book garbage collected
        book3 = {}
        objects = book2.values.select{|item| item["phage_alive"] }
        objects.each{|object|
            book3[object["uuid"]] = object
        }
        TheBook::commitBookToDisk(pathToRepository, book3)

        # fs garbage collection
        mutationFilepaths.each{|filepath|
            FileUtils.rm(filepath)
        }

        TheBook::markBookFolderAsMutated(pathToRepository)
    end

    # ---------------------------------------------------
    # READS

    # TheBook::mostRecentBookWithMutations(pathToRepository)
    def self.mostRecentBookWithMutations(pathToRepository)

        bookingtrace = TheBook::bookingTrace(pathToRepository)
        book = InMemoryStore::getOrNull(bookingtrace)
        return book if book

        if Config::isAlexandra() and (TheBook::mutationFilepaths(pathToRepository).size > 200) then
            TheBook::importsMutations(pathToRepository)
        end
        if Config::isAlexandra() and ((Time.new.to_i - File.mtime(TheBook::mostRecentBookFilepath(pathToRepository)).to_i) > 86400) then
            TheBook::importsMutations(pathToRepository)
        end
        book1 = TheBook::mostRecentBook(pathToRepository)
        book2 = TheBook::mutationFilepaths(pathToRepository)
                    .reduce(book1){|runningbook, filepath|
                        item = JSON.parse(IO.read(filepath))
                        runningbook[item["uuid"]] = item
                        runningbook
                    }

        InMemoryStore::set(bookingtrace, book2)
        book2
    end

    # ---------------------------------------------------
    # PUBLIC INTERFACE

    # TheBook::getObjects(pathToRepository)
    def self.getObjects(pathToRepository)
        TheBook::mostRecentBookWithMutations(pathToRepository)
            .values
            .select{|object| object["phage_alive"] }
    end

    # TheBook::getObjectOrNull(pathToRepository, uuid)
    def self.getObjectOrNull(pathToRepository, uuid)
        TheBook::mostRecentBookWithMutations(pathToRepository)[uuid]
    end

    # TheBook::commitObjectToDisk(pathToRepository, object)
    def self.commitObjectToDisk(pathToRepository, object)
        TheBook::commitMutation(pathToRepository, object)
    end
end
