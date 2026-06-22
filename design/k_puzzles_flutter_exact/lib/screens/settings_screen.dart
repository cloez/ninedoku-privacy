import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../widgets/kp_background.dart';
import '../widgets/kp_icon_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int theme = 0;
  int font = 0;
  bool mistakes = true, timer = true, autoComplete = true, sound = true, vibration = true, reduceEffects = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KPBackground(
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
            sliver: SliverList.list(children: [
              Row(children: [KPIconButton(asset: 'assets/icons/arrow-left.svg', onTap: () => Navigator.pop(context)), Expanded(child: Text('설정', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium)), const SizedBox(width: 50)]),
              const SizedBox(height: 18),
              _sectionTitle('화면'),
              _card([
                _segmentRow('assets/icons/palette.svg', '테마', ['시스템', '라이트', '다크'], theme, (v) => setState(() => theme = v)),
                _navRow('assets/icons/palette.svg', '테마 선택'),
                _segmentRow('assets/icons/text-size.svg', '글자 크기', ['기본', '크게', '매우'], font, (v) => setState(() => font = v)),
                _valueRow('assets/icons/globe.svg', '언어', '한국어'),
              ]),
              _sectionTitle('게임플레이'),
              _card([
                _switchRow('assets/icons/target.svg', '실수 표시', '틀린 숫자를 빨간색으로 표시', mistakes, (v) => setState(() => mistakes = v)),
                _switchRow('assets/icons/timer.svg', '타이머 표시', '게임 중 경과 시간 표시', timer, (v) => setState(() => timer = v)),
                _switchRow('assets/icons/wand.svg', '자동 완성', '남은 칸이 모두 확정될 때 자동으로 채움', autoComplete, (v) => setState(() => autoComplete = v)),
              ]),
              _sectionTitle('피드백'),
              _card([
                _switchRow('assets/icons/speaker.svg', '사운드', '숫자 입력, 완료 시 효과음', sound, (v) => setState(() => sound = v)),
                _switchRow('assets/icons/vibration.svg', '진동', '숫자 입력, 실수 시 진동', vibration, (v) => setState(() => vibration = v)),
                _switchRow('assets/icons/sparkle.svg', '효과 줄이기', '애니메이션과 시각 효과를 줄입니다', reduceEffects, (v) => setState(() => reduceEffects = v)),
              ]),
              _sectionTitle('정보'),
              _card([
                _valueRow('assets/icons/info.svg', '앱 버전', '1.0.0'),
                _statusRow('assets/icons/offline.svg', '완전 오프라인', '인터넷 연결 없이 동작합니다'),
              ]),
              _sectionTitle('백업'),
              _card([
                _navRow('assets/icons/upload.svg', '데이터 내보내기', '게임 기록, 배지, 설정을 JSON으로 저장'),
                _navRow('assets/icons/download.svg', '데이터 가져오기', '백업 파일에서 데이터 복원'),
              ]),
              const SizedBox(height: 16),
              _card([
                _navRow('assets/icons/document.svg', '오픈소스 라이선스'),
                _navRow('assets/icons/heart.svg', '후원하기', '개발자를 응원해 주세요'),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(padding: const EdgeInsets.fromLTRB(4, 18, 0, 10), child: Text(text, style: const TextStyle(color: KPColors.blue, fontSize: 17, fontWeight: FontWeight.w900)));
  Widget _card(List<Widget> rows) => Container(decoration: BoxDecoration(color: Colors.white.withOpacity(.96), borderRadius: BorderRadius.circular(28), boxShadow: KPShadow.soft, border: Border.all(color: KPColors.border)), child: Column(children: [for (int i=0;i<rows.length;i++) ...[rows[i], if (i<rows.length-1) const Divider(height: 1, indent: 72, color: KPColors.border)]]));
  Widget _icon(String asset) => Container(width: 42, height: 42, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: KPColors.paleViolet, borderRadius: BorderRadius.circular(14)), child: SvgPicture.asset(asset));
  Widget _baseRow(String icon, String title, String? subtitle, Widget trailing) => Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), child: Row(children: [_icon(icon), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: KPColors.text)), if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 13, height: 1.35, color: KPColors.muted))]])), const SizedBox(width: 12), trailing]));
  Widget _switchRow(String icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) => _baseRow(icon, title, subtitle, Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: KPColors.violet));
  Widget _navRow(String icon, String title, [String? subtitle]) => _baseRow(icon, title, subtitle, SvgPicture.asset('assets/icons/chevron-right.svg', width: 19));
  Widget _valueRow(String icon, String title, String value) => _baseRow(icon, title, null, Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: KPColors.muted)));
  Widget _statusRow(String icon, String title, String subtitle) => _baseRow(icon, title, subtitle, SvgPicture.asset('assets/icons/check-circle.svg', width: 30));
  Widget _segmentRow(String icon, String title, List<String> options, int value, ValueChanged<int> onChanged) => Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), child: Column(children: [Row(children: [_icon(icon), const SizedBox(width: 14), Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)))]), const SizedBox(height: 12), SegmentedButton<int>(segments: [for (int i=0;i<options.length;i++) ButtonSegment(value: i, label: Text(options[i]))], selected: {value}, onSelectionChanged: (set) => onChanged(set.first), showSelectedIcon: false, style: const ButtonStyle(visualDensity: VisualDensity.compact))]));
}
