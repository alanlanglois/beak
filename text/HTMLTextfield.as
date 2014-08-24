// =================================================================================================
//
//	Beak
//	Copyright 2014 Etamin Studio. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package beak.text 
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	/**
	 * ...
	 * @author Alan Langlois - Etamin Studio
	 */
	public class HTMLTextfield extends Sprite
	{
		private static const HELPER_POINT:Point = new Point();
		
		private var _textfield:TextField;
		private var _text:String;
		private var _textFormat:TextFormat;
		private var _width:int;
		private var _height:int;
		private var _scale:Number;
		private var _snapshot:Image;
		private var _multiline:Boolean;
		private var _embedFonts:Boolean;
		private var _wordWrap:Boolean;
		private var _antiAliasType:String;
		private var _onClickDefinitionCB:Function;
		private var _autoSize:String;
		private var _displayAsPassword:Boolean;
		private var _filters:Array;
		private var _condenseWhite:Boolean;
		private var _textColor:uint;
		private var _isAddedToStage:Boolean;
		
		public function HTMLTextfield( onClickDefinitionCB:Function ) 
		{
			this.addEventListener(Event.ADDED_TO_STAGE, _onAddedToStage);						
			this.onClickDefinitionCB = onClickDefinitionCB;
			
			_scale = Starling.contentScaleFactor;
			_textfield = new TextField();			
			
			antiAliasType = AntiAliasType.ADVANCED;
			autoSize = TextFieldAutoSize.LEFT;
			
			this.addEventListener(TouchEvent.TOUCH, _touchHandler);
			
		}
		
		private function _onAddedToStage(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, _onAddedToStage);
			_isAddedToStage = true;
			draw();
		}
		
		private function _touchHandler(e:TouchEvent):void 
		{
			var touch:Touch = e.getTouch(stage);
			
			if (!touch) return;
			
			if (touch.phase == TouchPhase.ENDED)
			{
				
				if (touch.target == _snapshot)
				{
					
					touch.getLocation(this, HELPER_POINT);
					
					var charIndex:int = _textfield.getCharIndexAtPoint(HELPER_POINT.x * _scale, HELPER_POINT.y * _scale);
					
					var htmlCharIndex:int = -1;
					var htmlText:String = _text;
					
					var regularText:String = _textfield.text;
					var htmlTextLength:int = htmlText.length;
					var lastHTMLContent:String;
					
					var _isHTML:Boolean;
					
					var testVec:Vector.<int> = new Vector.<int>();
					
					var skipLength:int = 0;
					var isHTML:Boolean;
					var isHTMLSpecial:Boolean;
					
					var htmlIndex:int = 0;
					var skipTo:int;
					
					for (var j:int = 0; j < htmlTextLength; j++)
					{
						
						if (htmlIndex == charIndex + 1)
						{
							break;
						}
						var htmlChar:String = htmlText.charAt(j);
						
						
						if (isHTML)
						{
							skipLength++;
							
							if (htmlChar == ">")
							{
								isHTML = false;
							}
							else if (isHTMLSpecial && htmlChar == ";")
							{
								isHTML = false;
								isHTMLSpecial = false;
							}
						}
						else if (htmlChar == "<")
						{
							skipLength++;
							skipTo = htmlText.indexOf(">", j);
							lastHTMLContent = htmlText.substr(j + 1, skipTo - j - 1);
							if (lastHTMLContent == "br")
							{
								htmlIndex++;
							}
							isHTML = true;
						}
						else if (htmlChar == "&")
						{
							isHTML = true;
							isHTMLSpecial = true;
						}
						else
						{
							htmlIndex++;
						}
					}
					htmlCharIndex = skipLength - 1;
					
					if (!lastHTMLContent || lastHTMLContent.search(/^dfn\s+/) != 0)
					{
						if (lastHTMLContent != null)
							trace("+++++++> 1 " + lastHTMLContent + " -- " + lastHTMLContent.search(/^dfn\s+/));
						//hideElements();
						return;
					}
					var linkStartIndex:int = lastHTMLContent.search(/title=[\"\']/) + 6;
					if (linkStartIndex < 2)
					{
						//hideElements();
						return;
					}
					
					//
					var linkEndIndex:int = lastHTMLContent.indexOf("\"", linkStartIndex + 1);
					if (linkEndIndex < 0)
					{
						linkEndIndex = lastHTMLContent.indexOf("'", linkStartIndex + 1);
						if (linkEndIndex < 0)
						{
							//hideElements();
							return;
						}
					}
					
					var def:String = lastHTMLContent.substr(linkStartIndex + 1, linkEndIndex - linkStartIndex - 1);
					if( onClickDefinitionCB != null ) onClickDefinitionCB( new Point( HELPER_POINT.x, int(_textfield.getCharBoundaries(charIndex).y / _scale)),  def );
				}
			}
		}
		
		public function draw():void
		{	
			if( !_isAddedToStage ) return;
			var bitmapData:BitmapData = new BitmapData(_textfield.width, _textfield.height, true, 0x0);
            bitmapData.draw(_textfield, new Matrix());
			
			if ( _snapshot != null ) {
				_snapshot.removeEventListener(Event.ADDED_TO_STAGE, _snapshotHandler);
				removeChild( _snapshot );
				_snapshot.dispose();
				_snapshot = null;
			}
			
			_snapshot = new Image( Texture.fromBitmapData(bitmapData, false, false, _scale) );
			_snapshot.addEventListener( Event.ADDED_TO_STAGE, _snapshotHandler);
			bitmapData = null;
			addChild( _snapshot );
		}
		
		private function _snapshotHandler(e:Event):void 
		{
			trace( "_snapshotHandler : " + this.height );
			_snapshot.removeEventListener(Event.ADDED_TO_STAGE, _snapshotHandler);
			_height = _snapshot.height;
			this.dispatchEventWith( Event.CHANGE );
		}
		
		
		
		public function get HTMLtext():String { return _text; }
		
		public function set HTMLtext(value:String):void 
		{
			_text = value;
			_textfield.htmlText = value;
			draw();
		}
		
		public function get defaultTextFormat():TextFormat { return _textFormat; }
		
		public function set defaultTextFormat(value:TextFormat):void 
		{
			value.size = Object( Number(value.size) * _scale );
			value.leading = Object( Number(value.leading) * _scale );
			_textColor = uint( value.color );
			_textFormat = value;
			_textfield.defaultTextFormat = _textFormat;
			draw();
		}
		
		public function get autoSize(): String{ return _autoSize; }
		
		public function set autoSize(value:String):void {
			_autoSize = value;
			_textfield.autoSize = _autoSize;
			if ( value || value != TextFieldAutoSize.NONE ) {
				_textfield.autoSize = _autoSize;
				_wordWrap = true;
				_multiline = true;
				_textfield.wordWrap = true;
				_textfield.multiline = true;
			}
			draw();
		}
		
		
		override public function get width(): Number{ return _width; }
		
		override public function set width(value:Number):void {
			super.width = value;
			_width = value;
			_textfield.width = _width * _scale;
			draw();
		}
		
		override public function get height(): Number{ return _height; }
		
		override public function set height(value:Number):void {
			super.height = value;
			_height = value;
			_textfield.height = _height * _scale;
			draw();
		}		
		
		public function get multiline():Boolean { return _multiline; }
		
		public function set multiline( value:Boolean ):void { 
			_multiline = value; 
			_textfield.multiline = value;
			draw();
		}
		
		public function get embedFont():Boolean { return _embedFonts; }
		
		public function set embedFonts( value:Boolean ):void { 
			_embedFonts = value; 
			_textfield.embedFonts = value;
			draw();
		}
		
		public function get displayAsPassword():Boolean { return _displayAsPassword; }
		
		public function set displayAsPassword( value:Boolean ):void { 
			_displayAsPassword = value; 
			_textfield.displayAsPassword = value;
			draw();
		}
		
		public function get filters():Array { return _filters; }
		
		public function set filters( value:Array ):void { 
			_filters = value; 
			_textfield.filters = value;
			draw();
		}
		
		public function get condenseWhite():Boolean { return _condenseWhite; }
		
		public function set condenseWhite( value:Boolean ):void { 
			_condenseWhite = value; 
			_textfield.condenseWhite = value;
			draw();
		}
		
		public function get length():int { return _textfield.length; }
		
		
		public function get textColor():uint { return _textColor; }
		
		public function set textColor( value:uint ):void { 
			_textColor = value; 
			_textfield.textColor = value;
			draw();
		}
		
		
		public function get wordWrap():Boolean { return _wordWrap; }
		
		public function set wordWrap( value:Boolean ):void { 
			_wordWrap = value; 
			_textfield.wordWrap = value;
			draw();
		}
		
		public function get antiAliasType():String { return _antiAliasType; }
		
		public function set antiAliasType( value:String ):void { 
			_antiAliasType = value; 
			_textfield.antiAliasType = value;
			draw();
		}
		
		public function get onClickDefinitionCB():Function 
		{
			return _onClickDefinitionCB;
		}
		
		public function set onClickDefinitionCB(value:Function):void 
		{
			_onClickDefinitionCB = value;
		}
		
		public function getCharWidth(index:int):Number
		{
			return _textfield.getCharBoundaries(index).width / _scale;
		}
		
		public function getCharHeight(index:int):Number
		{
			
			return _textfield.getCharBoundaries(index).height / _scale;
		}
		
		public function measureText(result:Point = null):Point
		{
			if(!result)
			{
				result = new Point();
			}
			
			if(_textfield)
			{
				result.x = _width;
				result.y = _height;
				return result;
			}
			
			return result;
			
		}
		
		
		override public function dispose():void 
		{
			this.removeEventListeners( Event.CHANGE );
			this.removeEventListener(TouchEvent.TOUCH, _touchHandler);
			super.dispose();
		}
		
	}

}