/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.1
 * 
 * Copyright (c) 2013, Esoteric Software
 * All rights reserved.
 * 
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to install, execute and perform the Spine Runtimes
 * Software (the "Software") solely for internal use. Without the written
 * permission of Esoteric Software (typically granted by licensing Spine), you
 * may not (a) modify, translate, adapt or otherwise create derivative works,
 * improvements of the Software or develop new applications using the Software
 * or (b) remove, delete, alter or obscure any trademarks or any copyright,
 * trademark, patent or other intellectual property or proprietary rights
 * notices on or in the Software, including any copy thereof. Redistributions
 * in binary or source form must include this license and terms.
 * 
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine.animation {
import spine.Event;
import spine.Skeleton;
import spine.Slot;
import spine.attachments.Attachment;

public class FfdTimeline extends CurveTimeline {
	public var slotIndex:int;
	public var frames:Vector.<Number>;
	public var frameVertices:Vector.<Vector.<Number>>;
	public var attachment:Attachment;

	public function FfdTimeline (frameCount:int) {
		super(frameCount);
		frames = new Vector.<Number>(frameCount, true);
		frameVertices = new Vector.<Vector.<Number>>(frameCount, true);
	}

	/** Sets the time and value of the specified keyframe. */
	public function setFrame (frameIndex:int, time:Number, vertices:Vector.<Number>) : void {
		frames[frameIndex] = time;
		frameVertices[frameIndex] = vertices;
	}

	override public function apply (skeleton:Skeleton, lastTime:Number, time:Number, firedEvents:Vector.<Event>, alpha:Number) : void {
		var slot:Slot = skeleton.slots[slotIndex];
		if (slot.attachment != attachment) return;

		var frames:Vector.<Number> = this.frames;
		if (time < frames[0]) {
			slot.attachmentVertices.length = 0;
			return; // Time is before first frame.
		}

		var frameVertices:Vector.<Vector.<Number>> = this.frameVertices;
		var vertexCount:int = frameVertices[0].length;

		var vertices:Vector.<Number> = slot.attachmentVertices;
		if (vertices.length != vertexCount) alpha = 1;
		vertices.length = vertexCount;

		var i:int;
		if (time >= frames[frames.length - 1]) { // Time is after last frame.
			var lastVertices:Vector.<Number> = frameVertices[int(frames.length - 1)];
			if (alpha < 1) {
				for (i = 0; i < vertexCount; i++)
					vertices[i] += (lastVertices[i] - vertices[i]) * alpha;
			} else {
				for (i = 0; i < vertexCount; i++)
					vertices[i] = lastVertices[i];
			}
			return;
		}

		// Interpolate between the previous frame and the current frame.
		var frameIndex:int = Animation.binarySearch(frames, time, 1);
		var frameTime:Number = frames[frameIndex];
		var percent:Number = 1 - (time - frameTime) / (frames[int(frameIndex - 1)] - frameTime);
		percent = getCurvePercent(frameIndex - 1, percent < 0 ? 0 : (percent > 1 ? 1 : percent));

		var prevVertices:Vector.<Number> = frameVertices[int(frameIndex - 1)];
		var nextVertices:Vector.<Number> = frameVertices[frameIndex];

		var prev:Number;
		if (alpha < 1) {
			for (i = 0; i < vertexCount; i++) {
				prev = prevVertices[i];
				vertices[i] += (prev + (nextVertices[i] - prev) * percent - vertices[i]) * alpha;
			}
		} else {
			for (i = 0; i < vertexCount; i++) {
				prev = prevVertices[i];
				vertices[i] = prev + (nextVertices[i] - prev) * percent;
			}
		}
	}
}

}
