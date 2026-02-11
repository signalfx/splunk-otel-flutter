/*
 * Copyright 2026 Splunk Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.splunk.rum.flutter.example.example.simulations

import android.app.Activity
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.View
import android.view.ViewGroup

import java.util.Random

object SlowRendering {
    /**
     * Creates and attaches a custom [SlowRenderView] to simulate poor rendering performance.
     *
     * @param testName Display name of the test (e.g. "slow render").
     * @param renderDelayMs How long each frame should be delayed in drawing, in milliseconds.
     * @param color The color of the shapes drawn to simulate load.
     * @param refreshIntervalMs How often to invalidate/redraw the view.
     * @param durationMs Total duration of the test in milliseconds.
     */
    fun simulateSlowRendering(
        activity: Activity,
        renderDelayMs: Long,
        color: Int,
        refreshIntervalMs: Long = DEFAULT_REFRESH_INTERVAL_MS,
        durationMs: Long = DEFAULT_TEST_DURATION_MS
    ) {
        val slowRenderView = SlowRenderView(
            activity.baseContext,
            renderDelayMs,
            color,
            refreshIntervalMs
        )

        slowRenderView.layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )

        val rootView = activity.window.decorView
            .findViewById<ViewGroup>(android.R.id.content)

        rootView.addView(slowRenderView)


        Handler(Looper.getMainLooper()).postDelayed({
            rootView.removeView(slowRenderView)
            slowRenderView.stopRendering()
        }, durationMs)
    }

    /**
     * A custom [View] that simulates rendering delays by performing expensive draw operations
     * repeatedly at a fixed refresh interval.
     *
     * @param context The application context.
     * @param renderDelayMs Time to delay each frame to simulate slowness.
     * @param shapeColor Color of the drawn shapes.
     * @param refreshIntervalMs Interval in milliseconds between view invalidations.
     */
    private class SlowRenderView(
        context: Context,
        private val renderDelayMs: Long,
        private val shapeColor: Int,
        private val refreshIntervalMs: Long
    ) : View(context) {

        private val shapePaint = Paint().apply { color = shapeColor }
        private val randomGenerator = Random()
        private val renderHandler = Handler(Looper.getMainLooper())

        init {
            startSlowRendering()
        }

        private fun startSlowRendering() {
            invalidate()
            renderHandler.postDelayed({ startSlowRendering() }, refreshIntervalMs)
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val renderStartTime = SystemClock.elapsedRealtime()

            // Draw until target delay time is consumed
            while (SystemClock.elapsedRealtime() - renderStartTime < renderDelayMs) {
                repeat(CIRCLES_PER_FRAME) {
                    if (width > 0 && height > 0) {
                        canvas.drawCircle(
                            randomGenerator.nextFloat() * width,
                            randomGenerator.nextFloat() * height,
                            CIRCLE_RADIUS,
                            shapePaint
                        )
                    }
                }
            }
        }

        fun stopRendering() {
            renderHandler.removeCallbacksAndMessages(null)
        }
    }

    /**
     * Constants used in rendering simulations to define timing and draw behavior.
     */

    /** Delay per frame for simulating slow renders (30ms). */
    const val SLOW_RENDER_DELAY_MS = 30L

    /** Delay per frame for simulating frozen renders (800ms). */
    const val FROZEN_RENDER_DELAY_MS = 800L

    /** Default interval between redraws (roughly 60 FPS). */
    const val DEFAULT_REFRESH_INTERVAL_MS = 16L

    /** Interval between redraws during frozen render simulation. */
    const val FROZEN_REFRESH_INTERVAL_MS = 1000L

    /** Duration to run the test (10 seconds). */
    const val DEFAULT_TEST_DURATION_MS = 10_000L

    /** Number of circles drawn in each frame to increase render cost. */
    const val CIRCLES_PER_FRAME = 200

    /** Radius of each drawn circle in pixels. */
    const val CIRCLE_RADIUS = 3f

}