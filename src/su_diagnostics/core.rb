#-------------------------------------------------------------------------------
#
# Copyright 2013, Trimble Navigation Limited
#
# This software is provided as an example of using the Ruby interface
# to SketchUp.
#
# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#-------------------------------------------------------------------------------

require 'su_diagnostics.rb'

module Sketchup::Extensions::Diagnostics

### UI ### ---------------------------------------------------------------------

  unless file_loaded?(__FILE__)
    # Commands
    cmd = UI::Command.new('Collect Data') { 
      self.collect_data
    }
    cmd.tooltip = 'Collect Data'
    cmd.status_bar_text = 'Collect diagnostics data.'
    cmd_collect_data = cmd
    
    # Menus
    menu = UI.menu('Plugins').add_submenu(PLUGIN_NAME)
    menu.add_item(cmd_collect_data)
  end


  ### Extension ### ------------------------------------------------------------

  KEY_SIZE  = 30
  SEPARATOR = "\n".freeze

  # @since 1.0.0
  def self.collect_data
    data = ''

    # SketchUp
    sketchup = 'SketchUp'
    sketchup << ' Pro' if Sketchup.is_pro?
    data << "#{sketchup} (#{Sketchup.version}) Diagnostic Information\n"
    data << SEPARATOR

    # Ruby
    data << "### Ruby\n"
    ruby_data = Object.constants.grep(/^RUBY_/).sort
    for constant in ruby_data
      data << "#{constant.to_s.ljust(KEY_SIZE)}: #{Object.const_get(constant)}\n"
    end
    data << SEPARATOR

    # Environment
    data << "### Environment\n"
    for key, value in ENV
      if key == 'PATH'
        paths = value.split(';')
        data << "#{key.ljust(KEY_SIZE)}: #{paths.shift}\n"
        indent = ' ' * KEY_SIZE
        for path in paths
          data << "#{indent}  #{path}\n"
        end
      else
        data << "#{key.ljust(KEY_SIZE)}: #{value}\n"
      end
    end
    data << SEPARATOR

    # Extensions
    if Sketchup.respond_to?(:extensions)
      extension = Sketchup.extensions
    else
      extensions = []
      ObjectSpace.each_object(SketchupExtension) { |extension|
        extensions << extension
      }
    end
    data << "### Extensions\n"
    for extension in extension
      loaded = (extension.respond_to?(:loaded?) && extension.loaded?) ? 'LOADED' : ''
      data << "#{extension.name.ljust(KEY_SIZE)} (#{extension.version}) #{loaded}\n"
    end
    data << SEPARATOR

    # $LOAD_PATH
    data << "### $LOAD_PATH\n"
    for path in $LOAD_PATH
      data << "#{path}\n"
    end
    data << SEPARATOR

    # $LOADED_FEATURES
    data << "### $LOADED_FEATURES\n"
    for filename in $LOADED_FEATURES
      data << "#{filename}\n"
    end
    data << SEPARATOR

    if ENV['LOCALAPPDATA']
      data << "### VirtualStore\n"
      plugins_path = Sketchup.find_support_file('Plugins')
      virtualstore = File.join(ENV['LOCALAPPDATA'], 'VirtualStore')
      path = plugins_path.split(':')[1]
      virtual_path = File.join(virtualstore, path)
      virtual_path = File.expand_path(virtual_path)
      if File.exist?( virtual_path )
        filter = File.join(virtual_path, '*')
        virtual_files = Dir.glob(filter).join("\n")
        data << "#{virtual_files}\n"
      else
        data << "<no files found>\n"
      end
      data << SEPARATOR
    end

    puts data


    # Save results to file.
    if ENV['HOME']
      desktop_path = File.join(ENV['HOME'], 'Desktop')
      unless File.exist?(desktop_path)
        desktop_path = nil
      end
    else
      desktop_path = nil
    end
    title = 'Save Diagnostic Data'
    default_name = 'SketchUp-Diagnostic.txt'
    filename = UI.savepanel(title, desktop_path, default_name)
    if filename
      File.open(filename, 'w') { |file| file.write(data) }
      puts "Diagnostics data written to: #{filename}"
    end
  end


  ### DEBUG ### ----------------------------------------------------------------
  
  # Sketchup::Extensions::Diagnostics.reload
  #
  # @since 1.0.0
  def self.reload
    original_verbose = $VERBOSE
    $VERBOSE = nil
    filter = File.join(PATH, '*.{rb,rbs}')
    files = Dir.glob(filter).each { |file|
      load file
    }
    files.length
  ensure
    $VERBOSE = original_verbose
  end

end # module

#-------------------------------------------------------------------------------

file_loaded(__FILE__)

#-------------------------------------------------------------------------------
