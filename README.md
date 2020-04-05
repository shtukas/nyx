# Catalyst

Catalyst is made of 5 individual apps: Night, Nyx, Starburst, Todo and Wave.

They operate independently in the sense that they have their own logic and their own data repositories. An app can expose functions to other apps, by providing a single class that can be imported by the other apps. For instance, Startburst can use Todo related functions, for instance to convert a startburst folder into a Todo item, by importing `Todo/Todo.rb`.


