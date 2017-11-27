package
{
	import flash.display.BitmapData;
	
	import mx.core.BitmapAsset;

	public class ImageAssets
	{
		/**
		 * 加载 gif
		 */
		[Embed(source="./assets/loading.gif")]
		private static const Loading:Class;
		public static function get LOADING (): BitmapData {
			const bmp: BitmapAsset = new Loading() as BitmapAsset;
			return bmp.bitmapData.clone();
		}
		
		/**
		 * 暂停按钮
		 */
		[Embed(source="./assets/btn-pause.png")]
		private static const BtnPause:Class;
		public static function get PAUSE_BTN() :BitmapData {
			const bmp: BitmapAsset = new BtnPause() as BitmapAsset;
			return bmp.bitmapData.clone();
		}
		
		/**
		 * 暂停控制按钮
		 */
		[Embed(source="./assets/ctrl-btn-paused.png")]
		private static const CtrlBtnPause:Class;
		public static function get CTRL_PAUSE_BTN() :BitmapData {
			const bmp: BitmapAsset = new CtrlBtnPause() as BitmapAsset;
			return bmp.bitmapData.clone();
		}
		
		/**
		 * 播放控制按钮
		 */
		[Embed(source="./assets/ctrl-btn-play.png")]
		private static const CtrlBtnPlay:Class;
		public static function get CTRL_PLAY_BTN() :BitmapData {
			const bmp: BitmapAsset = new CtrlBtnPlay() as BitmapAsset;
			return bmp.bitmapData.clone();
		}
		
		/**
		 * 控制圆圈
		 */
		[Embed(source="./assets/ctrl-circle.png")]
		private static const CtrlCircle:Class;
		public static function get CTRL_CIRCLE() :BitmapData {
			const bmp: BitmapAsset = new CtrlCircle() as BitmapAsset;
			return bmp.bitmapData.clone();
		}
		
		/**
		 * 展开
		 */
		[Embed(source="./assets/expand.png")]
		private static const CtrlExpand:Class;
		public static function get CTRL_EXPAND() :BitmapData {
			const bmp: BitmapAsset = new CtrlExpand() as BitmapAsset;
			return bmp.bitmapData.clone();
		}
		
		/**
		 * 音量 0 
		 */
		[Embed(source="./assets/volume-0.png")]
		private static const Volume0:Class;
		public static function get VOLUME_0() :BitmapData {
			const bmp: BitmapAsset = new Volume0() as BitmapAsset;
			return bmp.bitmapData.clone();
		}
	
		/**
		 * 音量 1 
		 */
		[Embed(source="./assets/volume-1.png")]
		private static const Volume1:Class;
		public static function get VOLUME_1() :BitmapData {
			const bmp: BitmapAsset = new Volume1() as BitmapAsset;
			return bmp.bitmapData.clone();
		}
		
		/**
		 * 音量 2 
		 */
		[Embed(source="./assets/volume-2.png")]
		private static const Volume2:Class;
		public static function get VOLUME_2() :BitmapData {
			const bmp: BitmapAsset = new Volume2() as BitmapAsset;
			return bmp.bitmapData.clone();
		}
		
		/**
		 * 音量 3 
		 */
		[Embed(source="./assets/volume-3.png")]
		private static const Volume3:Class;
		public static function get VOLUME_3() :BitmapData {
			const bmp: BitmapAsset = new Volume3() as BitmapAsset;
			return bmp.bitmapData.clone();
		}
	}
}