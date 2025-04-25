import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:frontend/auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Util {
  static final String BACKEND_URL =
      // Platform.isAndroid ? "http://10.0.2.2:5001" : "http://100.69.73.91:5001";
      // Platform.isAndroid ? "http://10.0.2.2:5001" : "http://localhost:5001";
      "https://randezvous-68978884599.us-east1.run.app";
}

void initBackgroundFetch() async {
  BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 15, // Run every 15 minutes
      stopOnTerminate: false, // Continue running after app termination
      enableHeadless: true, // Run even if the app is not in memory
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
    (String taskId) async {
      print("[BackgroundFetch] Task received: $taskId");

      // Call refresh logic
      await Auth.refreshTokenIfNeeded();

      // Finish the background task
      BackgroundFetch.finish(taskId);
    },
    (String taskId) async {
      print("[BackgroundFetch] Task timeout: $taskId");
      BackgroundFetch.finish(taskId);
    },
  );

  // Start the background fetch process
  BackgroundFetch.start();
  print("[BackgroundFetch] Background fetch started.");
}

extension ToBitDescription on Widget {
  Future<BitmapDescriptor> toBitmapDescriptor({
    Size? logicalSize,
    Size? imageSize,
    Duration waitToRender = const Duration(milliseconds: 300),
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    // It's generally better practice to wrap with Directionality
    // at a higher level if possible, but wrapping here is fine too.
    // Ensure the Directionality inside createImageFromWidget also matches
    // or remove it if this top-level one suffices.
    final widget = RepaintBoundary(
      child: MediaQuery(
        data:
            const MediaQueryData(), // Consider using MediaQuery.of(context) if available for theming etc.
        child: Directionality(textDirection: textDirection, child: this),
      ),
    );
    final pngBytes = await createImageFromWidget(
      widget,
      waitToRender: waitToRender,
      logicalSize: logicalSize,
      imageSize: imageSize,
      // Pass textDirection if needed inside createImageFromWidget's setup
      // textDirection: textDirection,
    );
    // It's crucial that BitmapDescriptor is imported from the correct package
    // e.g., 'package:google_maps_flutter/google_maps_flutter.dart'
    // Assuming you are using google_maps_flutter:
    // import 'package:google_maps_flutter/google_maps_flutter.dart';
    return BitmapDescriptor.fromBytes(pngBytes);
  }
}

/// Creates an image from the given widget by first spinning up a element and render tree,
/// wait [waitToRender] to render the widget that take time like network and asset images

/// The final image will be of size [imageSize] and the the widget will be layout, ... with the given [logicalSize].
/// By default Value of  [imageSize] and [logicalSize] will be calculate from the app main window

Future<Uint8List> createImageFromWidget(
  Widget widget, {
  Size? logicalSize,
  required Duration waitToRender,
  Size? imageSize,
  // Optional: Pass textDirection if your manual setup needs it explicitly
  // TextDirection textDirection = TextDirection.ltr,
}) async {
  final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

  // Use View.of(context) in a build context if possible for more accuracy,
  // otherwise using the first view is a reasonable fallback.
  final view = ui.PlatformDispatcher.instance.views.first;
  logicalSize ??= view.physicalSize / view.devicePixelRatio;
  imageSize ??= view.physicalSize;

  // The assertion might be too strict. Widgets might render correctly
  // even if aspect ratios don't match perfectly, depending on alignment
  // and widget constraints. Consider removing or adjusting if it causes issues.
  // assert(logicalSize.aspectRatio == imageSize.aspectRatio);

  final RenderView renderView = RenderView(
    view: view,
    child: RenderPositionedBox(
      alignment: Alignment.center,
      child: repaintBoundary,
    ),
    configuration: ViewConfiguration(
      // Use BoxConstraints instead of loose for more predictable sizing
      // logicalConstraints: BoxConstraints.loose(logicalSize),
      logicalConstraints: BoxConstraints(
        minWidth: logicalSize.width,
        maxWidth: logicalSize.width,
        minHeight: logicalSize.height,
        maxHeight: logicalSize.height,
      ),
      devicePixelRatio: 1.0, // Use 1.0 for logical size calculations
    ),
  );

  final PipelineOwner pipelineOwner = PipelineOwner();
  final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();

  final RenderObjectToWidgetElement<RenderBox>
  rootElement = RenderObjectToWidgetAdapter<RenderBox>(
    container: repaintBoundary,
    // Consider adding Directionality here if not handled by the caller's wrapper
    // child: Directionality(
    //   textDirection: textDirection,
    //   child: widget,
    // ),
    child: widget,
  ).attachToRenderTree(buildOwner);

  buildOwner.buildScope(rootElement);

  // Wait for async operations like images
  if (waitToRender > Duration.zero) {
    await Future.delayed(waitToRender);
  }

  // Rebuild and finalize layout after waiting
  buildOwner.buildScope(rootElement);
  buildOwner.finalizeTree();

  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  // Calculate pixelRatio based on desired image size vs logical size
  final double pixelRatio = imageSize.width / logicalSize.width;

  ui.Image image = await repaintBoundary.toImage(pixelRatio: pixelRatio);

  // <<< --- START ANDROID FLIP FIX --- >>>
  if (Platform.isAndroid) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    // Translate and scale canvas to flip vertically
    canvas.translate(0.0, image.height.toDouble());
    canvas.scale(1.0, -1.0);
    // Draw the original image onto the transformed canvas
    canvas.drawImage(image, Offset.zero, Paint());

    final ui.Picture picture = recorder.endRecording();
    // Ensure the flipped image has the same dimensions
    image = await picture.toImage(image.width, image.height);
    // Dispose the original image and picture if necessary (usually handled by GC)
    // image.dispose(); // Original image might still be needed if you cache it
    picture.dispose();
  }
  // <<< --- END ANDROID FLIP FIX --- >>>

  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );

  // Dispose the final image object to free up memory
  image.dispose();

  if (byteData == null) {
    throw Exception('Could not convert widget to image.');
  }

  return byteData.buffer.asUint8List();
}
