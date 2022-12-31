
# Stargate

Stargate is the umbrella name given to three different very distinct program that somehow exists in the same code: Catalyst, Nyx and Gridfire.

### Install

Note: global version of Ruby that comes with MacOS: `$ which ruby` gives `/usr/bin/ruby`. The gem command: `$ gem env home` gives `/Library/Ruby/Gems/2.6.0`. All of this is a problem for me because global version conflicts with the local version rbenv file and Gemfile.

Note: All the rubies: `$ rbenv versions` 

Note: Display the exec
	- `rbenv which irb`
	- `rbenv which gem` (`/Users/pascal/.rbenv/versions/3.1.2/bin/gem`)
	- `rbenv which bundle` (`/Users/pascal/.rbenv/versions/3.1.2/bin/bundle`)

Note: https://github.com/rbenv/rbenv

- $ brew install rbenv ruby-build # to get rbenv
- $ rbenv install 3.1.2 # version of ruby we are using
- $ bundle install (use the correct one)

Then to start catalyst: `catalyst`

### Catalyst

Catalyst is an advanced task management system.

### Nyx

Nyx is a file system.

Somebody once asked this question on the internet: _I am wondering if it is possible in a reasonably convenient way to store files in the form of a graph (in the mathematical sense). That would mean that any file can be connected to multiple other files or "directories", and such a directory would be a node in the graph but not a file._

My answer can be found here: [nyx.md](./nyx.md)

### Gridfire

Gridfire is a file system helper.