
# encoding: UTF-8
require 'json'

require_relative "LucilleCore.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

# -------------------------------------------------------------------------------------

class RealEstate

    # RealEstate::surveyConstruction()
    def self.surveyConstruction()
        userHomeDirectory = ENV['HOME']
        docnetFolderPath = "#{userHomeDirectory}/.docnet"
        if !File.exists?(docnetFolderPath) then
            status = LucilleCore::askQuestionAnswerAsBoolean("The folder '#{docnetFolderPath}' has not been created. I am going to create it, please confirm ")
            if !status then
                puts "I am aborting launching docnet. Good bye."
                exit
            end
            FileUtils.mkdir(docnetFolderPath)
        end
        deskFolderPath = "#{docnetFolderPath}/001-desk-85d03ad6-ba18-4b01-b9e3-8496eaab477f"
        if !File.exists?(deskFolderPath) then
            FileUtils.mkdir(deskFolderPath)
        end
    end

    # RealEstate::getDeskFolderpath()
    def self.getDeskFolderpath()
        "#{ENV['HOME']}/.docnet/001-desk-85d03ad6-ba18-4b01-b9e3-8496eaab477f"
    end
end