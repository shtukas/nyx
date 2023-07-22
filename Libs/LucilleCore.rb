
# require "/Users/pascal/Galaxy/Software/Lucille-Ruby-Libraries/LucilleCore.rb"

# ---------------------------------------------------------------------------------------------

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "1ac4eb69"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'date'

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'find'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

# ----------------------------------------------------------------------

if !defined?(LUCILLE_CORE_ICON_FILENAME) then
    LUCILLE_CORE_ICON_FILENAME = 'Icon'+["0D"].pack("H*")
end

if !defined?(LUCILLE_CORE_DS_STORE_FILENAME) then
    LUCILLE_CORE_DS_STORE_FILENAME = '.DS_Store'
end

class LucilleCore

    def self.ping()
        "pong"
    end

    # ------------------------------------------------------------------
    # MISC UTILS

    # LucilleCore::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = SecureRandom.uuid
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # LucilleCore::pressEnterToContinue(text = "")
    def self.pressEnterToContinue(text = "")
        if text.strip.size>0 then
            print text
        else
            print "Press [enter] to continue: "
        end
        STDIN.gets().strip
    end

    # LucilleCore::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # LucilleCore::integerEnumerator()
    def self.integerEnumerator()
        Enumerator.new do |integers|
            cursor = -1
            while true do
                cursor = cursor + 1
                integers << cursor
            end
        end
    end

    # LucilleCore::isOnPower()
    def self.isOnPower()
        `#{ENV["HOME"]}/Galaxy/Binaries/isOnPower`.strip == "true"
    end

    # ------------------------------------------------------------------
    # FILE SYSTEM UTILS

    # LucilleCore::locationsAtFolder(folderpath)
    def self.locationsAtFolder(folderpath)
        Dir.entries(folderpath)
            .reject{|filename| [".", "..", LUCILLE_CORE_DS_STORE_FILENAME, LUCILLE_CORE_ICON_FILENAME].include?(filename) }
            .sort
            .map{|filename| "#{folderpath}/#{filename}" }
    end

    # LucilleCore::enumeratorLocationsInFileHierarchyWithFilter(root, filter: Lambda(String -> Boolean))
    def self.enumeratorLocationsInFileHierarchyWithFilter(root, filter)
        Enumerator.new do |filepaths|
            Find.find(root) do |path|
                next if !filter.call(path)
                filepaths << path
            end
        end
    end

    # LucilleCore::getLocationInFileHierarchyWithFilterOrNull(root, filter: Lambda(String -> Boolean))
    def self.getLocationInFileHierarchyWithFilterOrNull(root, filter)
        LucilleCore::enumeratorLocationsInFileHierarchyWithFilter(root, filter).first
    end

    # LucilleCore::removeFileSystemLocation(location)
    def self.removeFileSystemLocation(location)
        return if !File.exist?(location)
        if File.file?(location) then
            FileUtils.rm(location)
        else
            FileUtils.rm_rf(location)
        end
    end

    # LucilleCore::copyFileSystemLocation(source, target)
    # If target already exists and is a folder, source is put inside target.
    def self.copyFileSystemLocation(source, target)
        if File.file?(source) then
            FileUtils.cp(source,target)
        else
            FileUtils.cp_r(source,target)
        end
    end

    # LucilleCore::copyContents(sourceFolderpath, targetFolderpath)
    def self.copyContents(sourceFolderpath, targetFolderpath)
        raise "[error: 2bb7c48e]" if !File.exist?(targetFolderpath)
        LucilleCore::locationsAtFolder(sourceFolderpath).each{|location|
            LucilleCore::copyFileSystemLocation(location, targetFolderpath)
        }
    end

    # LucilleCore::migrateContents(sourceFolderpath, targetFolderpath)
    def self.migrateContents(sourceFolderpath, targetFolderpath)
        raise "[error: 2b67a91b]" if !File.exist?(targetFolderpath)
        LucilleCore::locationsAtFolder(sourceFolderpath).each{|location|
            LucilleCore::copyFileSystemLocation(location, targetFolderpath)
            LucilleCore::removeFileSystemLocation(location)
        }
    end

    # LucilleCore::locationRecursiveSize(location)
    def self.locationRecursiveSize(location)
        if File.file?(location) then
            File.size(location)
        else
            4*1024 + Dir.entries(location)
                .select{|filename| filename!='.' and filename!='..' }
                .map{|filename| "#{location}/#{filename}" }
                .map{|location| LucilleCore::locationRecursiveSize(location) }
                .inject(0,:+)
        end
    end

    # LucilleCore::indexsubfolderpath(folderpath1, capacity = 100)
    def self.indexsubfolderpath(folderpath1, capacity = 100)
        if !File.exist?(folderpath1) then
            FileUtils.mkpath(folderpath1)
        end
        indexToLocation = lambda{|i, folderpath1| 
            "#{folderpath1}/#{i.to_s.rjust(6,"0")}"
        }
        indx = LucilleCore::integerEnumerator()
            .lazy
            .drop_while{|i|  
                File.exist?(indexToLocation.call(i, folderpath1)) and File.exist?(indexToLocation.call(i+1, folderpath1))
            }
            .drop_while{|i|  
                folderpath = indexToLocation.call(i, folderpath1)
                File.exist?(folderpath) and Dir.entries(folderpath).size >= capacity
            }
            .first
        targetsubfolderpath = indexToLocation.call(indx, folderpath1)
        if !File.exist?(targetsubfolderpath) then
            FileUtils.mkpath(targetsubfolderpath)
        end
        targetsubfolderpath
    end

    # LucilleCore::indexsubfolderpath2(folderpath1, capacity = 100)
    # In this version, we target the first folder under capacity
    def self.indexsubfolderpath2(folderpath1, capacity = 100)
        if !File.exist?(folderpath1) then
            FileUtils.mkpath(folderpath1)
        end
        indexToLocation = lambda{|i, folderpath1| 
            "#{folderpath1}/#{i.to_s.rjust(6,"0")}"
        }
        indx = LucilleCore::integerEnumerator()
            .lazy
            .drop_while{|i|  
                folderpath = indexToLocation.call(i, folderpath1)
                File.exist?(folderpath) and Dir.entries(folderpath).size >= capacity
            }
            .first
        targetsubfolderpath = indexToLocation.call(indx, folderpath1)
        if !File.exist?(targetsubfolderpath) then
            FileUtils.mkpath(targetsubfolderpath)
        end
        targetsubfolderpath
    end

    # LucilleCore::locationTraceRecursively(location)
    def self.locationTraceRecursively(location)
        if File.file?(location) then
            Digest::SHA1.hexdigest("#{location}:#{Digest::SHA1.file(location).hexdigest}")
        else
            trace = Dir.entries(location)
                .sort
                .reject{|filename| [".", "..", LUCILLE_CORE_DS_STORE_FILENAME, LUCILLE_CORE_ICON_FILENAME].include?(filename) }
                .map{|filename| "#{location}/#{filename}" }
                .map{|location| 
                    begin
                        LucilleCore::locationTraceRecursively(location)
                    rescue
                        location
                    end
                }
                .join("::")
            Digest::SHA1.hexdigest(trace)
        end
    end

    # ------------------------------------------------------------------
    # THE ART OF ASKING

    # LucilleCore::askQuestionAnswerAsString(question)
    def self.askQuestionAnswerAsString(question)
        print question
        STDIN.gets().strip
    end

    # LucilleCore::askQuestionAnswerAsBoolean(announce, defaultValue = nil)
    def self.askQuestionAnswerAsBoolean(announce, defaultValue = nil) # defaultValue: Boolean
        print announce
        if defaultValue.nil? then
            print "yes/no: "
            answer = STDIN.gets.strip().downcase
            if !["yes", "no"].include?(answer) then
                return LucilleCore::askQuestionAnswerAsBoolean(announce) 
            end
            return answer == 'yes'
        else
            print "yes/no (default: #{defaultValue ? "yes" : "no"}): "
            answer = STDIN.gets.strip().downcase
            if answer == "" then
                return defaultValue
            end
            if !["yes", "no"].include?(answer) then
                return LucilleCore::askQuestionAnswerAsBoolean(announce) 
            end
            return answer == 'yes'
        end
    end

    # LucilleCore::selectEntityFromListOfEntitiesOrNull(type, elements, toStringLambda = lambda{ |item| item })
    def self.selectEntityFromListOfEntitiesOrNull(type, elements, toStringLambda = lambda{ |item| item })
        puts "Select #{type}"
        indexDisplayMaxSize = elements.size.to_s.size # This allows adjustement of the index fragment.
        elements.each_with_index{|element,index|
                puts "    [#{(index+1).to_s.rjust(indexDisplayMaxSize)}] #{toStringLambda.call(element)}"
            }

        print ":: (empty for null): "
        indx = STDIN.gets().strip
        return nil if indx.size==0
        possibleStringAnswers = (1..elements.size).map{|x| x.to_s }
        if !possibleStringAnswers.include?(indx) then
            return LucilleCore::selectEntityFromListOfEntitiesOrNull(type, elements, toStringLambda)
        end

        indx = indx.to_i
        element = elements[indx-1]
        element   
    end

    # LucilleCore::selectEntityFromListOfEntities_EnsureChoice(type, options, toStringLambda = lambda{ |item| item })
    def self.selectEntityFromListOfEntities_EnsureChoice(type, options, toStringLambda = lambda{ |item| item })
        choice = nil
        while choice.nil? do 
            choice = LucilleCore::selectEntityFromListOfEntitiesOrNull(type, options, toStringLambda)
        end
        choice
    end

    # LucilleCore::selectZeroOrMore(type, selected, unselected, toStringLambda = lambda{ |item| item }) # [selected, unselected]
    def self.selectZeroOrMore(type, selected, unselected, toStringLambda = lambda{ |item| item })

        mappingDescriptionsToValues = {}
        (selected + unselected).each{|item|
            mappingDescriptionsToValues[toStringLambda.call(item)] = item
        }

        puts ""
        puts "-- multi selection ------------------------"

        counter = 0
        counterToItemMapping = {}

        puts "unselected:"
        unselected.each{|item|
            counter = counter + 1
            counterToItemMapping[counter] = item
            puts "      #{counter}: #{toStringLambda.call(item)}"
        }

        puts "selected:"
        selected.each{|item|
            counter = counter + 1
            counterToItemMapping[counter] = item
            puts "      #{counter}: #{toStringLambda.call(item)}"
        }

        puts ""
        print "index (empty for returning selection): "
        itemNumber = STDIN.gets().strip
        if itemNumber.size == 0 then
            return [selected, unselected]
        end
        itemNumber =  itemNumber.to_i

        item = counterToItemMapping[itemNumber]

        if selected.include?(item)  then
            # We move the item from 'selected' to 'unselected'
            LucilleCore::selectZeroOrMore(type, selected.reject{|x| toStringLambda.call(x) == toStringLambda.call(item) }, unselected + [item], toStringLambda)
        else
            # We move the item from 'unselected' to 'selected'
            LucilleCore::selectZeroOrMore(type, selected + [item], unselected.reject{|x| toStringLambda.call(x) == toStringLambda.call(item) }, toStringLambda)
        end
    end

    # ------------------------------------------------------------------
    # THE ART OF DOING

    # LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
    # Items = Array[ null || Item ] # null is used for empty space
    # Item = [String, lambda {}]
    def self.menuItemsWithLambdas(items)
        puts "->"
        indexDisplayMaxSize = items.size.to_s.size # This allows adjustement of the index fragment.
        items.each_with_index{|item,index|
                if item.nil? then
                    puts ""
                    next
                end
                puts "    [#{(index+1).to_s.rjust(indexDisplayMaxSize)}] #{item[0]}"
            }
        print ":: (empty for void): "
        indx = STDIN.gets().strip
        return nil if indx.size==0
        possibleStringAnswers = (1..items.size).map{|x| x.to_s }
        if !possibleStringAnswers.include?(indx) then
            return LucilleCore::menuItemsWithLambdas(items)
        end
        item = items[indx.to_i-1]
        item[1].call()
        true
    end
end
