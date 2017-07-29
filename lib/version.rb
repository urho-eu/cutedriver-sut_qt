############################################################################
##
## Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
## All rights reserved.
## Contact: Nokia Corporation (testabilitydriver@nokia.com)
##
## This file is part of Testability Driver.
##
## If you have questions regarding the use of this file, please contact
## Nokia at testabilitydriver@nokia.com .
##
## This library is free software; you can redistribute it and/or
## modify it under the terms of the GNU Lesser General Public
## License version 2.1 as published by the Free Software Foundation
## and appearing in the file LICENSE.LGPL included in the packaging
## of this file.
##
############################################################################

ENV['TDRIVER_SUT_QT_VERSION'] = '2.0.0'

module TDriverSutQt
  VERSION = ENV['TDRIVER_SUT_QT_VERSION']

  module Version # :nodoc: all
    MAJOR, MINOR, BUILD, *OTHER = TDriverSutQt::VERSION.split "."

    NUMBERS = [MAJOR, MINOR, BUILD, *OTHER]
  end
end

#
# version information
#
def read_version # :nodoc: all
  relmode = "  Release mode: "
  if @__release_mode
    relmode << @__release_mode
  else
    relmode << "unspecified"
  end
  puts relmode

  version = ENV['TDRIVER_SUT_QT_VERSION']

  File.open(Dir.getwd << '/debian/changelog') do |file|
    line = file.gets
    arr = line.split(')')
    arr = arr[0].split('(')
    arr = arr[1].split('-')
    version = arr[0]
  end

  if( @__release_mode == 'release' )
    return version
  elsif( @__release_mode == 'cruise' )
    return version + "." + Time.now.strftime("pre%Y%m%d")
  else
    return version + "." + Time.now.strftime("%Y%m%d%H%M%S")
  end
end
