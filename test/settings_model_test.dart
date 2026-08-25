import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udpcore/models/settings_model.dart';
import 'package:udpcore/services/storage_service.dart';

SettingsModel _settings() => SettingsModel(
  targetIp: '192.168.1.10',
  targetPort: 4210,
  speed: 100,
  forwardCommand: 'F',
  leftCommand: 'L',
  backwardCommand: 'B',
  rightCommand: 'R',
  stopCommand: 'S',
);

void main() {
  test('transport and control surface change independently', () {
    final original = _settings();
    final bluetooth = original.copyWith(
      communicationMode: CommunicationMode.bluetooth,
    );
    final sliders = bluetooth.copyWith(controlUi: ControlUi.sliders);

    expect(original.communicationMode, CommunicationMode.udp);
    expect(original.controlUi, ControlUi.dpad);
    expect(bluetooth.communicationMode, CommunicationMode.bluetooth);
    expect(bluetooth.controlUi, ControlUi.dpad);
    expect(sliders.communicationMode, CommunicationMode.bluetooth);
    expect(sliders.controlUi, ControlUi.sliders);
  });

  test('default slider configuration is complete', () {
    final settings = _settings();

    expect(settings.sliderConfigs, hasLength(9));
    for (final slider in settings.sliderConfigs) {
      expect(slider.defaultValue, greaterThanOrEqualTo(slider.min));
      expect(slider.defaultValue, lessThanOrEqualTo(slider.max));
    }
  });

  test(
    'transport, control surface, and slider configuration persist',
    () async {
      SharedPreferences.setMockInitialValues({});
      final sliders = List<SliderConfig>.from(defaultSliderConfigs);
      sliders[0] = const SliderConfig(
        name: 'Shoulder',
        min: 10,
        max: 170,
        defaultValue: 80,
      );
      final expected = _settings().copyWith(
        communicationMode: CommunicationMode.bluetooth,
        controlUi: ControlUi.sliders,
        sliderConfigs: sliders,
      );

      await StorageService.saveSettings(expected);
      final restored = await StorageService.loadSettings();

      expect(restored.communicationMode, CommunicationMode.bluetooth);
      expect(restored.controlUi, ControlUi.sliders);
      expect(restored.sliderConfigs[0].name, 'Shoulder');
      expect(restored.sliderConfigs[0].min, 10);
      expect(restored.sliderConfigs[0].max, 170);
      expect(restored.sliderConfigs[0].defaultValue, 80);
    },
  );
}
