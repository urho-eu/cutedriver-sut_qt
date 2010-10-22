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

require 'nokogiri'

module MobyBehaviour

  module QT

	module SUT

	  include MobyBehaviour::Behaviour

	  @@_event_type_map = { :Mouse => '0', :Touch => '1', :Both => '2' }

	  # QT specific feature.
	  # Kills all of the application processed started through the server.
	  def kill_started_processes

		# execute the application control service request
		execute_command( MobyCommand::Application.new( :KillAll ) )

	  end

	  # Returns list of applications running on SUT known to qttasserver
	  # ==usage
	  # apps = sut.list_apps() #returns the xml containing applications and their names and process ids
	  # ==return
	  # String:: Xml string containing all applications and their names and process ids
	  def list_apps

		apps = nil

		begin
		  # execute the application control service request
		  apps = execute_command( MobyCommand::Application.new( :ListApps ) )
		  MobyUtil::Logger.instance.log "behaviour", "PASS;Successfully listed applications.;#{ id };sut;{};list_apps;"

		rescue Exception => e

		  MobyUtil::Logger.instance.log "behaviour", "FAIL;Failed to list applications.;#{ id };sut;{};list_apps;"
		  Kernel::raise RuntimeError.new( "Unable to list applications: Exception: #{ e.message } (#{ e.class })" )

		end

		apps     
	  end
	  
	  # Returns list of crashed applications running on SUT known to qttasserver
	  # ==usage
	  # apps = sut.list_crashed_apps()
	  # ==return
	  # String:: Xml string containing crashed applications, their names, process ids and crash times
	  def list_crashed_apps
		
		apps = nil

		begin
		  # execute the application control service request
		  apps = execute_command( MobyCommand::Application.new( :ListCrashedApps ) )
		  MobyUtil::Logger.instance.log "behaviour", "PASS;Successfully listed crashed applications.;#{ id };sut;{};list_crashed_apps;"
		rescue Exception => e
		  MobyUtil::Logger.instance.log "behaviour", "FAIL;Failed to list crashed applications.;#{ id };sut;{};list_crashed_apps;"
		  Kernel::raise RuntimeError.new( "Unable to list crashed applications: Exception: #{ e.message } (#{ e.class })" )
		end

		apps     
	  end

	  # Executes the given command as a new process
	  #
	  # === params
	  # command:: String containing the command to execute and any arguments
	  # param:: Hash with the flags for the command
	  # === returns
	  # String:: Output of the command, if any
	  # === raises
	  # ArgumentError:: The command argument was not a non empty String
	  def execute_shell_command(command, param = { :detached => "false"} )      
		Kernel::raise ArgumentError.new("The command argument must be a non empty String.") unless ( command.kind_of?( String ) and !command.empty? )
		Kernel::raise ArgumentError.new("The parameters argumet must be a Hash.") unless ( param.kind_of?(Hash) )

		if param[:detached].nil?
		  param[:detached] = "false"
		end
        
		param[:timeout].nil? ? timeout = 300 : timeout = param[:timeout].to_i

		# Launch the program execution into the background, wait for it to finish.
		if param[:wait].to_s == "true"
		  param[:threaded] = "true"
		  pid = execute_command( MobyCommand::Application.new( :Shell, command, nil, nil, nil, nil, nil, nil, param ) ).to_i
		  data = "" 
		  if pid != 0
			time = Time.new + timeout
			while true
			  obj = shell_command(pid)
			  sleep 1
			  data += obj['output']
			  if Time.new > time
				command_params = {:kill => 'true'}
				command_output = shell_command(pid, command_params)['output']
				Kernel::raise RuntimeError.new( "Timeout of #{timeout.to_s} seconds reached. #{command_output}")
			  elsif obj['status'] == "RUNNING"
				next
			  else 
				break
			  end
			end
		  end
		  return data
		end

		return execute_command( MobyCommand::Application.new( :Shell, command, nil, nil, nil, nil, nil, nil, param ) ).to_s
	  end

	  # Returns the command status of given shell command
	  #
	  # === params
	  # pid:: Integer of the process id given.
	  # param:: Hash with the flags for the command
	  # === returns
	  # Hash:: Information about the shell command.
	  # === raises
	  # ArgumentError:: The command argument was not a non empty String
	  def shell_command(pid, param = {} )
		Kernel::raise ArgumentError.new("pid argument should be positive integer.") unless pid.to_i > 0
		param[ :status ] = 'true'
		xml_source = execute_command( MobyCommand::Application.new( :Shell, pid.to_s, nil, nil, nil, nil, nil, nil, param ) ).to_s
		if param[:kill].nil?
		  xml = Nokogiri::XML(xml_source)
		  data = {}
		  xml.xpath("//object[@type = 'Response']/attributes/attribute").each { |attr|
			data[attr[:name]] = attr.children[0].content
		  }
		  return data
		else
		  # Killed processes have no relevant data.
		  data = {
			:status => "KILLED",
			:output => xml_source
		  }
		end
	  end


	  def system_information
		xml_source = execute_command( MobyCommand::Application.new( :SystemInfo, nil) )
		MobyBase::StateObject.new( xml_source )			  		
	  end


	  # returns the memory used by the agent if -1 then memory consumption cannot be read
	  def agent_mem_usage
		info = self.system_information
		begin 
		  info.MemoryStatus.attribute('qttasMemUsage').to_i
		rescue Exception => e
		  -1
		end
	  end

	  #returns the total memory of the sut if -1 then memory details cannot be read
	  def system_total_mem
		info = self.system_information
		begin 
		  info.MemoryStatus.attribute('total').to_i
		rescue Exception => e
		  -1
		end
	  end

	  #returns the available (free) memory of the sut if -1 then memory details cannot be read
	  def system_available_mem
		info = self.system_information
		begin 
		  info.MemoryStatus.attribute('available').to_i
		rescue Exception => e
		  -1
		end
	  end

	  # tap screen on given coordinates
	  # x:: X Coordinate to tap
	  # y:: Y Coordinate to tap
	  # time_to_hold:: How long is the ta pressed down, in seconds. default 0.1s
	  # == params
	  def tap_screen(x,y,time_to_hold = 0.1) # todo count
		
		command = MobyCommand::Tap.new(x,y,time_to_hold)

		begin 
		  execute_command( command )    				
		  nil
		rescue Exception => e      
		  
		  MobyUtil::Logger.instance.log "behaviour" , "FAIL;Failed tap_screen on coords \"#{x}:#{y}\";"
		  Kernel::raise e        
		  
		end      

	  end

	  def close_qttas
		begin
		  # execute the application control service request
		  apps = execute_command( MobyCommand::Application.new( :CloseQttas ) )
		  MobyUtil::Logger.instance.log "behaviour", "PASS;Successfully closed qttas.;#{ id };sut;{};close_qttas;"
		rescue Exception => e
		  MobyUtil::Logger.instance.log "behaviour", "FAIL;Failed to close qttas.;#{ id };sut;{};close_qttas;"
		  Kernel::raise RuntimeError.new( "Unable to close qttas: Exception: #{ e.message } (#{ e.class })" )
		end

	  end

    # == description
    # Starts process memory logging. Information about the given application's
    # heap memory usage will be stored in a file. In addition to application,
    # used log file can be specified as well as the type of timestamp and
    # interval length (in seconds).
    #
    # Note! Currently only supported on Symbian platform.
    #
    # == arguments
    # thread_name
    #  String
    #   description: Name of the application process/thread.
    #   example: 'testapp'
    #
    # file_name
    #  String
    #   description: Full name (containing path) of the used log file.
    #   example: 'c:\Data\proc_mem.log'
    #
    # timestamp_type
    #  String
    #   description: Type of the used timestamp, either "absolute" for
    #                current system time or "relative" or not specified for
    #                relative timestamp from 0 in milliseconds.
    #   example: 'absolute'
    #
    # interval_s
    #  Integer
    #   description: Logging interval in seconds.
    #   example: 2
    #
    # == returns
    # String
    #   description: Response message
    #   example: 'OK'
    #
	  def log_process_mem_start(thread_name, file_name = nil, timestamp_type = nil, interval_s = nil)
		status = nil
		begin
		  status = execute_command(
								   MobyCommand::Application.new(
																:ProcessMemLoggingStart,
																thread_name,
																nil, nil, nil, nil, nil, nil,
																{:file_name => file_name, :timestamp => timestamp_type, :interval_s => interval_s} ) )
		  MobyUtil::Logger.instance.log "behaviour", "PASS;Successfully started process memory logging.;#{ id };sut;{};log_process_mem_start;"
		rescue Exception => e
		  MobyUtil::Logger.instance.log "behaviour", "FAIL;Failed to start process memory logging.;#{ id };sut;{};log_process_mem_start;"
		  Kernel::raise RuntimeError.new( "Unable to start process memory logging: Exception: #{ e.message } (#{ e.class })" )
		end
		status
	  end

    # == description
    # Stops process memory logging. Logging of the given application's heap
    # memory usage is stopped. Either the full log file name or the log file
    # contents will be returned.
    #
    # Note! Currently only supported on Symbian platform.
    #
    # == arguments
    # thread_name
    #  String
    #   description: Name of the application process/thread.
    #   example: 'testapp'
    #
    # return_data
    #  String
    #   description: Should the log file data be returned in response message.
    #                If false, only the log file name will be returned.
    #   example: 'true'
    #
    # == returns
    # String
    #   description: Either the full log file name or the log file contents.
    #   example: 'OK'
    #
    def log_process_mem_stop(thread_name, return_data = nil)
		log = nil
		begin
		  log = execute_command(
								MobyCommand::Application.new(
															 :ProcessMemLoggingStop,
															 thread_name,
															 nil, nil, nil, nil, nil, nil,
															 {:return_data => return_data} ) )
		  MobyUtil::Logger.instance.log "behaviour", "PASS;Successfully stopped process memory logging.;#{ id };sut;{};log_process_mem_stop;"
		rescue Exception => e
		  MobyUtil::Logger.instance.log "behaviour", "FAIL;Failed to stop process memory logging.;#{ id };sut;{};log_process_mem_stop;"
		  Kernel::raise RuntimeError.new( "Unable to stop process memory logging: Exception: #{ e.message } (#{ e.class })" )
		end
		log
	  end

    # == description
    # Starts generating CPU load. Tries to generate CPU load as accurately as
    # it can but depending on other activities on the system it might vary.
    #
    # Note! Currently only supported on Symbian platform.
    #
    # == arguments
    # load
    #  Integer
    #   description: Requested CPU load in percentage.
    #   example: 50
    #
    # == returns
	  # NilClass
	  #   description: -
	  #   example: -
    #
    def cpu_load_start(load)
      begin
        status = execute_command(
                    MobyCommand::Application.new(
															 :CpuLoadStart,
															 nil, nil, nil, nil, nil, nil, nil,
															 {:cpu_load => load} ) )
        MobyUtil::Logger.instance.log "behaviour", "PASS;Successfully started generating CPU load.;#{ id };sut;{};cpu_load_start;"
      rescue Exception => e
        MobyUtil::Logger.instance.log "behaviour", "FAIL;Failed to start generating CPU load.;#{ id };sut;{};cpu_load_start;"
        Kernel::raise RuntimeError.new( "Unable to start generating CPU load: Exception: #{ e.message } (#{ e.class })" )
      end
    end

    # == description
    # Stops generating CPU load.
    #
    # Note! Currently only supported on Symbian platform.
    #
    # == returns
	  # NilClass
	  #   description: -
	  #   example: -
    #
    def cpu_load_stop
      begin
        status = execute_command(MobyCommand::Application.new(:CpuLoadStop) )
        MobyUtil::Logger.instance.log "behaviour", "PASS;Successfully started generating CPU load.;#{ id };sut;{};cpu_load_start;"
      rescue Exception => e
        MobyUtil::Logger.instance.log "behaviour", "FAIL;Failed to start generating CPU load.;#{ id };sut;{};cpu_load_start;"
        Kernel::raise RuntimeError.new( "Unable to start generating CPU load: Exception: #{ e.message } (#{ e.class })" )
      end
    end

	  def group_behaviours( interval, app, &block )
		begin		  
		  raise ArgumentError.new("Application must be defined!") unless app
		  raise ArgumentError.new("Interval must be a number.") unless interval.kind_of?(Numeric)

		  interval_millis = interval*1000 # to millis

		  # make one refresh before execution then freeze
		  app.force_refresh({:id => get_application_id})
		  self.freeze

		  #disable sleep to avoid unnecessary sleeping
		  MobyUtil::Parameter[ id ][ :sleep_disabled] = 'true'

		  ret = execute_command( MobyCommand::Group.new(interval_millis.to_i, app, block ) )

		  MobyUtil::Parameter[ id ][ :sleep_disabled] = 'false'

		  self.unfreeze

		  # the behaviour returns the amout of behaviours
		  # sleep to avoid sending messages to the app untill the 
		  # commands have been executed
		  sleep (ret*interval)

		  MobyUtil::Logger.instance.log "behaviour", "PASS;Successfully executed grouped behaviours.;#{ id };sut;{};group_behaviours;"
		rescue Exception => e
		  MobyUtil::Logger.instance.log "behaviour", "FAIL;Failed to execute grouped behaviours.;#{ id };sut;{};group_behaviours;"
		  Kernel::raise RuntimeError.new( "Unable to execute grouped behaviours: Exception: #{ e.message } (#{ e.class })" )
		end
	  end

	  # Set the event type used to interact with the target. Possible methods are :Mouse, :Touch and :Both.
	  # Event generation depends on this setting. If set to :Mouse or :Touch then only those events are generated.
	  # If set to :Both then both mouse and touch events are sent. In this situation touch events are set as primary.
	  # This setting has no affect when using multitouch. Note that if you generate multitouch type events e.g. a.tap_down, 
	  # b.tap_down then a.tap_up, b.tap_up you must set the type to :Touch to avoid mouse events to be generated.
	  # === params
	  # new_type:: Symbol defining which method to use: :Mouse, :Touch and :Both.
	  # === raises
	  # ArgumentError:: If invalid type is given.
	  def set_event_type(new_type)
 		raise ArgumentError.new("Invalid event type. Accepted values :" << @@_event_type_map.keys.join(", :") ) unless @@_event_type_map.include?(new_type)
		MobyUtil::Parameter[ self.id ][ :event_type] = @@_event_type_map[new_type]
	  end

	  # {:name => '', id => '', applicationUid => ''},[ {:objectName => '' , :className => , :text =>} ,..]
	  def find_object(app_details = nil, objects = nil)
		ret = execute_command( MobyCommand::FindObjectCommand.new(self, app_details, objects) )
	  end

	  # enable hooking for performance measurement & debug logging
	  MobyUtil::Hooking.instance.hook_methods( self ) if defined?( MobyUtil::Hooking )
	end 
  end

end
