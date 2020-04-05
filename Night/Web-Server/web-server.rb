
# encoding: UTF-8

# ------------------------------------------------------------

require 'sinatra'
# http://www.sinatrarb.com/intro.html

require 'mustache'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(2) #=> "eb69"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/load-code.rb"

# --  --------------------------------------------------

def core_get_config()
    JSON.parse(IO.read("#{File.dirname(__FILE__)}/config.json"))
end

def core_read_config_value(key)
    core_get_config()[key]
end

set :port, core_read_config_value('port')
set :public_folder, "#{File.dirname(__FILE__)}/www-root"

# -- --------------------------------------------------
# Route

not_found do
  ''
end

get '/' do
    IO.read("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Night/Elm-Source/src/index.html")
end

get '/data/permanodes' do
    # aionblobref = params['aionblobref']
    content_type 'application/json'
    data = NyxIndex2::permanodesEnumerator().to_a
    JSON.generate(data)
end

get '/data/timelines' do
    # aionblobref = params['aionblobref']
    content_type 'application/json'
    data = NyxPermanodeUtils::timelinesInDecreasingActivityDateTime()
    JSON.generate(data)
end

get '/command/open-unique-string/:uniquename' do
    uniquename = params['uniquename']
    location = NyxMiscUtils::uniqueNameResolutionLocationPathOrNull(uniquename)
    if location then
        system("open '#{location}'")
        "Ok: #{location}"
    else
        "Location not found"
    end
end

get '/command/open-target-folder/:mark' do
    mark = params['mark']
    location = NyxMiscUtils::lStoreMarkResolutionToMarkFilepathOrNull(mark)
    if location then
        if File.exists?(location) then
            folderpath = File.dirname(location)
            system("open '#{folderpath}'")
            "Ok: #{folderpath}"
        else
            "Location not reachable: #{location}"
        end
    else
        "Location not found"
    end
end

get '/command/open-perma-dir/:foldername' do
    foldername = params['foldername']
    location = YmirEstate::locationBasenameToYmirLocationOrNull(Nyx::pathToYmir(), "nyx", foldername)
    if location and File.exists?(location) then
        system("open '#{location}'")
        "Ok: #{location}"
    else
        "Location not found: #{location}"
    end
end

