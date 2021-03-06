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

require 'sketchup.rb'
require 'extensions.rb'

#-------------------------------------------------------------------------------

module Sketchup
 module Extensions
  module Diagnostics
  
  ### CONSTANTS ### ------------------------------------------------------------
  
  # Plugin information
  PLUGIN_ID       = 'Diagnostics'.freeze
  PLUGIN_NAME     = 'SketchUp Diagnostics Tools'.freeze
  PLUGIN_VERSION  = '1.2.0'.freeze
  
  # Resource paths
  FILENAMESPACE = File.basename(__FILE__, '.*')
  PATH_ROOT     = File.dirname(__FILE__).freeze
  PATH          = File.join(PATH_ROOT, FILENAMESPACE).freeze
  
  
  ### EXTENSION ### ------------------------------------------------------------
  
  unless file_loaded?(__FILE__)
    loader = File.join( PATH, 'core.rb' )
    ex = SketchupExtension.new(PLUGIN_NAME, loader)
    ex.description = 'Collects diagnostics data related to SketchUp.'
    ex.version     = PLUGIN_VERSION
    ex.copyright   = 'Trimble Navigation Limited © 2013'
    ex.creator     = 'SketchUp'
    Sketchup.register_extension(ex, true)
  end
  
  end # module Diagnostics
 end # module Extensions
end # module Sketchup

#-------------------------------------------------------------------------------

file_loaded(__FILE__)

#-------------------------------------------------------------------------------
