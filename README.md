
### Nyx

Nyx is Pascal's knowledge graph.

### Install

```
$ rbenv install 3.4.1
$ rbenv local 3.4.1
$ bundle install
```

If we have a problem after upgrading Ruby, for instance sqlite3 is not working, try:

```
brew reinstall sqlite
gem uninstall sqlite3
gem install sqlite3 --platform=ruby
bundle pristine sqlite3
bundle install
```
