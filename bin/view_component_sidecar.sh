#!/bin/bash

# # Rename .rb
# find ./app/components -name '*.rb' | while read file; do
#   new_file=`echo $file | sed 's/\([a-z_]*\)\.rb/component.rb/'`
#   mv $file $new_file
# done

# Rename specs
find ./spec/components -name '*_spec.rb' | while read file; do
  new_dir=`echo $file | sed 's/\([a-z_]*\)\_spec.rb/\1/'`
  new_file=`echo $file | sed 's/\([a-z_]*\)\_spec.rb/\1\/component_spec.rb/'`
  mkdir $new_dir
  mv $file $new_file
done

# # Rename .html.erb
# find ./app/components -name '*.html.erb' | while read file; do
#   new_file=`echo $file | sed 's/\([a-z_]*\)\.html\.erb/component.html.erb/'`
#   mv $file $new_file
# done

# # Rename .css
# find ./app/components -name '*.css' | while read file; do
#   new_file=`echo $file | sed 's/\([a-z_]*\)\.css/component.css/'`
#   mv $file $new_file
# done

# # Rename .js
# find ./app/components -name '*.js' | while read file; do
#   new_file=`echo $file | sed 's/\([a-z_]*\)\.js/component.js/'`
#   mv $file $new_file
# done

# # Rename class declaration
# find ./app/components -name '*.rb' | while read file; do
#   sed -i 's/class \([a-zA-Z]\)*/class Component/' $file
# done

# Rename class in specs
# find ./spec/components -name '*_spec.rb' | while read file; do
#   sed -i 's/::\([A-Za-z]*\)/::Component/' $file
# done
