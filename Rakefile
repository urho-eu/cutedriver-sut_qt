############################################################################
##
## Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
## All rights reserved.
## Contact: Nokia Corporation (testabilitydriver@nokia.com)
##
## This file is part of TDriver.
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

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

$webdav_upload_disabled == false

require 'rubygems'
require 'fileutils'
require 'tmpdir'
require "bundler/setup"
require "version"

require File.expand_path(File.join(File.dirname(__FILE__), 'env'))
require File.expand_path(File.join(File.dirname(__FILE__), 'webdav'))
include DocumentDavupload

GEM_NAME = "cutedriver-sut-qt-plugin"

task :default do | task |
  puts "supported tasks: cruise, gem, gem_install, gem_uninstall, doc, doc[../tests], behaviours"
end

def delete_folder(folder)

  folder = File.expand_path(folder)

  if File.directory?( folder )
    puts "Deleting folder #{folder}"
    begin
      FileUtils.rm_r(folder)
    rescue Exception => exception
      abort("Error while deleting folder (%s: %s)" %[exception.class, exception.message])
    end
  end
end

def create_folder(folder)
  folder = File.expand_path(folder)

  unless File.directory?(folder)
    puts "Creating folder #{folder}"
    begin
      FileUtils.mkdir_p(folder)
    rescue Exception => exception
      abort("Error while creating folder (%s: %s)" %[exception.class, exception.message])
    end
  end
end

def copy_files(source, destination)
  destination = File.expand_path(destination)
  source = File.expand_path(source)
  create_folder(destination)

  puts "Copying #{File.dirname(source)} to #{File.join(destination)}"

  Dir.glob(source) do |entry|
    begin
      FileUtils.cp(entry, destination)
    rescue Exception => exception
      abort("Error while copying file (%s: %s)" %[exception.class, exception.message])
    end
  end
end

def run_tdriver_devtools(params, tests)
  begin
    command = "ruby #{File.expand_path(File.join(File.dirname( __FILE__ ), '../driver/lib/tdriver-devtools/tdriver-devtools.rb'))} #{params} -t #{tests}"
    puts command
    system(command)
  rescue LoadError
    begin
      require('tdriver/env')
      command = "ruby #{File.join(ENV['TDRIVER_PATH'], 'lib/tdriver-devtools/tdriver-devtools.rb')} #{params} -t #{tests}"
      puts command
      system(command)
    rescue LoadError
      abort("Unable to proceed due to TDriver/cuTeDriver not found or is too old! (required 0.9.2 or later)")
    end
  end
end

task :behaviours do |task|
  puts "\nGenerating behaviour XML files from implementation... "
  run_tdriver_devtools('-g behaviours lib behaviours', nil)
end

def doc_tasks(tasks, test_results_folder, tests_path_defined)
  #test_results_folder = File.expand_path( test_results_folder )

  if tests_path_defined == false
    puts "\nWarning: Test results folder not given, using default location (#{test_results_folder})"
    puts "\nSame as executing:\nrake doc[#{test_results_folder}]\n\n"
    sleep 1
  else
    puts "Using given test results from #{test_results_folder}"
  end

  # delete possibly existing output folder
  delete_folder('./doc/output/')

  # create it again
  create_folder('./doc/output/')

  # start generating documentation
  puts "\nGenerating documentation XML file..."

  tasks.each{ |task|
    case task[0]
    when :copy
      copy_files(*task[ 1 ])
    when :generate
      run_tdriver_devtools(*task[1])
    when :render
      run_tdriver_devtools(*task[1])
    else
      abort("Unknown task: #{task[0]}")
    end
  }
  puts "Done\n"
end

task :doc_upload do
  abort('Error: Unable to upload document due to WebDAV feature is disabled') if $webdav_upload_disabled == true

  if File.directory?("#{Dir.pwd}/doc/output/")
    puts "Upload current documentation to public web dav"
    puts "Please give your projects.forum.nokia cerendials"
    puts "Username:"
    username=STDIN.gets
    puts "Password:"
    password=STDIN.gets
    puts "Please give the document current type: , qt_windows or qt_symbian"
    puts "1 qt_linux"
    puts "2 qt_windows"
    puts "3 qt_linux"
    puts "4 enter the sut type"
    doc=STDIN.gets
    case doc
    when 1
      doc='qt_linux'
    when 2
      doc='qt_windows'
    when 3
      doc='qt_windows'
    else
      puts "Please give the document current type:"
      doc=STDIN.gets
    end
    puts "Please give the TDriver version number of previous documentation for archiving"
    version=STDIN.gets

    puts "Please give the proxy"
    proxy=STDIN.gets

    if username==nil
      puts "Username missing aborting..."
      exit(1)
    end
    if password==nil
      puts "Password missing aborting..."
      exit(1)
    end
    if doc==nil
      puts "Documentation missing aborting..."
      exit(1)
    end
    if version==nil
      puts "Previous version infromation missing aborting..."
      exit(1)
    end
    if proxy==nil
      puts "Proxy infromation missing aborting..."
      exit(1)
    end
    upload_doc_to_public_dav(username,password,doc,version,proxy)
  end
end

task :doc, :tests do |task, args|
  test_results_folder = args[:tests] || "../tests/test/feature_xml"

  doc_tasks(
    [
      [:generate, ["-d -g behaviours ../driver/lib/tdriver/ #{File.expand_path(File.join(Dir.tmpdir, "tdriver-devtools-behaviours"))}", test_results_folder]],
      [:copy, ['../driver/doc/images/*', './doc/output/images']],
      [:generate, ['-r -g both lib doc/output/document.xml', test_results_folder]],
      [:copy, ['./doc/images/*', './doc/output/images']]
    ],
    test_results_folder,
    !args[:tests].nil?
  )
end

task :doc_sut, :tests do |task, args|
  test_results_folder = args[:tests] || "../tests/test/feature_xml"

  doc_tasks(
    [
      [:generate, ['-d -r -g both lib doc/output/document.xml', test_results_folder]],
      [:copy, ['./doc/images/*', './doc/output/images']]
    ],
    test_results_folder,
    args[:tests].nil?
  )
end

desc "Task for uninstalling the generated gem"
task :gem_uninstall do
  puts "#########################################################"
  puts "### Uninstalling GEM #{GEM_NAME} ###"
  puts "#########################################################"

  FileUtils.rm(Dir.glob('*gem'))
  cmd = "gem uninstall #{GEM_NAME} -a -x -I"

  if RUBY_PLATFORM =~ /linux-gnu/
    cmd = "sudo " + "gem uninstall #{GEM_NAME} -a -x -I"
  end

  failure = system(cmd)
  raise "Uninstalling  #{GEM_NAME} failed" if (failure != true) or ($? != 0)
end

desc "Task for installing the generated gem"
task :gem_install do
  puts "#########################################################"
  puts "### Installing GEM  #{GEM_NAME} ###"
  puts "#########################################################"
  cmd = "gem install #{GEM_NAME}"

  if RUBY_PLATFORM =~ /linux-gnu/
    cmd = "sudo " + cmd
  end

  failure = system(cmd)
  raise "Installing #{GEM_NAME} failed" if (failure != true) or ($? != 0)
end

desc "Task for building the gem"
task :gem do
  cmd = "gem build cutedriver-driver.gemspec"
  failure = system(cmd)
  raise "Building #{GEM_NAME} failed" if (failure != true) or ($? != 0)
end

desc "Task for rebuilding and reinstalling the gem"
task :cruise => ['gem_uninstall', 'gem', 'gem_install'] do
end
