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
	
	import mx.controls.Alert;
	import mx.utils.StringUtil;
	
	[Event(name="executableFound",type="com.aaronhardy.javaUtils.WhereisEvent")]
	[Event(name="executableNotFound",type="com.aaronhardy.javaUtils.WhereisEvent")]
	[Event(name="error",type="flash.events.ErrorEvent")]
	public class WhereisUtil extends EventDispatcher
	{
		protected var nativeProcess:NativeProcess;
		protected var pathsFound:Boolean = false;
		
		public function getExePaths(exeToFind:String, whereisExePath:String):void
		{
			// Stop the previous query in case this is called multiple times.
			stopAndCleanUp();
			
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.executable = File.applicationDirectory.resolvePath(whereisExePath);
			info.workingDirectory = File.applicationDirectory;
			
			var args:Vector.<String> = new Vector.<String>();
			args.push('-p');
			args.push('-s');
			args.push(exeToFind);
			info.arguments = args;
			
			nativeProcess = new NativeProcess();
			addListeners();
			nativeProcess.start(info);
		}
		
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
		
		protected function outputDataHandler(event:ProgressEvent):void
		{
			var output:String = nativeProcess.standardOutput.readUTFBytes(
					nativeProcess.standardOutput.bytesAvailable);
			var paths:Array = output.split('\n');
			
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
		
		protected function standardErrorDataHandler(event:ProgressEvent):void
		{
			var output:String = StringUtil.trim(nativeProcess.standardError.readUTFBytes(
					nativeProcess.standardError.bytesAvailable));
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, 
					'The whereis query reported error: ' + output + '.'));
			stopAndCleanUp();
		}
		
		protected function ioErrorHandler(event:IOErrorEvent):void
		{
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, 
					'The whereis query I/O connection closed unexpectedly.'));
			stopAndCleanUp();
		}
		
		protected function exitHandler(event:NativeProcessExitEvent):void
		{
			if (!pathsFound)
			{
				dispatchEvent(new WhereisEvent(WhereisEvent.EXECUTABLE_NOT_FOUND));
			}
			stopAndCleanUp();
		}
		
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