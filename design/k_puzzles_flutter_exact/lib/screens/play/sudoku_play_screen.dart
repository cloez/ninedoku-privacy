import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kp_background.dart';
import '../../widgets/kp_icon_button.dart';

class SudokuPlayScreen extends StatefulWidget {
  const SudokuPlayScreen({super.key});
  @override
  State<SudokuPlayScreen> createState() => _SudokuPlayScreenState();
}

class _SudokuPlayScreenState extends State<SudokuPlayScreen> {
  int selectedRow = 4, selectedCol = 3, selectedNumber = 7;
  bool noteMode = false;
  static const board = [
    [7,0,4,5,3,1,0,8,0],[3,0,9,8,0,6,0,5,2],[0,8,6,9,0,4,0,1,7],
    [6,0,8,0,0,0,0,9,3],[4,3,1,7,0,9,8,0,0],[2,0,0,3,0,0,0,0,4],
    [0,4,2,0,0,7,0,0,1],[1,5,7,0,0,0,6,4,9],[0,0,3,1,4,5,2,0,0],
  ];

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.sizeOf(context).width > 800;
    return Scaffold(body: KPBackground(maxWidth: landscape ? 1400 : 580, child: Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 24), child: landscape ? _landscape(context) : _portrait(context))));
  }

  Widget _portrait(BuildContext context) => ListView(children: [_topbar(context), const SizedBox(height: 14), _status(), const SizedBox(height: 12), _progress(), const SizedBox(height: 14), _board(), const SizedBox(height: 16), _tools(), const SizedBox(height: 16), _numbers()]);
  Widget _landscape(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 11, child: Center(child: _board())), const SizedBox(width: 26), Expanded(flex: 9, child: ListView(children: [_topbar(context), const SizedBox(height: 14), _status(), const SizedBox(height: 12), _progress(), const SizedBox(height: 18), _tools(), const SizedBox(height: 18), _numbers()]))]);

  Widget _topbar(BuildContext context) => Row(children: [KPIconButton(asset: 'assets/icons/arrow-left.svg', onTap: () => Navigator.pop(context)), Expanded(child: Text('클래식', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium)), KPIconButton(asset: 'assets/icons/pause.svg', onTap: () {})]);
  Widget _status() => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: KPShadow.soft), child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_StatusText('입문'), _StatusText('▦ 35'), _StatusText('× 실수 0'), _StatusText('Ⅱ 00:03')]));
  Widget _progress() => Container(height: 10, decoration: BoxDecoration(color: const Color(0xFFE9E7F4), borderRadius: BorderRadius.circular(99)), child: FractionallySizedBox(widthFactor: .18, alignment: Alignment.centerLeft, child: Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [KPColors.violet, KPColors.blue]), borderRadius: BorderRadius.circular(99)))));
  Widget _board() => AspectRatio(aspectRatio: 1, child: Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: const Color(0xFF8D84D7), borderRadius: BorderRadius.circular(24), boxShadow: KPShadow.soft), child: ClipRRect(borderRadius: BorderRadius.circular(21), child: GridView.builder(physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9), itemCount: 81, itemBuilder: (context, index) {final r=index~/9,c=index%9,v=board[r][c]; final related=r==selectedRow||c==selectedCol; final selected=r==selectedRow&&c==selectedCol; final thickR=c==2||c==5; final thickB=r==2||r==5; return GestureDetector(onTap: ()=>setState((){selectedRow=r;selectedCol=c;if(v!=0)selectedNumber=v;}), child: Container(decoration: BoxDecoration(color:selected?const Color(0xFFEAF0FF):related?const Color(0xFFF1F4FF):Colors.white,border:Border(right:BorderSide(color:thickR?const Color(0xFF8D84D7):const Color(0xFFDDE2F4),width:thickR?2.5:1),bottom:BorderSide(color:thickB?const Color(0xFF8D84D7):const Color(0xFFDDE2F4),width:thickB?2.5:1))), child: Center(child: Text(v==0?'':'$v', style: TextStyle(fontSize: 24,fontWeight:FontWeight.w800,color:v==selectedNumber?KPColors.blue:KPColors.text))));})))));
  Widget _tools() {final items=[('assets/icons/undo.svg','되돌리기'),('assets/icons/delete.svg','삭제'),('assets/icons/pencil.svg','메모'),('assets/icons/wand.svg','자동 메모'),('assets/icons/number.svg','숫자우선'),('assets/icons/bulb.svg','힌트')]; return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: KPShadow.soft), child: GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:MediaQuery.sizeOf(context).width<600?3:6,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1),itemCount:items.length,itemBuilder:(context,i){final active=(i==2&&noteMode)||i==4;return InkWell(onTap:()=>setState(()=>noteMode=i==2?!noteMode:noteMode),borderRadius:BorderRadius.circular(18),child:Container(decoration:BoxDecoration(color:active?KPColors.paleViolet:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:active?const Color(0xFFD8CEFF):KPColors.border)),padding:const EdgeInsets.all(10),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[SvgPicture.asset(items[i].$1,width:28,height:28),const SizedBox(height:7),Text(items[i].$2,textAlign:TextAlign.center,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800))]))); }));}
  Widget _numbers()=>Row(children:[for(int n=1;n<=9;n++) Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:InkWell(onTap:()=>setState(()=>selectedNumber=n),borderRadius:BorderRadius.circular(18),child:Container(padding:const EdgeInsets.symmetric(vertical:12),decoration:BoxDecoration(color:selectedNumber==n?KPColors.paleViolet:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:selectedNumber==n?const Color(0xFFD6CCFF):KPColors.border),boxShadow:KPShadow.soft),child:Column(children:[Text('$n',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900,color:KPColors.blue)),Text('${(n*3)%6+2}',style:const TextStyle(fontSize:11,color:KPColors.muted))])))))]);
}

class _StatusText extends StatelessWidget {const _StatusText(this.text);final String text;@override Widget build(BuildContext context)=>Text(text,style:const TextStyle(color:KPColors.indigo,fontWeight:FontWeight.w800));}
