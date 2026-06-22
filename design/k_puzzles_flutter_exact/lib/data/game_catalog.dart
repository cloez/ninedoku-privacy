import 'package:flutter/material.dart';
import '../models/game_definition.dart';

const gameCatalog = <GameDefinition>[
  GameDefinition(
    id: 'sudoku', order: 1, title: '스도쿠', subtitle: '숫자 논리 퍼즐의 정석',
    tagline: '마음을 편안하게, 한 칸씩',
    description: '스도쿠는 간단한 규칙과 복잡한 해법을 지닌 논리 퍼즐입니다. 3×3 형태의 지역으로 분할된 9×9 격자 판에 1부터 9까지의 숫자를 채워야 합니다.',
    rules: ['각 가로줄에는 1부터 9까지의 숫자가 오직 한 번씩만 들어가야 합니다.', '각 세로줄에는 1부터 9까지의 숫자가 오직 한 번씩만 들어가야 합니다.', '각 3×3 지역에는 1부터 9까지의 숫자가 오직 한 번씩만 들어가야 합니다.'],
    iconAsset: 'assets/icons/game-sudoku.svg', primary: Color(0xFF3C8AF7), secondary: Color(0xFF6B54EE), surface: Color(0xFFEFF6FF),
  ),
  GameDefinition(
    id: 'binairo', order: 2, title: '비나이로', subtitle: '0과 1로 채우는 이진 퍼즐',
    tagline: '0과 1 사이의 완벽한 균형',
    description: '비나이로는 격자에 0과 1을 채우며 연속, 개수, 중복 규칙을 모두 만족시키는 이진 논리 퍼즐입니다.',
    rules: ['같은 숫자가 가로나 세로로 세 개 이상 연속될 수 없습니다.', '각 행과 열에는 0과 1이 같은 개수만큼 들어갑니다.', '완성된 두 행 또는 두 열은 서로 같을 수 없습니다.'],
    iconAsset: 'assets/icons/game-binairo.svg', primary: Color(0xFF45CDAE), secondary: Color(0xFF53627E), surface: Color(0xFFECFBF7),
  ),
  GameDefinition(
    id: 'minesweeper', order: 3, title: '지뢰찾기', subtitle: '숫자 힌트로 지뢰를 찾아라',
    tagline: '숫자 속에 숨은 위험을 찾아라',
    description: '지뢰찾기는 열린 칸의 숫자를 단서로 숨겨진 지뢰의 위치를 추론하는 클래식 논리 게임입니다.',
    rules: ['숫자는 주변 여덟 칸에 있는 지뢰의 개수를 뜻합니다.', '지뢰로 확정한 칸에는 깃발을 표시합니다.', '지뢰가 없는 모든 칸을 열면 퍼즐이 완료됩니다.'],
    iconAsset: 'assets/icons/game-minesweeper.svg', primary: Color(0xFF7557D9), secondary: Color(0xFFFF7A59), surface: Color(0xFFF4EFFF),
  ),
  GameDefinition(
    id: 'yin-yang', order: 4, title: '음양', subtitle: '흑과 백의 조화를 완성하세요',
    tagline: '흑과 백의 조화를 완성하세요',
    description: '음양은 모든 칸을 흑과 백으로 채워 두 색의 연결과 2×2 규칙을 만족시키는 논리 퍼즐입니다.',
    rules: ['모든 흑색 칸은 하나로 연결되어야 합니다.', '모든 백색 칸도 하나로 연결되어야 합니다.', '2×2 영역 전체가 같은 색이 될 수 없습니다.'],
    iconAsset: 'assets/icons/game-yinyang.svg', primary: Color(0xFF8A4DFF), secondary: Color(0xFFE265C4), surface: Color(0xFFF7EFFF),
  ),
  GameDefinition(
    id: 'nonogram', order: 5, title: '노노그램', subtitle: '숫자 힌트로 그림을 완성해요',
    tagline: '숫자를 따라 그림을 완성하세요',
    description: '노노그램은 행과 열의 숫자 힌트를 이용해 칠해질 칸을 찾아 숨겨진 그림을 완성하는 퍼즐입니다.',
    rules: ['숫자는 연속해서 칠해야 하는 칸의 수를 뜻합니다.', '여러 숫자 그룹 사이에는 최소 한 칸이 비어야 합니다.', '확실히 비는 칸에는 X 표시를 합니다.'],
    iconAsset: 'assets/icons/game-nonogram.svg', primary: Color(0xFFF49A3F), secondary: Color(0xFF385276), surface: Color(0xFFFFF4E8),
  ),
  GameDefinition(
    id: 'killer-sudoku', order: 6, title: '킬러 스도쿠', subtitle: '합계 케이지로 푸는 스도쿠',
    tagline: '합계를 읽고 케이지를 풀어라',
    description: '킬러 스도쿠는 스도쿠 규칙에 점선 케이지의 합계 규칙이 더해진 고급 숫자 퍼즐입니다.',
    rules: ['기본 스도쿠의 행, 열, 3×3 영역 규칙을 지킵니다.', '각 케이지의 숫자 합은 표시된 값과 같아야 합니다.', '하나의 케이지 안에서 같은 숫자는 반복되지 않습니다.'],
    iconAsset: 'assets/icons/game-killer-sudoku.svg', primary: Color(0xFF4BA9F5), secondary: Color(0xFF3F35B5), surface: Color(0xFFEDF7FF),
  ),
  GameDefinition(
    id: 'star-battle', order: 7, title: '스타 배틀', subtitle: '별을 규칙에 맞게 배치하세요',
    tagline: '별을 배치하고 규칙을 완성하세요',
    description: '스타 배틀은 각 행, 열, 영역에 정해진 수의 별을 배치하는 공간 논리 퍼즐입니다.',
    rules: ['각 행에는 지정된 개수의 별이 들어갑니다.', '각 열과 각 영역에도 같은 개수의 별이 들어갑니다.', '별은 가로, 세로, 대각선으로 서로 닿을 수 없습니다.'],
    iconAsset: 'assets/icons/game-star-battle.svg', primary: Color(0xFFFFBE2E), secondary: Color(0xFF7251D6), surface: Color(0xFFFFF8DF),
  ),
  GameDefinition(
    id: 'light-up', order: 8, title: '라이트업', subtitle: '전구로 모든 칸을 비추세요',
    tagline: '모든 칸에 빛을 밝혀 보세요',
    description: '라이트업은 전구를 배치해 흰색 칸을 모두 비추면서 벽의 숫자 조건을 만족시키는 퍼즐입니다.',
    rules: ['모든 흰색 칸은 하나 이상의 전구 빛을 받아야 합니다.', '전구끼리는 서로 직접 비출 수 없습니다.', '숫자 벽 주변에는 표시된 개수만큼 전구가 있어야 합니다.'],
    iconAsset: 'assets/icons/game-lightup.svg', primary: Color(0xFF17B8D6), secondary: Color(0xFFFFCC46), surface: Color(0xFFEBFAFE),
  ),
  GameDefinition(
    id: 'futoshiki', order: 9, title: '후토시키', subtitle: '부등호로 푸는 숫자 퍼즐',
    tagline: '부등호를 따라 정답을 추론하세요',
    description: '후토시키는 라틴 방진 규칙과 셀 사이의 부등호를 이용해 숫자를 채우는 논리 퍼즐입니다.',
    rules: ['각 행에는 1부터 보드 크기까지의 숫자가 한 번씩 들어갑니다.', '각 열에도 같은 숫자가 한 번씩 들어갑니다.', '인접한 두 칸은 표시된 부등호 관계를 만족해야 합니다.'],
    iconAsset: 'assets/icons/game-futoshiki.svg', primary: Color(0xFF20A79A), secondary: Color(0xFFC79A31), surface: Color(0xFFECFAF7),
  ),
  GameDefinition(
    id: 'tents', order: 10, title: '텐트', subtitle: '나무 옆에 텐트를 배치하세요',
    tagline: '나무 옆에 완벽한 캠프를 만드세요',
    description: '텐트는 각 나무와 짝을 이루는 텐트를 배치하고 행과 열의 개수 힌트를 만족시키는 퍼즐입니다.',
    rules: ['각 텐트는 가로나 세로로 하나의 나무와 인접해야 합니다.', '각 나무는 하나의 텐트와만 연결됩니다.', '텐트끼리는 대각선을 포함해 서로 닿을 수 없습니다.'],
    iconAsset: 'assets/icons/game-tent.svg', primary: Color(0xFFF27A51), secondary: Color(0xFF3D9B69), surface: Color(0xFFFFF0E8),
  ),
  GameDefinition(
    id: 'jigsaw-sudoku', order: 11, title: '직소 스도쿠', subtitle: '불규칙 영역 스도쿠',
    tagline: '불규칙한 영역 속 규칙을 찾아라',
    description: '직소 스도쿠는 3×3 상자 대신 불규칙한 영역을 사용하는 스도쿠 변형 퍼즐입니다.',
    rules: ['각 행에는 1부터 9까지의 숫자가 한 번씩 들어갑니다.', '각 열에도 1부터 9까지의 숫자가 한 번씩 들어갑니다.', '각 불규칙 영역에도 1부터 9까지의 숫자가 한 번씩 들어갑니다.'],
    iconAsset: 'assets/icons/game-jigsaw-sudoku.svg', primary: Color(0xFF60BE50), secondary: Color(0xFF3978F6), surface: Color(0xFFF0F9ED),
  ),
  GameDefinition(
    id: 'skyscrapers', order: 12, title: '빌딩', subtitle: '외곽 힌트로 높이를 추론해요',
    tagline: '보이는 높이로 도시를 완성하세요',
    description: '빌딩은 외곽에서 보이는 건물의 개수를 단서로 각 칸의 건물 높이를 추론하는 퍼즐입니다.',
    rules: ['각 행과 열에는 1부터 보드 크기까지의 높이가 한 번씩 들어갑니다.', '높은 건물 뒤의 낮은 건물은 외곽에서 보이지 않습니다.', '외곽 숫자는 해당 방향에서 보이는 건물의 개수를 뜻합니다.'],
    iconAsset: 'assets/icons/game-building.svg', primary: Color(0xFF315E9A), secondary: Color(0xFF5EB9FF), surface: Color(0xFFEDF5FC),
  ),
  GameDefinition(
    id: 'kakuro', order: 13, title: '카쿠로', subtitle: '합계 힌트 숫자 크로스워드',
    tagline: '합계를 맞추고 숫자를 연결하세요',
    description: '카쿠로는 가로와 세로의 합계 힌트를 만족하도록 1부터 9까지의 숫자를 채우는 숫자 크로스워드입니다.',
    rules: ['각 흰색 칸에는 1부터 9까지의 숫자를 입력합니다.', '한 구간의 숫자 합은 검은 힌트 칸의 합계와 같아야 합니다.', '하나의 합계 구간 안에서 같은 숫자는 반복되지 않습니다.'],
    iconAsset: 'assets/icons/game-kakuro.svg', primary: Color(0xFFE65072), secondary: Color(0xFF7350E8), surface: Color(0xFFFFEEF3), isNew: true,
  ),
];

GameDefinition gameById(String id) => gameCatalog.firstWhere((game) => game.id == id);
