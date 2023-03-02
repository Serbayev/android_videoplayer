import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:flutter_gpu_video_filters/flutter_gpu_video_filters.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({Key? key}) : super(key: key);

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  late final GPUVideoPreviewController controller;
  late final GPUVideoPreviewParams previewParams;
  late GPUFilterConfiguration configuration;
  bool previewParamsReady = false;
  static const _assetPath = 'assets/demo.mp4';
  late final File pickedFile;

  @override
  void initState() {
    super.initState();
    configuration = GPUGrayScaleConfiguration();
    _prepare().whenComplete(() => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  Future<void> _prepare() async {
    previewParams = await GPUVideoPreviewParams.create(configuration);
    previewParamsReady = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Preview'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          child: previewParamsReady
              ? GPUVideoNativePreview(
                  params: previewParams,
                  configuration: configuration,
                  onViewCreated: (controller, outputSizeStream) async {
                    final picker = ImagePicker();
                    controller = controller;
                    final v =
                        await picker.pickVideo(source: ImageSource.gallery);
                    pickedFile = File(v!.path);
                    controller.setVideoFile(pickedFile);
                    // controller.setVideoAsset(_assetPath);
                    await for (final _ in outputSizeStream) {
                      setState(() {});
                    }
                  },
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final picker = ImagePicker();

          setState(() {});
          await e();
        },
        child: const Icon(Icons.save),
      ),
    );
  }

  Future<void> _exportVideo() async {
    const asset = _assetPath;
    final output = File(
      '${DateTime.now().millisecondsSinceEpoch}.${asset.split('.').last}',
    );
    final watch = Stopwatch();
    watch.start();
    final processStream = configuration.exportVideoFile(
      VideoExportConfig(
        AssetInputSource(asset),
        output,
      ),
    );
    await for (final progress in processStream) {
      debugPrint('Exporting file ${(progress * 100).toInt()}%');
    }
    debugPrint('Exporting file took ${watch.elapsedMilliseconds} milliseconds');
    debugPrint('Exported: ${output.absolute}');
  }

  Future<void> e() async {
    const asset = 'assets/demo.mp4';
    final temp = await getTemporaryDirectory();
    final inputSource = AssetInputSource(asset);
    final output = File('${temp.path}/result.mp4');
    final configuration = GPUGrayScaleConfiguration();
    final processStream =
        configuration.exportVideoFile(VideoExportConfig(inputSource, output));
    await for (final progress in processStream) {
      debugPrint('Exporting file ${(progress * 100).toInt()}%');
    }
  }
}
