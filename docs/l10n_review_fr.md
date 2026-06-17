# Revue UX FR — `app_strings.dart` (_fr)

## 1. Note globale : **7,5 / 10**

Traduction globalement naturelle, terminologie ludique correcte (Sudoku, Démineur, Nonogramme, Gratte-ciels, Illumination). Vouvoiement cohérent. Principaux problèmes : **chaînes anglaises non traduites** (Binairo, tutoriel, badges, certains titres Sudoku), capitalisation à l'anglaise (Title Case au lieu de la casse phrase française), et quelques espaces fines manquantes.

## 2. Catégories fortes

- **Terminologie puzzle FR** : « Démineur », « Gratte-ciels », « Indice », « Cases », « Cage » — standard.
- **Ton vouvoiement** : cohérent (« Votre progression », « Appuyez », « Choisissez »), bon choix mobile.
- **Espaces avant `!` `?` `:`** : majoritairement présentes (« Félicitations ! », « Abandonner ? », « Temps : »).
- **Accents** : corrects partout (é, è, ê, ç, à).

## 3. P0 — corrections immédiates

| Clé | Actuel | Suggéré |
|---|---|---|
| `binairo.*` (≈25 clés) | Anglais (« Fill the grid… », « Pause », « Give Up »…) | À traduire intégralement (« Remplissez la grille de 0 et 1 », « Pause », « Abandonner »…) |
| `tutorial.page1-6.*` | Anglais (« What is Sudoku? », « Fill a 9×9 grid… ») | Traduire (« Qu'est-ce que le Sudoku ? », « Remplissez une grille 9×9 avec les chiffres 1 à 9. ») |
| `badge.firstClear.*` … `badge.streak30.*` (Sudoku) | Anglais (« First Step », « Complete your first puzzle ») | « Premier pas », « Terminez votre premier puzzle » |
| `badge.binairo_*.name/.desc` | Anglais | Traduire (« Débutant Binairo », « Terminez votre premier Binairo ») |
| `sudoku.about.*`, `sudoku.rules.r1-3` | Anglais | Traduire (« Qu'est-ce que le Sudoku ? », « Chaque ligne doit contenir les chiffres 1 à 9 une seule fois. ») |

## 4. P1 — améliorations graduelles

1. `home.newGame` « Nouvelle Partie » → casse phrase : **« Nouvelle partie »** (déjà utilisé pour `futoshiki.newGame`, harmoniser).
2. `home.todayPuzzle` « Puzzle du Jour » → **« Puzzle du jour »**.
3. `home.tutorial` « Comment Jouer » → **« Comment jouer »**.
4. `mode.title` « Mode de Jeu » → **« Mode de jeu »** ; `difficulty.title` « Difficulté » OK.
5. `mode.comingSoon` « Bientôt » → **« Bientôt disponible »** (plus clair en mobile).
6. `pause.elapsed` « Temps : » → ajouter **espace insécable fine** avant « : » (`Temps :`).
7. `result.grade.s/a/b` : éviter coupure mid-phrase ; reformuler en chaîne complète avec placeholders.
8. `settings.autoComplete.desc` « Remplir auto. quand toutes les cases sont déterminées » → **« Remplit automatiquement quand toutes les cases sont déterminées »**.
9. `donation.message` « Si vous appréciez cette app, » → **« Si l'application vous plaît, »** (« app » familier, virgule finale orpheline).
10. `daily.weekday.sun` « D » → **« Di »** (« D » ambigu, confondu avec autres jours).

## 5. Cohérence ton (vous/accents)

- **Vouvoiement** : 100 % cohérent dans la zone FR — conserver.
- **Casse** : mélange Title Case (Sudoku, accueil) vs casse phrase (Futoshiki/Kakuro/Démineur). Adopter la **casse phrase** partout (norme typographique FR).
- **Espaces fines insécables** avant `: ; ! ? » «` : à généraliser via ` `.
- **Apostrophe typographique** `'` recommandée (vs `'` droit) pour cohérence avec l'écosystème Apple/Android FR.

## 6. NE PAS modifier le code — revue documentaire uniquement.

---

**한국어 요약**: 프랑스어 영역은 어휘·존댓말(vous)·악센트 측면에서 자연스러우나, **Binairo 전체 / Sudoku 튜토리얼 / 모든 Sudoku·Binairo 배지명이 영문 그대로 방치**되어 있는 것이 가장 큰 문제(P0). 또한 게임별로 대문자 표기(Title Case vs 문장 표기)가 혼재하므로 프랑스어 표준인 문장형 표기로 통일 필요. 마침표·콜론 앞 가는 공백(U+202F)도 일부 누락. 전체 점수 7.5/10.
