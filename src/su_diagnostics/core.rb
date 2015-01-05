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

  KEY_SIZE  = 40
  SEPARATOR = "\n".freeze

  # @since 1.0.0
  def self.collect_data
    data = ''
    # Because UTF-8 conversion might fail, collect all data as binary data.
    # SketchUp will try to display it correctly.
    data.encode!("ASCII-8BIT") if data.respond_to?(:encode!)
    #p [1, data.encoding]

    # SketchUp
    sketchup = 'SketchUp'
    sketchup << ' Pro' if Sketchup.is_pro?
    data << "#{sketchup} (#{Sketchup.version}) Diagnostic Information\n"
    data << SEPARATOR
    #p [2, data.encoding]

    # Ruby
    data << "### Ruby\n"
    ruby_data = Object.constants.grep(/^RUBY_/).sort
    for constant in ruby_data
      data << "#{constant.to_s.ljust(KEY_SIZE)}: #{Object.const_get(constant)}\n".force_encoding("ASCII-8BIT")
    end
    data << SEPARATOR
    #p [3, data.encoding]

    # Environment
    data << "### Environment\n"
    for key, value in ENV

      key_utf8 = key.dup.force_encoding("ASCII-8BIT")
      key_encoding = key.encoding.name.force_encoding("ASCII-8BIT")

      value_utf8 = value.dup.force_encoding("ASCII-8BIT")
      value_encoding = value.encoding.name.force_encoding("ASCII-8BIT")

      key_info = "#{key_utf8} (#{key_encoding})"

      if key_utf8.upcase == 'PATH'
        paths = value_utf8.split(';')
        data << "#{key_info.ljust(KEY_SIZE)}: #{paths.shift} (#{value_encoding})\n".force_encoding("ASCII-8BIT")
        indent = ' ' * KEY_SIZE
        for path in paths
          data << "#{indent}  #{path} (#{value_encoding})\n".force_encoding("ASCII-8BIT")
        end
      else
        data << "#{key_info.ljust(KEY_SIZE)}: #{value_utf8} (#{value_encoding})\n".force_encoding("ASCII-8BIT")
      end
    end
    data << SEPARATOR
    #p [4, data.encoding]

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
      data << "#{extension.name.ljust(KEY_SIZE)} (#{extension.version}) #{loaded}\n".force_encoding("ASCII-8BIT")
    end
    data << SEPARATOR
    #p [5, data.encoding]

    # $LOAD_PATH
    data << "### $LOAD_PATH\n"
    for path in $LOAD_PATH
      if path.respond_to?(:encoding)
        # (!) Might have to use force_encoding instead.
        path_utf8 = path.dup.force_encoding("ASCII-8BIT")
        path_encoding = path.encoding.name.force_encoding("ASCII-8BIT")
        #puts '---'
        #p path_utf8.encoding
        #p path_encoding.encoding
        #p data.encoding
        data << "#{path_utf8} (#{path_encoding})\n".force_encoding("ASCII-8BIT")
      else
        data << "#{path}\n".force_encoding("ASCII-8BIT")
      end
    end
    data << SEPARATOR
    #p [6, data.encoding]

    # $LOADED_FEATURES
    data << "### $LOADED_FEATURES\n"
    for filename in $LOADED_FEATURES
      if filename.respond_to?(:encoding)
        # (!) Might have to use force_encoding instead.
        filename_utf8 = filename.dup.force_encoding("ASCII-8BIT")
        filename_encoding = filename.encoding.name.force_encoding("ASCII-8BIT")
        data << "#{filename_utf8} (#{filename_encoding})\n"
      else
        data << "#{filename}\n"
      end
    end
    data << SEPARATOR
    #p [7, data.encoding]

    # Plugins folder content
    data << "### Plugins Folder\n"
    plugins_path = Sketchup.find_support_file('Plugins')
    data << "Path: #{plugins_path}\n".force_encoding("ASCII-8BIT")
    filter = File.join(plugins_path, '*')
    content = Dir.glob(filter)
    for item in content
      filename_encoding = item.encoding.name.force_encoding("ASCII-8BIT")
      basename = File.basename(item)
      basename.force_encoding("ASCII-8BIT")
      if File.directory?(item)
        file_item = "[Folder] #{basename} (#{filename_encoding})\n"
      else
        file_item = "  [File] #{basename} (#{filename_encoding})\n"
      end
      file_item.force_encoding("ASCII-8BIT")
      data << file_item
    end
    data << SEPARATOR
    #p [8, data.encoding]

    # VirtualStore
    if ENV['LOCALAPPDATA']
      data << "### VirtualStore\n"
      plugins_path = Sketchup.find_support_file('Plugins')
      virtualstore = File.join(ENV['LOCALAPPDATA'], 'VirtualStore')

      plugins_path.force_encoding("ASCII-8BIT")
      virtualstore.force_encoding("ASCII-8BIT")

      path = plugins_path.split(':')[1]
      virtual_path = File.join(virtualstore, path)
      virtual_path = File.expand_path(virtual_path)

      virtual_path.force_encoding("UTF-8")

      if File.exist?( virtual_path )
        filter = File.join(virtual_path, '*')
        virtual_files = Dir.glob(filter).join("\n")
        data << "#{virtual_files}\n"
      else
        data << "<no files found>\n"
      end
      data << SEPARATOR
    end
    #p [9, data.encoding]
  ensure

    # Attempt to convert data to UTF-8 encoding.
    test_data = data.dup
    test_data.force_encoding("UTF-8")
    data << "Valid UTF-8 encoding: #{test_data.valid_encoding?}"

    puts data


    # Save results to file.
    if ENV['HOME']
      desktop_path = File.join(ENV['HOME'], 'Desktop')
      desktop_path.force_encoding("UTF-8")
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
