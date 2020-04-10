
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/YmirEstate.rb"
=begin
    YmirEstate::ymirFilepathEnumerator(pathToYmir)
    YmirEstate::locationBasenameToYmirLocationOrNull(pathToYmir, basename)
    YmirEstate::makeNewYmirLocationForBasename(pathToYmir, basename)
        # If base name is meant to be the name of a folder then folder itself 
        # still need to be created. Only the parent is created.
=end

require_relative "Nyx.rb"

require_relative "Nyx-Library/NyxCuration.rb"
require_relative "Nyx-Library/NyxPermanodeOperator.rb"
require_relative "Nyx-Library/NyxMiscUtils.rb"
require_relative "Nyx-Library/NyxUserInterface.rb"
require_relative "Nyx-Library/NyxSearch.rb"
