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
	import flash.events.Event;
	
	/**
	 * Event reporting on the validation of the currently installed JRE. The currently installed
	 * JRE version information is available for JAVA_VALIDATED and JAVA_INVALIDATED but not 
	 * JAVA_NOT_FOUND.
	 */
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