// Copyright (c) 2010 Aaron Hardy - http://aaronhardy.com
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
package com.aaronhardy.javaUtils.install
{
	import com.aaronhardy.javaUtils.whereis.WhereisEvent;
	import com.aaronhardy.javaUtils.whereis.WhereisUtil;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	
	import mx.core.Application;
	import mx.core.Window;
	import mx.core.WindowedApplication;
	import mx.utils.StringUtil;
	
	/**
	 * Event dispatched when the installation completes successfully.
	 */
	[Event(name="complete",type="com.aaronhardy.javaUtils.install.JavaInstallEvent")]
	
	/**
	 * Event dispatched when an error occurred while running the installation.
	 */
	[Event(name="error",type="flash.events.ErrorEvent")]
	
	/**
	 * A utility that initializes and monitors the installation of a java runtime environment on
	 * the Windows operating system.
	 */
	public class JavaInstallUtil extends EventDispatcher
	{
		protected var installerPath:String;
		protected var whereisPath:String;
		
		/**
		 * Initializes the installation.
		 * 
		 * @param installerPath The path, relative to the swf, to the JRE installation executable.
		 * @param whereisPath The path, relative to the swf, to the whereis utility executable.
		 */
		public function install(installerPath:String, whereisPath:String):void
		{
			// Stop the previous install in case this is called multiple times.
			stopAndCleanUp();
			
			this.installerPath = installerPath;
			this.whereisPath = whereisPath;
			
			getCmdPath();
		}
		
		//////////////////////////////////////////////////////////////////////
		// Find Cmd path
		//////////////////////////////////////////////////////////////////////
		
		protected var cmdPathWhereisUtil:WhereisUtil;
		
		/**
		 * Determines the path to cmd.
		 */
		protected function getCmdPath():void
		{
			cmdPathWhereisUtil = new WhereisUtil();
			addCmdWhereisListeners();
			cmdPathWhereisUtil.search('cmd.exe', whereisPath);
		}
		
		/**
		 * Adds listeners to the whereis utility.
		 */
		protected function addCmdWhereisListeners():void
		{
			if (cmdPathWhereisUtil)
			{
				cmdPathWhereisUtil.addEventListener(WhereisEvent.EXECUTABLE_FOUND, cmdFoundHandler);
				cmdPathWhereisUtil.addEventListener(WhereisEvent.EXECUTABLE_NOT_FOUND, cmdNotFoundHandler);
				cmdPathWhereisUtil.addEventListener(ErrorEvent.ERROR, cmdSearchErrorHandler);
			}
		}
		
		/**
		 * Removes listeners from the whereis utility.
		 */
		protected function removeCmdWhereisListeners():void
		{
			if (cmdPathWhereisUtil)
			{
				cmdPathWhereisUtil.removeEventListener(WhereisEvent.EXECUTABLE_FOUND, cmdFoundHandler);
				cmdPathWhereisUtil.removeEventListener(WhereisEvent.EXECUTABLE_NOT_FOUND, cmdNotFoundHandler);
				cmdPathWhereisUtil.removeEventListener(ErrorEvent.ERROR, cmdSearchErrorHandler);
			}
		}
		
		/**
		 * Handles the event notifying that cmd was found.
		 */
		protected function cmdFoundHandler(event:WhereisEvent):void
		{
			executeInstaller(String(event.paths[0]), installerPath);
		}
		
		/**
		 * Handles the event notifying that cmd was not found.
		 */
		protected function cmdNotFoundHandler(event:WhereisEvent):void
		{
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, 
					'Unable to find cmd.exe.'));
			stopAndCleanUp();
		}
		
		/**
		 * Handles the event notifying that an error occured while searching for cmd.
		 */
		protected function cmdSearchErrorHandler(event:ErrorEvent):void
		{
			dispatchEvent(event);
			stopAndCleanUp();
		}
		
		/**
		 * Stops utility if running and cleans references for garbage collection.
		 */
		protected function cleanCmdPathWhereisUtil():void
		{
			if (cmdPathWhereisUtil)
			{
				removeCmdWhereisListeners();
				cmdPathWhereisUtil.stopAndCleanUp();
				cmdPathWhereisUtil = null;
			}
		}	
		
		//////////////////////////////////////////////////////////////////////
		// Perform installation
		//////////////////////////////////////////////////////////////////////
		
		protected var installProcess:NativeProcess;
		
		/**
		 * After cmd is found, this begins the installation by running the installer through
		 * cmd. We need cmd to execute the installer in order to prompt the user for elevated 
		 * privileges for installation if necessary.  If we were to call the JRE installer directly 
		 * and elevated privileges were required, nothing would happen. No error, no prompt, 
		 * nothing.  AIR bug?
		 */
		protected function executeInstaller(cmdPath:String, installerPath:String):void
		{
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.executable = File.applicationDirectory.resolvePath(cmdPath);
			info.workingDirectory = File.applicationDirectory;
			
			var nativeInstallerPath:String = 
					File.applicationDirectory.resolvePath(installerPath).nativePath;
			
			var args:Vector.<String> = new Vector.<String>();
			args.push('/C');
			args.push(nativeInstallerPath);
			info.arguments = args;
			
			installProcess = new NativeProcess();
			addInstallListeners();
			installProcess.start(info);
		}

		/**
		 * Adds listeners to the install process.
		 */
		protected function addInstallListeners():void
		{
			if (installProcess)
			{
				installProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, standardErrorDataHandler);
				installProcess.addEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, ioErrorHandler);
				installProcess.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, ioErrorHandler);
				installProcess.addEventListener(NativeProcessExitEvent.EXIT, exitHandler);
			}
		}
		
		/**
		 * Removes listeners from the install process.
		 */
		protected function removeInstallListeners():void
		{
			if (installProcess)
			{
				installProcess.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, standardErrorDataHandler);
				installProcess.removeEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, ioErrorHandler);
				installProcess.removeEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, ioErrorHandler);
				installProcess.removeEventListener(NativeProcessExitEvent.EXIT, exitHandler);
			}
		}
		
		/**
		 * Handles the event notifying that an error was reported from the installer.
		 */
		protected function standardErrorDataHandler(event:ProgressEvent):void
		{
			var output:String = StringUtil.trim(installProcess.standardError.readUTFBytes(
					installProcess.standardError.bytesAvailable));
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, 
					'The java installation process reported error: ' + output + '.'));
			stopAndCleanUp();
		}
		
		/**
		 * Handles the event notifying that an I/O error occured with the installer.
		 */
		protected function ioErrorHandler(event:IOErrorEvent):void
		{
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, 
				'The java installation process I/O connection closed unexpectedly.'));
			stopAndCleanUp();
		}
		
		/**
		 * Handles the event notifying of installation exit.  The exit code will determine whether
		 * the installation was successful.
		 */ 
		protected function exitHandler(event:NativeProcessExitEvent):void
		{
			// Note that if the operation requires permission and the user does not give permission,
			// the exit code will be 0 even though the install process did not complete.
			if (event.exitCode == 0)
			{
				getJavaPath();
			}
			else
			{
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, 
						'The java installation process exited with error code ' + event.exitCode + '.'));
				stopAndCleanUp();
			}
		}
		
		protected function cleanInstallProcess():void
		{
			if (installProcess)
			{
				removeInstallListeners();
				
				if (installProcess.running)
				{
					installProcess.exit(true);
				}
				
				installProcess = null;
			}
		}
		
		//////////////////////////////////////////////////////////////////////
		// Retrieve Java Location
		//////////////////////////////////////////////////////////////////////
		
		protected var javaPathWhereisUtil:WhereisUtil;
		
		/**
		 * Determines the path to Java.
		 */
		protected function getJavaPath():void
		{
			javaPathWhereisUtil = new WhereisUtil();
			addJavaWhereisListeners();
			javaPathWhereisUtil.search('java.exe', whereisPath);
		}
		
		/**
		 * Adds listeners to the whereis utility.
		 */
		protected function addJavaWhereisListeners():void
		{
			if (javaPathWhereisUtil)
			{
				javaPathWhereisUtil.addEventListener(WhereisEvent.EXECUTABLE_FOUND, javaFoundHandler);
				javaPathWhereisUtil.addEventListener(WhereisEvent.EXECUTABLE_NOT_FOUND, javaNotFoundHandler);
				javaPathWhereisUtil.addEventListener(ErrorEvent.ERROR, javaSearchErrorHandler);
			}
		}
		
		/**
		 * Removes listeners from the whereis utility.
		 */
		protected function removeJavaWhereisListeners():void
		{
			if (javaPathWhereisUtil)
			{
				javaPathWhereisUtil.removeEventListener(WhereisEvent.EXECUTABLE_FOUND, javaFoundHandler);
				javaPathWhereisUtil.removeEventListener(WhereisEvent.EXECUTABLE_NOT_FOUND, javaNotFoundHandler);
				javaPathWhereisUtil.removeEventListener(ErrorEvent.ERROR, javaSearchErrorHandler);
			}
		}
		
		/**
		 * Handles the event notifying that java was found.
		 */
		protected function javaFoundHandler(event:WhereisEvent):void
		{
			dispatchEvent(new JavaInstallEvent(JavaInstallEvent.COMPLETE, String(event.paths[0])));
			stopAndCleanUp();
		}
		
		/**
		 * Handles the event notifying that java was not found.
		 */
		protected function javaNotFoundHandler(event:WhereisEvent):void
		{
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, 
				'Unable to find java.exe after installation.'));
			stopAndCleanUp();
		}
		
		/**
		 * Handles the event notifying that an error occured while searching for java.
		 */
		protected function javaSearchErrorHandler(event:ErrorEvent):void
		{
			dispatchEvent(event);
			stopAndCleanUp();
		}
		
		/**
		 * Stops utility if running and cleans references for garbage collection.
		 */
		protected function cleanJavaPathWhereisUtil():void
		{
			if (javaPathWhereisUtil)
			{
				removeJavaWhereisListeners();
				javaPathWhereisUtil.stopAndCleanUp();
				javaPathWhereisUtil = null;
			}
		}	
		
		/**
		 * Stops whereis utility and install process, if running, and cleans references for 
		 * garbage collection.
		 */
		public function stopAndCleanUp():void
		{
			cleanCmdPathWhereisUtil();
			cleanInstallProcess();
			cleanJavaPathWhereisUtil();
		}
	}
}