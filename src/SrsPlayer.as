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

/**
 *modofied by wemlion
 */
package
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetStream;
	import flash.system.Security;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	

	[SWF(backgroundColor="#000000", frameRate="60", width="480", height="270")]
    public class SrsPlayer extends Sprite
    {
        // user set id.
        private var js_id:String = null;
        // user set callback
        private var js_on_player_ready:String = null;
        private var js_on_player_metadata:String = null;
        private var js_on_player_timer:String = null;
        private var js_on_player_empty:String = null;
        private var js_on_player_full:String = null;
		private var js_on_player_status:String = null;

        // play param, user set width and height
        private var user_w:int = 0;
        private var user_h:int = 0;
        private var user_buffer_time:Number = 0;
        private var user_max_buffer_time:Number = 0;
		private var user_volume:Number = 0;
		private var user_volume_grade:int = 0;
        // user set dar den:num
        private var user_dar_den:int = 0;
        private var user_dar_num:int = 0;
        // user set fs(fullscreen) refer and percent.
        private var user_fs_refer:String = null;
        private var user_fs_percent:int = 0;
        
        // media specified.
        private var media_video:Video = null;
        private var media_metadata:Object = {};
        private var media_timer:Timer = new Timer(300);

        // the common player to play stream.
        private var player:Player = null;
        // the flashvars config.
        private var config:Object = null;
        
        public function SrsPlayer()
        {
            if (!this.stage) {
                this.addEventListener(Event.ADDED_TO_STAGE, this.system_on_add_to_stage);
            } else {
                this.system_on_add_to_stage(null);
            }
        }

        /**
        * system event callback, when this control added to stage.
        * the main function.
        */
        private function system_on_add_to_stage(evt:Event):void {
			log("system_on_add_to_stage");
			this.removeEventListener(Event.ADDED_TO_STAGE, this.system_on_add_to_stage);

			// Allow JS calls from other domains
			Security.allowDomain("*");
			Security.allowInsecureDomain("*");
			// Security.loadPolicyFile('https://s1.ssl.qhres.com/crossdomain.xml');

            this.stage.align = StageAlign.TOP_LEFT;
            this.stage.scaleMode = StageScaleMode.NO_SCALE;

			this.initializeControls();
			this.stage.addEventListener(FullScreenEvent.FULL_SCREEN, this.user_on_stage_fullscreen);
			// toggle playing on space key
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, function (e: KeyboardEvent): void {
				switch (e.keyCode) {
					case 32:
						togglePlay();
				}
			});
			
            this.contextMenu = new ContextMenu();
            this.contextMenu.hideBuiltInItems();
            
            var flashvars:Object = this.root.loaderInfo.parameters;
            
            if (!flashvars.hasOwnProperty("id")) {
                throw new Error("must specifies the id");
            }

            this.config = flashvars;
            this.js_id = flashvars.id;
            this.js_on_player_ready = flashvars.on_player_ready;
            this.js_on_player_metadata = flashvars.on_player_metadata;
            this.js_on_player_timer = flashvars.on_player_timer;
            this.js_on_player_empty = flashvars.on_player_empty;
            this.js_on_player_full = flashvars.on_player_full;
			this.js_on_player_status = flashvars.on_player_status;
            
            this.media_timer.addEventListener(TimerEvent.TIMER, this.system_on_timer);
            this.media_timer.start();
            
            flash.utils.setTimeout(this.system_on_js_ready, 0);
        }
        
        /**
         * system callack event, when js ready, register callback for js.
         * the actual main function.
         */
        private function system_on_js_ready():void {
            if (!flash.external.ExternalInterface.available) {
                log("js not ready, try later.");
                flash.utils.setTimeout(this.system_on_js_ready, 100);
                return;
            }
            
            flash.external.ExternalInterface.addCallback("__play", this.js_call_play);
            flash.external.ExternalInterface.addCallback("__stop", this.js_call_stop);
            flash.external.ExternalInterface.addCallback("__pause", this.js_call_pause);
            flash.external.ExternalInterface.addCallback("__resume", this.js_call_resume);
            flash.external.ExternalInterface.addCallback("__set_dar", this.js_call_set_dar);
            flash.external.ExternalInterface.addCallback("__set_fs", this.js_call_set_fs_size);
            flash.external.ExternalInterface.addCallback("__set_bt", this.js_call_set_bt);
            flash.external.ExternalInterface.addCallback("__set_mbt", this.js_call_set_mbt);
            flash.external.ExternalInterface.addCallback("__dump_log", this.js_call_dump_log);
            
            flash.external.ExternalInterface.call(this.js_on_player_ready, this.js_id);
        }
        
        /**
        * system callack event, timer to do some regular tasks.
        */
        private function system_on_timer(evt:TimerEvent):void {
            if (!player) {
                return;
            }

            var ms:NetStream = player.stream();
            
            if (!ms) {
                log("stream is null, ignore timer event.");
                return;
            }
            
            var rtime:Number = flash.utils.getTimer();
            var bitrate:Number = Number((ms.info.videoBytesPerSecond + ms.info.audioBytesPerSecond) * 8 / 1000);
            log("on timer, time=" + ms.time.toFixed(2) + "s, buffer=" + ms.bufferLength.toFixed(2) + "s" 
                + ", bitrate=" + bitrate.toFixed(1) + "kbps"
                + ", fps=" + ms.currentFPS.toFixed(1)
                + ", rtime=" + rtime.toFixed(0)
            );
            flash.external.ExternalInterface.call(
                this.js_on_player_timer, this.js_id, ms.time, ms.bufferLength,
                bitrate, ms.currentFPS, rtime
            );
        }
        
        /**
         * system callback event, when stream is empty.
         */
        private function system_on_buffer_empty():void {
            var time:Number = flash.utils.getTimer();
            log("stream is empty at " + time + "ms");
            flash.external.ExternalInterface.call(this.js_on_player_empty, this.js_id, time);
        }
        private function system_on_buffer_full():void {
            var time:Number = flash.utils.getTimer();
            log("stream is full at " + time + "ms");
            flash.external.ExternalInterface.call(this.js_on_player_full, this.js_id, time);
        }
        
        /**
         * system callack event, when got metadata from stream.
         * or got video dimension change event(the DAR notification), to update the metadata manually.
         */
        private function system_on_metadata(metadata:Object):void {
            if (!media_metadata) {
                media_metadata = {};
            }
            for (var k:String in metadata) {
                media_metadata[k] = metadata[k];
            }

            // update the debug info.
            on_debug_info(media_metadata);
            update_context_items();

            // for js.
            var obj:Object = __get_video_size_object();
            
            // obj.server = 'srs';
            obj.contributor = 'winlin';
            
            if (srs_server != null) {
                obj.server = srs_server;
            }
            if (srs_primary != null) {
                obj.contributor = srs_primary;
            }
            if (srs_authors != null) {
                obj.contributor = srs_authors;
            }
            if (srs_id != null) {
                obj.cid = srs_id;
            }
            if (srs_pid != null) {
                obj.pid = srs_pid;
            }
            if (srs_server_ip != null) {
                obj.ip = srs_server_ip;
            }
            
            var s:String = "";
            for (var key:String in obj) {
                s += key + "=" + obj[key] + " ";
            }
            log("metadata is " + s);
            
            var code:int = flash.external.ExternalInterface.call(js_on_player_metadata, js_id, obj);
            if (code != 0) {
                throw new Error("callback on_player_metadata failed. code=" + code);
            }
        }
        
        /**
         * player callack event, when user click video to enter or leave fullscreen.
         */
        private function user_on_stage_fullscreen(evt:FullScreenEvent):void {
			log("user_on_stage_fullscreen");
            if (!evt.fullScreen) {
                __execute_user_set_dar();
            } else {
                __execute_user_enter_fullscreen();
            }
        }
        
        /**
         * user event callback, js cannot enter the fullscreen mode, user must click to.
         */
        private function user_on_click_toggle_fullscreen(evt:MouseEvent):void {
            if (!this.stage.allowsFullScreen) {
                log("donot allow fullscreen.");
                return;
            }
            
            // enter fullscreen to get the fullscreen size correctly.
            if (this.stage.displayState == StageDisplayState.FULL_SCREEN) {
                this.stage.displayState = StageDisplayState.NORMAL;
            } else {
                this.stage.displayState = StageDisplayState.FULL_SCREEN;
            }
        }
        
        /**
         * function for js to call: to pause the stream. ignore if not play.
         */
        private function js_call_pause():void {
            if (player && player.stream()) {
                player.streamPause();
                log("user pause play");
            }
        }
        
        /**
         * function for js to call: to resume the stream. ignore if not play.
         */
        private function js_call_resume():void {
            if (player && player.stream()) {
                player.streamResume();
                log("user resume play");
            }
        }

        /**
         * dumps all log data.
         */
        private function js_call_dump_log():String {
            return Utility.logData;
        }
        
        /**
        * to set the DAR, for example, DAR=16:9 where num=16,den=9.
        * @param num, for example, 16. 
        *       use metadata width if 0.
        *       use user specified width if -1.
        * @param den, for example, 9. 
        *       use metadata height if 0.
        *       use user specified height if -1.
         */
        private function js_call_set_dar(num:int, den:int):void {
            user_dar_num = num;
            user_dar_den = den;
            
            flash.utils.setTimeout(__execute_user_set_dar, 0);
            log("user set dar to " + num + "/" + den);
        }
        
        /**
         * set the fullscreen size data.
         * @refer the refer fullscreen mode. it can be:
         *       video: use video orignal size.
         *       screen: use screen size to rescale video.
         * @param percent, the rescale percent, where
         *       100 means 100%.
         */
        private function js_call_set_fs_size(refer:String, percent:int):void {
            user_fs_refer = refer;
            user_fs_percent = percent;
            log("user set refer to " + refer + ", percent to" + percent);
        }
        
        /**
         * set the stream buffer time in seconds.
         * @buffer_time the buffer time in seconds.
         */
        private function js_call_set_bt(buffer_time:Number):void {
            if (player && player.stream()) {
                player.stream().bufferTime = buffer_time;
                log("user set bufferTime to " + buffer_time.toFixed(2) + "s");
            }
        }
        
        /**
         * set the max stream buffer time in seconds.
         * @max_buffer_time the max buffer time in seconds.
         * @remark this is the key feature for realtime communication by flash.
         */
        private function js_call_set_mbt(max_buffer_time:Number):void {
            if (player && player.stream()) {
                player.stream().bufferTimeMax = max_buffer_time;
                log("user set bufferTimeMax to " + max_buffer_time.toFixed(2) + "s");
            }
        }
        
        /**
         * function for js to call: to stop the stream. ignore if not play.
         */
        private function js_call_stop():void {
            if (this.media_video) {
                this.removeChild(this.media_video);
                this.media_video = null;
            }

            if (player) {
                player.close();
                player = null;
            }
            log("player stopped");
        }
        
		private function togglePlay(): void {	
			if (player.isPaused) {
				player.streamResume();
			} else {
				player.streamPause();
			}
			// 更新播放暂停按钮
			drawPlayButton();
			// 更新中心暂停按钮
			if (player.isPaused) {
				ctrl_mask.addChild(ctrl_center_pause);
				ctrl_center_pause.addEventListener(MouseEvent.CLICK, togglePlay);
			} else {
				ctrl_mask.removeChild(ctrl_center_pause);
				ctrl_center_pause.removeEventListener(MouseEvent.CLICK, togglePlay);
			}
		}
		
        // srs infos
        private var srs_server:String = null;
        private var srs_primary:String = null;
        private var srs_authors:String = null;
        private var srs_id:String = null;
        private var srs_pid:String = null;
        private var srs_server_ip:String = null;
        private function update_context_items():void {
            // for context menu
            var customItems:Array = [new ContextMenuItem("base on SrsPlayer")];
            if (srs_server != null) {
                customItems.push(new ContextMenuItem("Server: " + srs_server));
            }
            if (srs_primary != null) {
                customItems.push(new ContextMenuItem("Primary: " + srs_primary));
            }
            if (srs_authors != null) {
                customItems.push(new ContextMenuItem("Authors: " + srs_authors));
            }
            if (srs_server_ip != null) {
                customItems.push(new ContextMenuItem("SrsIp: " + srs_server_ip));
            }
            if (srs_pid != null) {
                customItems.push(new ContextMenuItem("SrsPid: " + srs_pid));
            }
            if (srs_id != null) {
                customItems.push(new ContextMenuItem("SrsId: " + srs_id));
            }
            contextMenu.customItems = customItems;
        }
        
        /**
         * server can set the debug info in _result of RTMP connect, or metadata.
         */
        private function on_debug_info(data:*):void {
            if (data.hasOwnProperty("srs_server")) {
                srs_server = data.srs_server;
            }
            if (data.hasOwnProperty("srs_primary")) {
                srs_primary = data.srs_primary;
            }
            if (data.hasOwnProperty("srs_authors")) {
                srs_authors = data.srs_authors;
            }
            if (data.hasOwnProperty("srs_id")) {
                srs_id = data.srs_id;
            }
            if (data.hasOwnProperty("srs_pid")) {
                srs_pid = data.srs_pid;
            }
            if (data.hasOwnProperty("srs_server_ip")) {
                srs_server_ip = data.srs_server_ip;
            }
        }
        
        /**
         * function for js to call: to play the stream. stop then play.
         * @param url, the rtmp/http url to play.
         * @param _width, the player width.
         * @param _height, the player height.
         * @param buffer_time, the buffer time in seconds. recommend to >=0.5
         * @param max_buffer_time, the max buffer time in seconds. recommend to 3 x buffer_time.
         * @param volume, the volume, 0 is mute, 1 is 100%, 2 is 200%.
         */
        private function js_call_play(url:String, _width:int, _height:int, buffer_time:Number, max_buffer_time:Number, volume:Number):void {
            this.user_w = _width;
            this.user_h = _height;
            this.user_buffer_time = buffer_time;
            this.user_max_buffer_time = max_buffer_time;
            this.user_volume = volume;
            log("start to play url: " + url + ", w=" + this.user_w + ", h=" + this.user_h
                + ", buffer=" + buffer_time.toFixed(2) + "s, max_buffer=" + max_buffer_time.toFixed(2) + "s, volume=" + volume.toFixed(2)
            );
            
            js_call_stop();
			
			// trim last ?
			while (Utility.stringEndswith(url, "?")) {
				url = url.substr(0, url.length - 1);
			}

            // create player.
            player = new Player(this);

            // init player by config.
            player.init(config);

            // play the url.
            player.play(url);
        }
        public function on_player_before_play():void {
            if (!player) {
                return;
            }

            var ms:NetStream = player.stream();
            if (!ms) {
                return;
            }
	
			var v:Number = user_volume;
			user_volume_grade = v == 0 ? 0 : (v < 1/3 ? 1 : (v < 2/3 ? 2 : 3));
            ms.soundTransform = new SoundTransform(user_volume);
            ms.bufferTime = user_buffer_time;
            ms.bufferTimeMax = user_max_buffer_time;
            ms.client = {};
            ms.client.onMetaData = system_on_metadata;
        }
        public function on_player_play():void {
            if (!player) {
                return;
            }
			
			// 先移除
			if (media_video) {
				removeChild(media_video);
			}
            media_video = new Video();
            media_video.width = user_w;
            media_video.height = user_h;
            media_video.attachNetStream(player.stream());
            media_video.smoothing = true;
            addChild(media_video);

            __draw_black_background(user_w, user_h);

            // lowest layer, for mask to cover it.
            setChildIndex(media_video, 0);
        }
        public function on_player_metadata(data:Object):void {
            system_on_metadata(data);
        }
        public function on_player_302(url:String):void {
            setTimeout(function():void{
                log("Async RTMP 302 Redirected.");
                js_call_play(url, user_w, user_h, user_buffer_time, user_max_buffer_time, user_volume);
            }, 1000);
        }
        public function on_player_dimension_change():void {
            system_on_metadata(media_metadata);
        }
        public function on_player_buffer_empty():void {
            system_on_buffer_empty();
        }
        public function on_player_buffer_full():void {
            system_on_buffer_full();
        }
		
		public function on_player_status(code:String, desc:String):void {
			log("[STATUS] code=" + code + ", desc=" + desc);
			flash.external.ExternalInterface.call(this.js_on_player_status, this.js_id, code, desc);
		}
        
        /**
        * get the "right" size of video,
        * 1. initialize with the original video object size.
        * 2. override with metadata size if specified.
        * 3. override with codec size if specified.
        */
        private function __get_video_size_object():Object {
			if (!media_video) {
				return {};
			}
            var obj:Object = {
                width: media_video.width,
                height: media_video.height
            };
            
            // override with metadata size.
            if (this.media_metadata.hasOwnProperty("width")) {
                obj.width = this.media_metadata.width;
            }
            if (this.media_metadata.hasOwnProperty("height")) {
                obj.height = this.media_metadata.height;
            }
            
            // override with codec size.
            if (media_video.videoWidth > 0) {
                obj.width = media_video.videoWidth;
            }
            if (media_video.videoHeight > 0) {
                obj.height = media_video.videoHeight;
            }
            
            return obj;
        }
        
        /**
        * execute the enter fullscreen action.
        */
        private function __execute_user_enter_fullscreen():void {
            if (!user_fs_refer || user_fs_percent <= 0) {
                return;
            }
            
            // change to video size if refer to video.
            var obj:Object = __get_video_size_object();
            
            // get the DAR
            var den:int = user_dar_den;
            var num:int = user_dar_num;
            
            if (den == 0) {
                den = obj.height;
            }
            if (den == -1) {
                den = this.stage.fullScreenHeight;
            }
            
            if (num == 0) {
                num = obj.width;
            }
            if (num == -1) {
                num = this.stage.fullScreenWidth;
            }
                
            // for refer is screen.
            if (user_fs_refer == "screen") {
                obj = {
                    width: this.stage.fullScreenWidth,
                    height: this.stage.fullScreenHeight
                };
            }
            
            // rescale to fs
            __update_video_size(num, den, 
                obj.width * user_fs_percent / 100, 
                obj.height * user_fs_percent / 100, 
                this.stage.fullScreenWidth, this.stage.fullScreenHeight
            );
        }
        
        /**
         * for user set dar, or leave fullscreen to recover the dar.
         */
        private function __execute_user_set_dar():void {
            // get the DAR
            var den:int = user_dar_den;
            var num:int = user_dar_num;
            
            var obj:Object = __get_video_size_object();
            
            if (den == 0) {
                den = obj.height;
            }
            if (den == -1) {
                den = this.user_h;
            }
            
            if (num == 0) {
                num = obj.width;
            }
            if (num == -1) {
                num = this.user_w;
            }
            
            __update_video_size(num, den, this.user_w, this.user_h, this.user_w, this.user_h);
        }
        
        /**
        * update the video width and height, 
        * according to the specifies DAR(den:num) and max size(w:h).
        * set the position of video(x,y) specifies by size(sw:sh),
        * and update the bg to size(sw:sh).
        * @param _num/_den the DAR. use to rescale the player together with paper size.
        * @param _w/_h the video draw paper size. used to rescale the player together with DAR.
        * @param _sw/_wh the stage size, >= paper size. used to center the player.
        */
        private function __update_video_size(_num:int, _den:int, _w:int, _h:int, _sw:int, _sh:int):void {
            if (!this.media_video || _den <= 0 || _num <= 0) {
                return;
            }
            
            // set DAR.
            // calc the height by DAR
            var _height:int = _w * _den / _num;
            if (_height <= _h) {
                this.media_video.width = _w;
                this.media_video.height = _height;
            } else {
                // height overflow, calc the width by DAR
                var _width:int = _h * _num / _den;
                
                this.media_video.width = _width;
                this.media_video.height = _h;
            }
            
            // align center.
            this.media_video.x = (_sw - this.media_video.width) / 2;
            this.media_video.y = (_sh - this.media_video.height) / 2;
            
            __draw_black_background(_sw, _sh);
        }
        
        /**
        * draw black background and draw the fullscreen mask.
        */
		private const dimension: Object = {};
        private function __draw_black_background(_width:int, _height:int):void {
            // draw black bg.
            this.graphics.beginFill(0x00, 1.0);
            this.graphics.drawRect(0, 0, _width, _height);
            this.graphics.endFill();
			dimension.w = _width;
			dimension.h = _height;

			this.redraw();
        }
        
        private function log(msg:String):void {
           Utility.log(js_id, msg);
        }
		
		private var ctrl_center_pause: Sprite = new Sprite();
		private var ctrl_mask: Sprite = new Sprite();
		private var ctrl_con: Sprite = new Sprite();
		private var ctrl_con_bg: Sprite = new Sprite();
		private var play_pause_btn: Sprite = new Sprite();
		private var expand_btn: Sprite = new Sprite();
		private var volume_status_btn: Sprite = new Sprite();
		
		private function initializeControls(): void {
			var self: SrsPlayer = this;
			// 添加舞台 mask
			addChild(ctrl_mask);
			ctrl_mask.addEventListener(MouseEvent.CLICK, function (e: MouseEvent): void {
				self.togglePlay();
			});
			
			// 居中的暂停按钮
			bindHoverEffect(ctrl_center_pause);
			
			// 底部控制部分
			addChild(ctrl_con);
			bindFadeEffect(ctrl_con);

			// 绘制控制部分背景
			ctrl_con.addChild(ctrl_con_bg);

			// 绘制左侧播放/暂停按钮
			ctrl_con.addChild(play_pause_btn);
			bindHoverEffect(play_pause_btn);
			play_pause_btn.addEventListener(MouseEvent.CLICK, function (e: MouseEvent): void {
				togglePlay();
			});
			
			// 绘制右侧全屏按钮
			ctrl_con.addChild(expand_btn);
			bindHoverEffect(expand_btn);
			expand_btn.addEventListener(MouseEvent.CLICK, this.user_on_click_toggle_fullscreen);
			
			// 音量
			ctrl_con.addChild(volume_status_btn);
			bindHoverEffect(volume_status_btn);
			var v_timer: uint;
			volume_status_btn.addEventListener(MouseEvent.CLICK, function (): void {
				clearTimeout(v_timer);
				v_timer = setTimeout(function (): void {
					var ms:NetStream = player.stream();
					user_volume_grade = (user_volume_grade + 1) % 4;
					ms.soundTransform = new SoundTransform(user_volume_grade / 3);
					// 绘制音量等级user_volume_grade
					drawVolumeButton();
				}, 200);
			});
		}
	
		private var CTRL_HEIHGT: int = 30;
		private var CTRL_PADDING: int = 20;
		
		private function redraw():void {
			var _width: int  = dimension.w;
			var _height: int = dimension.h;
			
			ctrl_mask.graphics.clear();
			ctrl_mask.graphics.beginFill(0x000000, 0);
			ctrl_mask.graphics.drawRect(0, 0, _width, _height);
			ctrl_mask.graphics.endFill();
			
			ctrl_con_bg.graphics.clear();
			// ctrl_con_bg.graphics.beginFill(0x19b955, .80);
			ctrl_con_bg.graphics.beginFill(0x000000, .70);
			ctrl_con_bg.graphics.drawRect(0, _height - CTRL_HEIHGT, _width, CTRL_HEIHGT);
			ctrl_con_bg.graphics.endFill();
		
			// 绘制播放暂停按钮
			drawPlayButton();
			
			// 绘制中央暂停按钮
			drawBitmapButton(
				this.ctrl_center_pause,
				ImageAssets.PAUSE_BTN,
				_width / 2  - ImageAssets.PAUSE_BTN.width / 2,
				_height / 2 - ImageAssets.PAUSE_BTN.height / 2
			);
			
			// 绘制全屏按钮
			var bmexp: BitmapData = ImageAssets.CTRL_EXPAND;
			drawBitmapButton(
				this.expand_btn,
				bmexp,
				_width - CTRL_PADDING - bmexp.width,
				_height - CTRL_HEIHGT / 2 - bmexp.height / 2
			);

			// 绘制音量等级
			var v: Number = user_volume;
			var vGrade: int = v == 0 ? 0 : (v < 1/3 ? 1 : (v < 2/3 ? 2 : 3));
			drawVolumeButton();
		}
		
		// 使用位图绘制按钮
		private function drawBitmapButton(
			sprite: Sprite,
			bitmapData: BitmapData,
			x: int,
			y: int
		): void {
			var matrix:Matrix = new Matrix();
			matrix.tx = x;
			matrix.ty = y;
			sprite.graphics.clear();
			sprite.graphics.beginBitmapFill(bitmapData, matrix);
			sprite.graphics.drawRect(x, y, bitmapData.width, bitmapData.height);
			sprite.graphics.endFill();
			sprite.buttonMode = true;
		}
		
		// 绘制播放暂停按钮
		private function drawPlayButton(): void {
			var bm: BitmapData = player.isPaused ? ImageAssets.CTRL_PAUSE_BTN : ImageAssets.CTRL_PLAY_BTN;
			drawBitmapButton(
				this.play_pause_btn,
				bm,
				CTRL_PADDING,
				dimension.h - CTRL_HEIHGT / 2 - bm.height / 2
			);
		}
		
		// 绘制音量按钮
		private function drawVolumeButton(): void {
			var bmv: BitmapData = ImageAssets['VOLUME_' + user_volume_grade];
			drawBitmapButton(
				this.volume_status_btn,
				bmv,
				dimension.w - CTRL_PADDING * 2 - bmv.width - ImageAssets.CTRL_EXPAND.width,
				dimension.h - CTRL_HEIHGT / 2 - bmv.height / 2
			);
		}
		
		// 模拟按钮  hover效果
		private function bindHoverEffect(sprite: Sprite): void {
			sprite.addEventListener(MouseEvent.ROLL_OVER, function user_on_mouseover(e: MouseEvent): void {
				e.target.alpha = 0.8;
			});
			sprite.addEventListener(MouseEvent.ROLL_OUT,  function user_on_mouseout(e: MouseEvent): void {
				e.target.alpha = 1;
			});
		}
		
		// 淡入淡出效果
		private function bindFadeEffect(sprite: Sprite): void {
			var timer: uint = 0;
			function fadeOut(): void {
				clearTimeout(timer);
				timer = setTimeout(function ():void {
					sprite.addEventListener(Event.ENTER_FRAME, function listener():void {
						sprite.alpha -= 0.05;
						if (sprite.alpha <= 0) {
							sprite.removeEventListener(Event.ENTER_FRAME, listener);
							clearTimeout(timer);
							sprite.alpha = 0;
						}
					});
				}, 200);
			}
			
			function fadeIn(): void {
				ctrl_con.addEventListener(Event.ENTER_FRAME, function listener():void {
					sprite.alpha += 0.06;
					if (sprite.alpha >= 1) {
						sprite.removeEventListener(Event.ENTER_FRAME, listener);
						clearTimeout(timer);
						sprite.alpha = 1;
					}
				});
			}
			
			stage.addEventListener(MouseEvent.MOUSE_OUT, fadeOut);
			
			stage.addEventListener(MouseEvent.MOUSE_MOVE, function (e: MouseEvent): void {
				clearTimeout(timer);
				timer = setTimeout(function ():void {
					var isAtBothEnds: Boolean = e.stageX < 100 || dimension.w - 100 < e.stageX;
					var isAtBottom: Boolean = e.stageY + CTRL_HEIHGT * 2 > dimension.h;
					if (isAtBothEnds || isAtBottom) {
						fadeIn();
					} else {
						clearTimeout(timer);
						timer = setTimeout(fadeOut, 500);
					}
				}, 200);
			});
			
		}
    }
}
