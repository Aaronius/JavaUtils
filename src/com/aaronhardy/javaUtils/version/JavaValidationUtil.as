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
package com.aaronhardy.javaUtils.version
{
	import com.aaronhardy.javaUtils.whereis.WhereisEvent;
	import com.aaronhardy.javaUtils.whereis.WhereisUtil;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	
	import mx.utils.StringUtil;
	
	/**
	 * Dispatched when the java version has been determined and is equal to or greater than the
	 * required java version.  The event will have details regarding the currently installed java
	 * version.
	 */
	[Event(name="javaValidated",type="com.aaronhardy.javaUtils.version.JavaValidationEvent")]
	
	/**
	 * Dispatched when the java version has been determined and is less than the required java
	 * version.  The event will have details regarding the currently installed java version.
	 */
	[Event(name="javaInvalidated",type="com.aaronhardy.javaUtils.version.JavaValidationEvent")]
	
	/**
	 * Dispatched when the java version was not found.
	 */
	[Event(name="javaNotFound",type="com.aaronhardy.javaUtils.version.JavaValidationEvent")]
	
	/**
	 * Dispatched if an error occurred while determining the currently installed java version.
	 */
	[Event(name="error",type="flash.events.ErrorEvent")]
	
	/**
	 * A utility that determines if the user has the java runtime environment installed on their
	 * Windows system.  If a java runtime is found, it will be compared with a specified minimum
	 * java version to determine if it is the same version or newer.
	 */
	public class JavaValidationUtil extends EventDispatcher
	{
		protected var whereisPath:String;
		protected var minMajor:uint;
		protected var minMinor:uint;
		protected var minRevision:uint;
		protected var minUpdate:uint;
		
		/**
		 * Validates the user has Java installed and that is is the same version or newer than
		 * a specified version.
		 * 
		 * @param whereisPath The path, relative to the swf, to the whereis utility executable.
		 * @param minMajor The minimum major version the user's JRE must be in order to be 
		 *        considered valid.
		 * @param minMinor The minimum minor version the user's JRE must be in order to be
		 *        considered valid.
		 * @param minRevision The minimum revision version the user's JRE must be in order to be
		 *        considered valid.
		 * @param minUpdate The minimum update version the user's JRE must be in order to be
		 *        considered valid.
		 */
		public function validate(whereisPath:String, minMajor:uint, minMinor:uint, minRevision:uint, 
				minUpdate:uint):void
		{
			// If this function was called recently and the previous process is still running,
			// this will clean up the previous one.
			stopAndCleanUp();
			
			this.whereisPath = whereisPath;
			this.minMajor = minMajor;
			this.minMinor = minMinor;
			this.minRevision = minRevision;
			this.minUpdate = minUpdate;
			
			getJavaPath();
		}
		
		//////////////////////////////////////////////////////////////////////
		// Find Java Path
		//////////////////////////////////////////////////////////////////////
		
		protected var whereisUtil:WhereisUtil;
		protected var javaPath:String;
		
		/**
		 * Searches the Windows path (as specified in the Windows PATH variable) to find the java
		 * executable.
		 */
		protected function getJavaPath():void
		{
			whereisUtil = new WhereisUtil();
			addWhereisListeners();
			whereisUtil.search('java.exe', whereisPath);
		}
		
		/**
		 * Adds listeners to the whereis utility.
		 */
		protected function addWhereisListeners():void
		{
			if (whereisUtil)
			{
				whereisUtil.addEventListener(WhereisEvent.EXECUTABLE_FOUND, javaFoundHandler);
				whereisUtil.addEventListener(WhereisEvent.EXECUTABLE_NOT_FOUND, javaNotFoundHandler);
				whereisUtil.addEventListener(ErrorEvent.ERROR, errorHandler);
			}
		}
		
		/**
		 * Removes listeners from the whereis utility.
		 */
		protected function removeWhereisListeners():void
		{
			if (whereisUtil)
			{
				whereisUtil.removeEventListener(WhereisEvent.EXECUTABLE_FOUND, javaFoundHandler);
				whereisUtil.removeEventListener(WhereisEvent.EXECUTABLE_NOT_FOUND, javaNotFoundHandler);
				whereisUtil.removeEventListener(ErrorEvent.ERROR, errorHandler);
			}
		}
		
		/**
		 * Handles the event notifying that the path to the java executable was found.
		 */
		protected function javaFoundHandler(event:WhereisEvent):void
		{
			javaPath = String(event.paths[0]); 
			getVersion(javaPath);
			cleanWhereisUtil();
		}
		
		/**
		 * Handles the event notifying that the path to the java executable was not found.
		 */
		protected function javaNotFoundHandler(event:WhereisEvent):void
		{
			dispatchEvent(new JavaValidationEvent(JavaValidationEvent.JAVA_NOT_FOUND));
			stopAndCleanUp();
		}
		
		/**
		 * Handles the event notifying that an error occurred while looking for the java executable.
		 */
		protected function errorHandler(event:ErrorEvent):void
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
		// Retrieve Java Version
		//////////////////////////////////////////////////////////////////////
		
		protected var versionProcess:NativeProcess;
		
		/**
		 * Determines the version of the currently installed JRE.
		 */
		protected function getVersion(pathToJava:String):void
		{
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.executable = File.applicationDirectory.resolvePath(pathToJava);
			info.workingDirectory = File.applicationDirectory;
			
			var args:Vector.<String> = new Vector.<String>();
			args.push('-version');
			info.arguments = args;
			
			versionProcess = new NativeProcess();
			addVersionListeners();
			versionProcess.start(info);
		}
		
		/**
		 * Adds listeners to the version process.
		 */
		protected function addVersionListeners():void
		{
			if (versionProcess)
			{
				// Standard error is actually the one receiving the java version info.
				versionProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, outputDataHandler);
				versionProcess.addEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, ioErrorHandler);
				versionProcess.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, ioErrorHandler);
			}
		}
		
		/**
		 * Removes listeners from the version process.
		 */
		protected function removeVersionListeners():void
		{
			if (versionProcess)
			{
				versionProcess.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, outputDataHandler);
				versionProcess.removeEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, ioErrorHandler);
				versionProcess.removeEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, ioErrorHandler);
			}
		}
		
		/**
		 * Handles the output from the version process.  The version information is actually 
		 * reported through the standard error instead of standard out.  The versio is then
		 * compared to the required java version to determine if it is the same or newer.
		 */
		protected function outputDataHandler(event:ProgressEvent):void
		{
			// Java reports the version through standardError instead of standardOutput
			// See http://java.sun.com/j2se/versioning_naming.html for version naming conventions
			var output:String = StringUtil.trim(versionProcess.standardError.readUTFBytes(
					versionProcess.standardError.bytesAvailable));
			var versionRegEx:RegExp = /java version "(\d+).(\d+).(\d+)_*(\d+)*.*"/i;
			var versionMatches:Array = versionRegEx.exec(output) as Array;
			
			if (versionMatches)
			{
				var major:uint = versionMatches[1];
				var minor:uint = versionMatches[2];
				var revision:uint = versionMatches[3];
				var update:uint = 0;
				
				if (versionMatches.length > 4)
				{
					update = versionMatches[4];
				}
				
				if (compareVersions([major, minor, revision, update], 
						[minMajor, minMinor, minRevision, minUpdate]))
				{
					dispatchEvent(new JavaValidationEvent(JavaValidationEvent.JAVA_VALIDATED,
							major, minor, revision, update, javaPath));
				}
				else
				{
					dispatchEvent(new JavaValidationEvent(JavaValidationEvent.JAVA_INVALIDATED,
							major, minor, revision, update, javaPath));
				}
			}
			else
			{
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, 
						'Error parsing version in Java version output:\n' + output));
			}
			
			stopAndCleanUp();
		}
		
		/**
		 * Compares java versions to determine if the first is newer than the second.
		 * 
		 * @param version1 An array where the first index is the major version, the second index
		 *        is the minor version, and so on.
		 * @param version2 An array where the first index is the major version, the second index
		 *        is the minor version, and so on.
		 * @return Whether the first version is equal to or greater than the second version.
		 */
		protected function compareVersions(version1:Array, version2:Array):Boolean
		{
			// Remember that 1.0.0_0 is greater than 0.9.9_9. If you make this algorithm too
			// simple that can be overlooked.
			var compare:Function = function(version1:Array, version2:Array, index:uint):Boolean
			{
				if (index > version1.length - 1 || index > version2.length - 1 ||
						version1[index] > version2[index])
				{
					return true;
				}
				else if (version1[index] < version2[index])
				{
					return false;
				}
				else
				{
					return compare(version1, version2, index + 1)
				}
			}
			
			return compare(version1, version2, 0);
		}
		
		/**
		 * Handles the event notifying there was an error when attempting to determin the JRE
		 * version.
		 */
		protected function ioErrorHandler(event:IOErrorEvent):void
		{
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, 
				'The version query I/O connection closed unexpectedly.'));
			stopAndCleanUp();
		}
		
		/**
		 * Stops process if running and cleans references for garbage collection.
		 */
		protected function cleanVersionProcess():void
		{
			if (versionProcess)
			{
				removeVersionListeners();
				
				if (versionProcess.running)
				{
					versionProcess.exit(true);
				}
				
				versionProcess = null;
			}
		}
		
		/**
		 * Stops whereis utility and version process, if running, and cleans references for 
		 * garbage collection.
		 */
		public function stopAndCleanUp():void
		{
			cleanWhereisUtil();
			cleanVersionProcess();
		}
	}
}