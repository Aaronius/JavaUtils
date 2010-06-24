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
	
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.core.Window;
	import mx.core.WindowedApplication;
	import mx.utils.StringUtil;
	
	/**
	 * Event dispatched when the installation completes successfully.
	 */
	[Event(name="complete",type="flash.events.Event")]
	
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
		
		protected var whereisUtil:WhereisUtil;
		
		/**
		 * Determines the path to cmd.
		 */
		protected function getCmdPath():void
		{
			whereisUtil = new WhereisUtil();
			addWhereisListeners();
			whereisUtil.getExePaths('cmd.exe', whereisPath);
		}
		
		/**
		 * Adds listeners to the whereis utility.
		 */
		protected function addWhereisListeners():void
		{
			if (whereisUtil)
			{
				whereisUtil.addEventListener(WhereisEvent.EXECUTABLE_FOUND, cmdFoundHandler);
				whereisUtil.addEventListener(WhereisEvent.EXECUTABLE_NOT_FOUND, cmdNotFoundHandler);
				whereisUtil.addEventListener(ErrorEvent.ERROR, cmdSearchErrorHandler);
			}
		}
		
		/**
		 * Removes listeners from the whereis utility.
		 */
		protected function removeWhereisListeners():void
		{
			if (whereisUtil)
			{
				whereisUtil.removeEventListener(WhereisEvent.EXECUTABLE_FOUND, cmdFoundHandler);
				whereisUtil.removeEventListener(WhereisEvent.EXECUTABLE_NOT_FOUND, cmdNotFoundHandler);
				whereisUtil.removeEventListener(ErrorEvent.ERROR, cmdSearchErrorHandler);
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
		protected function cleanWhereisUtil():void
		{
			if (whereisUtil)
			{
				removeWhereisListeners();
				whereisUtil.stopAndCleanUp();
				whereisUtil = null;
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
				dispatchEvent(new Event(Event.COMPLETE));
			}
			else
			{
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, 
						'The java installation process exited with error code ' + event.exitCode + '.'));
			}
			stopAndCleanUp();
		}
		
		/**
		 * Stops whereis utility and install process, if running, and cleans references for 
		 * garbage collection.
		 */
		public function stopAndCleanUp():void
		{
			if (whereisUtil)
			{
				removeWhereisListeners();
				whereisUtil.stopAndCleanUp();
				whereisUtil = null;
			}
			
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
	}
}