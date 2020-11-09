
LUCILLE_CORE_ICON_FILENAME     = 'Icon'+["0D"].pack("H*")
LUCILLE_CORE_DS_STORE_FILENAME = '.DS_Store'

class LucilleCore

    def self.ping()
        "pong"
    end

    # ------------------------------------------------------------------
    # MISC UTILS

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

    # ------------------------------------------------------------------
    # FILE SYSTEM UTILS

    # LucilleCore::locationsAtFolder(folderpath)
    def self.locationsAtFolder(folderpath)
        Dir.entries(folderpath)
            .reject{|filename| [".", "..", LUCILLE_CORE_DS_STORE_FILENAME, LUCILLE_CORE_ICON_FILENAME].include?(filename) }
            .sort
            .map{|filename| "#{folderpath}/#{filename}" }
    end

    # LucilleCore::removeFileSystemLocation(location)
    def self.removeFileSystemLocation(location)
        return if !File.exists?(location)
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
        raise "[error: 2bb7c48e]" if !File.exists?(targetFolderpath)
        LucilleCore::locationsAtFolder(sourceFolderpath).each{|location|
            LucilleCore::copyFileSystemLocation(location, targetFolderpath)
        }
    end

    # LucilleCore::migrateContents(sourceFolderpath, targetFolderpath)
    def self.migrateContents(sourceFolderpath, targetFolderpath)
        raise "[error: 2b67a91b]" if !File.exists?(targetFolderpath)
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

    # LucilleCore::indexsubfolderpath(folderpath1)
    def self.indexsubfolderpath(folderpath1)
        if !File.exists?(folderpath1) then
            FileUtils.mkpath(folderpath1)
        end
        indexToLocation = lambda{|i, folderpath1| 
            "#{folderpath1}/#{i.to_s.rjust(6,"0")}"
        }
        indx = LucilleCore::integerEnumerator()
            .lazy
            .drop_while{|i|  
                File.exists?(indexToLocation.call(i, folderpath1)) and File.exists?(indexToLocation.call(i+1, folderpath1))
            }
            .drop_while{|i|  
                folderpath = indexToLocation.call(i, folderpath1)
                File.exists?(folderpath) and Dir.entries(folderpath).size >= 100
            }
            .first
        targetsubfolderpath = indexToLocation.call(indx, folderpath1)
        if !File.exists?(targetsubfolderpath) then
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
        indexDisplayMaxSize = elements.size.to_s.size # This allows adjustement of the index ns0.
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

    # LucilleCore::selectZeroOrMore(type, selected, unselected, toStringLambda = lambda{ |item| item })
    def self.selectZeroOrMore(type, selected, unselected, toStringLambda = lambda{ |item| item })

        mappingDescriptionsToValues = {}
        (selected + unselected).each{|item|
            mappingDescriptionsToValues[toStringLambda.call(item)] = item
        }

        puts type

        counter = 0
        counterToItemMapping = {}

        if unselected.size > 0 then
            puts "-> unselected"
            unselected.each{|item|
                counter = counter + 1
                counterToItemMapping[counter] = item
                puts "      #{counter}: #{toStringLambda.call(item)}"
            }
        end

        if selected.size > 0 then
            puts "-> selected"
            selected.each{|item|
                counter = counter + 1
                counterToItemMapping[counter] = item
                puts "      #{counter}: #{toStringLambda.call(item)}"
            }
        end

        print "item: "
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
        indexDisplayMaxSize = items.size.to_s.size # This allows adjustement of the index ns0.
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

class LCoreMenuItemsNX1

    def initialize()
        @items = []
        @position = 0
    end

    def item(description, xlambda)
        @position = @position + 1
        @items << {
            "position" => @position,
            "lambda"   => xlambda
        }
        puts "[#{@position.to_s.rjust(2)}] #{description}"
    end

    def ordinal(xlambda)
        @position = @position + 1
        @items << {
            "position" => @position,
            "lambda"   => xlambda
        }
        @position
    end

    def promptAndRunSandbox() # display a prompt and handle the input ; return whether something ran
        position = LucilleCore::askQuestionAnswerAsString("-> ")
        return false if position.size == 0
        position = position.to_i
        item = @items.select{|item| item["position"] == position }.first
        return true if item.nil?
        item["lambda"].call()
        true
    end

    def promptAndRunFunctionGetValueOrNull() # display a prompt and handle the input ; return the value of the lambda
        position = LucilleCore::askQuestionAnswerAsString("-> ")
        return nil if position.size == 0
        position = position.to_i
        item = @items.select{|item| item["position"] == position }.first
        return nil if item.nil?
        item["lambda"].call()
    end

    def executeFunctionAtPositionGetValueOrNull(position) # for when the user will be prompting themselves and only call this if an integer, eg: Catalyst UI,
        item = @items.select{|item| item["position"] == position }.first
        return if item.nil?
        item["lambda"].call()
    end
end

class LCoreMenuItemsNX2

    def reset()
        @items = []
        @position = 0
    end

    def initialize()
        reset()
    end

    def item(description, xlambda)
        @position = @position + 1
        @items << {
            "position" => @position,
            "lambda"   => xlambda
        }
        puts "[#{@position.to_s.rjust(2)}] #{description}"
    end

    def executeFunctionAtPositionGetValueOrNull(position) # for when the user will be prompting themselves and only call this if an integer, eg: Catalyst UI,
        item = @items.select{|item| item["position"] == position }.first
        return if item.nil?
        item["lambda"].call()
    end
end


