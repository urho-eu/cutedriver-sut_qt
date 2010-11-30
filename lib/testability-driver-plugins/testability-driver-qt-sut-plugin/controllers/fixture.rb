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

module MobyController

	module QT

		module Fixture 
		  include MobyUtil::MessageComposer

			# Execute the command
			# Sends the message to the device using the @sut_adapter (see base class)     
			# == params         
			# == returns
			# == raises
			# NotImplementedError: raised if unsupported command type       
			def execute
				Kernel::raise ArgumentError.new( "Fixture '%s' not found for sut id '%s'" % [ @name, @sut_adapter.sut_id ] ) if ( plugin_params =  MobyUtil::Parameter[ @sut_adapter.sut_id.to_sym ][ :fixtures ][ @params[:name].to_sym, nil ] ).nil?

     		    fixture_plugin = plugin_params[:plugin]
				@sut_adapter.send_service_request(Comms::MessageGenerator.generate(make_fixture_message(fixture_plugin, @params)))

			end

			def set_adapter( adapter )
				@sut_adapter = adapter
			end

			# enable hooking for performance measurement & debug logging
			MobyUtil::Hooking.instance.hook_methods( self ) if defined?( MobyUtil::Hooking )


		end # Fixture

	end #module QT

end #module MobyController
