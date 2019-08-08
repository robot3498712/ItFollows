package com.robot.itfollows;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

// for intent
import android.content.Intent;
import java.nio.ByteBuffer;
import io.flutter.plugin.common.ActivityLifecycleListener;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;

public class MainActivity extends FlutterActivity {
	private String sharedText;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		GeneratedPluginRegistrant.registerWith(this);
		
		// Handle intent when app is initially opened
		handleSendIntent(getIntent());

		new MethodChannel(getFlutterView(), "app.channel.shared.data").setMethodCallHandler(
			new MethodCallHandler() {
				@Override
				public void onMethodCall(MethodCall call, MethodChannel.Result result) {
					if (call.method.contentEquals("getSharedText")) {
						result.success(sharedText);
						sharedText = null;
					}
				}
			}
		);
	}

	@Override
	protected void onNewIntent(Intent intent) {
		// Handle intent when app is resumed
		super.onNewIntent(intent);
		handleSendIntent(intent);
	}

	private void handleSendIntent(Intent intent) {
		String action = intent.getAction();
		String type = intent.getType();

		// We only care about sharing intent that contain plain text
		if (Intent.ACTION_SEND.equals(action) && type != null) {
			if ("text/plain".equals(type)) {
				sharedText = intent.getStringExtra(Intent.EXTRA_TEXT);
			}
		}
	}
}
