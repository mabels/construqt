# what is construqt

construqt is an interface to describe strong depending network structures.

construqt describes connections(left,right) with same syntax, and hides 
the implementation details from user. It is vendor agnostic.

construqt uses a programming language(ruby) to describe
the network. There is no static configuration file or format or syntax.

construqt knows the described network connections and generates a 
network-documentation on the fly.

# examples

There are now parts of my homenetwork as living examples. Just go to 
examples and do ruby construqt.rb and have a look in the generated cfgs directory.

Here are the hand drawn picture of the example network

![alt tag](https://raw.github.com/mabels/construqt/master/example-construqt.jpg)
https://docs.google.com/drawings/d/16ipb13nHpIuQmVJlAk3TNada8zNe9v3V-Wmv9cLiyWA/edit?usp=sharing

This is the generated network plan

![alt tag](https://storage.googleapis.com/construqt/world.svg)
https://storage.googleapis.com/construqt/world.svg


