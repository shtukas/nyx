## DocNet

This is the DocNet end user documentation.

DocNet is a multi-user distributed documentation framework, built for the Guardian engineering department. DocNet became an active project mid 2020 and is a work in progress.

In this documentation:

- How to aquire it and get it to run.
- The basic functions 
	- Exploration of the knowledge network.
	- Creation and edition of new datapoints.

DocNet...

- Was born as a terminal application (a purposeful choice by its author), but will acquire other interfaces as time goes on. 
- Is written in Ruby (because the program is it splitting from, Catalyst, is written in Ruby).
- Has an interesting data model. The reader is invited to get familiar with it to better understand the user interface. See [DocNet Datamodel](DocNetDatamodel.md).

### Installation and running

There is only one dependency that you might not already have installed: the `curses` gem.

```
$ gem install curses # or sudo gem install curses
```

DocNet is currently distributed as a github repo, so do clone the repository [https://github.com/shtukas/catalyst](https://github.com/shtukas/catalyst). Then 

```
./docnet
```

at the command line and that's all you should then be greeted with this screen.

![](images/1595716867.png)

followed by 

![](images/1595716977.png)

Note that depending on your permission level, less than those 11 options may be presented to you. 

