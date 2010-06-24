package com.aaronhardy.javaUtils.version
{
	import flash.events.Event;
	
	public class JavaValidationEvent extends Event
	{
		public static const JAVA_VALIDATED:String = 'javaValidated';
		public static const JAVA_INVALIDATED:String = 'javaInvalidated';
		public static const JAVA_NOT_FOUND:String = 'javaNotFound';
		public var major:uint;
		public var minor:uint;
		public var revision:uint;
		public var update:uint;
		
		public function JavaValidationEvent(type:String, major:uint=0, minor:uint=0, 
				revision:uint=0, update:uint=0)
		{
			super(type);
			this.major = major;
			this.minor = minor;
			this.revision = revision;
			this.update = update;
		}
		
		override public function clone():Event
		{
			return new JavaValidationEvent(type, major, minor, revision, update);
		}
	}
}