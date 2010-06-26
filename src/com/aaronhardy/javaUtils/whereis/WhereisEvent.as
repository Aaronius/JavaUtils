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
	import flash.events.Event;
	
	/**
	 * Event reporting whether the specified executable was found by the whereis utility.
	 * If EXECUTABLE_FOUND, paths will contain all the paths found for the executable.
	 */
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