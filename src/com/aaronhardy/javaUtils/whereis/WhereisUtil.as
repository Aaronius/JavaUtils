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
package com.aaronhardy.javaUtils.whereis
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	
	import mx.utils.StringUtil;
	
	/**
	 * Dispatched if the executable is found.
	 */
	[Event(name="executableFound",type="com.aaronhardy.javaUtils.WhereisEvent")]
	
	/**
	 * Dispatched if the executable is not fouond.
	 */
	[Event(name="executableNotFound",type="com.aaronhardy.javaUtils.WhereisEvent")]
	
	/**
	 * Dispatched if an error occurs while searching for the executable.
	 */
	[Event(name="error",type="flash.events.ErrorEvent")]
	
	/**
	 * A utility that determines where an executable exists within the windows path as defined by
	 * the PATH environment variable.  Utilizes the whereis.exe utility provided by Synesis.
	 * @see http://www.synesis.com.au/systools.html
	 */
	public class WhereisUtil extends EventDispatcher
	{
		protected var nativeProcess:NativeProcess;
		protected var pathsFound:Boolean = false;
		
		/**
		 * Searches for a specified executable in the windows path.
		 */
		public function search(exeToFind:String, whereisPath:String):void
		{
			// Stop the previous query in case this is called multiple times.
			stopAndCleanUp();
			
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.executable = File.applicationDirectory.resolvePath(whereisPath);
			info.workingDirectory = File.applicationDirectory;
			
			var args:Vector.<String> = new Vector.<String>();
			args.push('-r');
			args.push('c:\\Windows\\SysWOW64;c:\\Windows\\System32'); // searches in the Windows paths (the directories specified in the PATH environment variable)
			args.push('-s'); // succinct output. Prints path only
			args.push(exeToFind);
			info.arguments = args;
			
			nativeProcess = new NativeProcess();
			addListeners();
			nativeProcess.start(info);
		}
		
		/**
		 * Adds listeners to the whereis process.
		 */
		protected function addListeners():void
		{
			if (nativeProcess)
			{
				nativeProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, outputDataHandler);
				nativeProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, standardErrorDataHandler);
				nativeProcess.addEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, ioErrorHandler);
				nativeProcess.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, ioErrorHandler);
				nativeProcess.addEventListener(NativeProcessExitEvent.EXIT, exitHandler);
			}
		}
		
		/**
		 * Removes listeners from the whereis utility.
		 */
		protected function removeListeners():void
		{
			if (nativeProcess)
			{
				nativeProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, outputDataHandler);
				nativeProcess.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, standardErrorDataHandler);
				nativeProcess.removeEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, ioErrorHandler);
				nativeProcess.removeEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, ioErrorHandler);
				nativeProcess.removeEventListener(NativeProcessExitEvent.EXIT, exitHandler);
			}
		}
		
		/**
		 * Handles output from the whereis process.  Each path found is on a separate line.
		 */
		protected function outputDataHandler(event:ProgressEvent):void
		{
			var output:String = nativeProcess.standardOutput.readUTFBytes(
					nativeProcess.standardOutput.bytesAvailable);
			var paths:Array = output.split('\n');
			
			// Make sure all entries are sanitized.
			for (var i:int = paths.length - 1; i >= 0; i--)
			{
				var path:String = StringUtil.trim(paths[i]);
				
				if (path.length == 0)
				{
					paths.splice(i, 1);
				}
				else
				{
					paths[i] = path;
				}
			}
			
			dispatchEvent(new WhereisEvent(WhereisEvent.EXECUTABLE_FOUND, paths));
			
			pathsFound = true;
			stopAndCleanUp();
		}
		
		/**
		 * Handles the event notifying that an error was reported from the whereis process.
		 */
		protected function standardErrorDataHandler(event:ProgressEvent):void
		{
			var output:String = StringUtil.trim(nativeProcess.standardError.readUTFBytes(
					nativeProcess.standardError.bytesAvailable));
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, 
					'The whereis query reported error: ' + output + '.'));
			stopAndCleanUp();
		}
		
		/**
		 * Handles the event notifying that an I/O error occured with the whereis process.
		 */
		protected function ioErrorHandler(event:IOErrorEvent):void
		{
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, 
					'The whereis query I/O connection closed unexpectedly.'));
			stopAndCleanUp();
		}
		
		/**
		 * Handles the exit event from the whereis process.
		 */
		protected function exitHandler(event:NativeProcessExitEvent):void
		{
			if (!pathsFound)
			{
				dispatchEvent(new WhereisEvent(WhereisEvent.EXECUTABLE_NOT_FOUND));
			}
			stopAndCleanUp();
		}
		
		/**
		 * Stops whereis process, if running, and cleans references for garbage collection.
		 */
		public function stopAndCleanUp():void
		{
			if (nativeProcess)
			{
				removeListeners();
				
				if (nativeProcess.running)
				{
					nativeProcess.exit(true);
				}
				
				nativeProcess = null;
				pathsFound = false;
			}
		}
	}
}