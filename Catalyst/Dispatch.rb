
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Dispatch.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTargets.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoints.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Multiverse.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/TimePods/TimePods.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/Todo.rb"

# -----------------------------------------------------------------

class Dispatch

    # Dispatch::textDispatch(text)
    def self.textDispatch(text)
        puts "-------------------------------------------------------------"
        puts text
        puts "-------------------------------------------------------------"
        options = [
            "dispatch to Todo"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return if option.nil?
        if option == "dispatch to Todo" then

            # File creation
            filename = "#{SecureRandom.uuid}.txt"
            filepath = "/tmp/#{filename}"
            File.open(filepath, "w"){|f| f.puts(text) }

            # Make target
            target = CatalystStandardTargets::issueTargetFile(filepath)
            puts JSON.pretty_generate(target)

            # Make Todo item
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            item = Items::issueNewItemInteractivelyX1(description, target)
            puts JSON.pretty_generate(item)
        end
    end
end
