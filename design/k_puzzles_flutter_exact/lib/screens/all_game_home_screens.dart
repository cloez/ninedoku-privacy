import 'package:flutter/widgets.dart';
import '../data/game_catalog.dart';
import 'game_home_screen.dart';

class SudokuHomeScreen extends StatelessWidget { const SudokuHomeScreen({super.key}); @override Widget build(BuildContext context)=>GameHomeScreen(game: gameById('sudoku')); }
class BinairoHomeScreen extends StatelessWidget { const BinairoHomeScreen({super.key}); @override Widget build(BuildContext context)=>GameHomeScreen(game: gameById('binairo')); }
class MinesweeperHomeScreen extends StatelessWidget { const MinesweeperHomeScreen({super.key}); @override Widget build(BuildContext context)=>GameHomeScreen(game: gameById('minesweeper')); }
class YinYangHomeScreen extends StatelessWidget { const YinYangHomeScreen({super.key}); @override Widget build(BuildContext context)=>GameHomeScreen(game: gameById('yin-yang')); }
class NonogramHomeScreen extends StatelessWidget { const NonogramHomeScreen({super.key}); @override Widget build(BuildContext context)=>GameHomeScreen(game: gameById('nonogram')); }
class KillerSudokuHomeScreen extends StatelessWidget { const KillerSudokuHomeScreen({super.key}); @override Widget build(BuildContext context)=>GameHomeScreen(game: gameById('killer-sudoku')); }
class StarBattleHomeScreen extends StatelessWidget { const StarBattleHomeScreen({super.key}); @override Widget build(BuildContext context)=>GameHomeScreen(game: gameById('star-battle')); }
class LightUpHomeScreen extends StatelessWidget { const LightUpHomeScreen({super.key}); @override Widget build(BuildContext context)=>GameHomeScreen(game: gameById('light-up')); }
class FutoshikiHomeScreen extends StatelessWidget { const FutoshikiHomeScreen({super.key}); @override Widget build(BuildContext context)=>GameHomeScreen(game: gameById('futoshiki')); }
class TentsHomeScreen extends StatelessWidget { const TentsHomeScreen({super.key}); @override Widget build(BuildContext context)=>GameHomeScreen(game: gameById('tents')); }
class JigsawSudokuHomeScreen extends StatelessWidget { const JigsawSudokuHomeScreen({super.key}); @override Widget build(BuildContext context)=>GameHomeScreen(game: gameById('jigsaw-sudoku')); }
class SkyscrapersHomeScreen extends StatelessWidget { const SkyscrapersHomeScreen({super.key}); @override Widget build(BuildContext context)=>GameHomeScreen(game: gameById('skyscrapers')); }
class KakuroHomeScreen extends StatelessWidget { const KakuroHomeScreen({super.key}); @override Widget build(BuildContext context)=>GameHomeScreen(game: gameById('kakuro')); }
