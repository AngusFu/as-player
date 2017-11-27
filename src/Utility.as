/**
The MIT License (MIT)

Copyright (c) 2013-2015 SRS(ossrs)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package
{
    import flash.external.ExternalInterface;
    import flash.utils.setTimeout;

    /**
     * the utility functions.
     */
    public class Utility
    {
        /**
         * total log.
         */
        public static var logData:String = "";

        /**
         * whether string s endswith f.
         */
        public static function stringEndswith(s:String, f:String):Boolean {
            return s && f && s.indexOf(f) == s.length - f.length;
        }

        /**
         * whether string s startswith f.
         */
        public static function stringStartswith(s:String, f:String):Boolean {
            return s && f && s.indexOf(f) == 0;
        }

        /**
         * write log to trace and console.log.
         * @param msg the log message.
         */
        public static function log(js_id:String, msg:String):void {
			if (js_id) {
            	msg = "[" + new Date() +"][srs-player][" + js_id + "] " + msg;
			}

            logData += msg + "\n";

            trace(msg);

            if (!flash.external.ExternalInterface.available) {
                flash.utils.setTimeout(log, 300, null, msg);
                return;
            }

            ExternalInterface.call("SrsPlayer.log", msg);
        }
    }
}