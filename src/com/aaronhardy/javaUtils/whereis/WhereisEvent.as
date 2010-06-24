package com.aaronhardy.javaUtils.whereis
{
	import flash.events.Event;
	
	public class WhereisEvent extends Event
	{
		public static const EXECUTABLE_FOUND:String = 'executableFound';
		public static const EXECUTABLE_NOT_FOUND:String = 'executableNotFound';
		public var paths:Array;
		
		public function WhereisEvent(type:String, paths:Array=null)
		{
			super(type);
			this.paths = paths;
		}
		
		override public function clone():Event
		{
			return new WhereisEvent(type, paths);
		}
	}
}