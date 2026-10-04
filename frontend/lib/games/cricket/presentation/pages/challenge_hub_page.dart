import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../platform/services/platform_api_service.dart';
import '../../data/cricket_dataset.dart';
import '../../domain/models/cricket_models.dart';

class ChallengeHubPage extends ConsumerStatefulWidget {
  const ChallengeHubPage({super.key});

  @override
  ConsumerState<ChallengeHubPage> createState() => _ChallengeHubPageState();
}

class _ChallengeHubPageState extends ConsumerState<ChallengeHubPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _score = 0;
  int _streak = 0;

  // Mini Game 1: Who Am I?
  CricketPlayer? _whoAmITarget;
  int _revealedClues = 1;
  List<String> _whoAmIOptions = [];
  bool? _whoAmICorrect;

  static const Map<String, List<String>> _whoAmICustomClues = {
    "virat_kohli": [
      "I am known globally by the nickname 'King' or 'Chase Master'.",
      "I represented India and won the 2011 ODI World Cup & 2024 T20 World Cup.",
      "I hold the world record for the most centuries in ODI history (50 centuries).",
      "I scored 973 runs in a single IPL season (2016) with 4 centuries.",
      "I have amassed over 26,900 international runs across all formats.",
    ],
    "sachin_tendulkar": [
      "I am revered worldwide as the 'Little Master' and 'God of Cricket'.",
      "I made my international Test debut at age 16 against Pakistan in 1989.",
      "I am the only cricketer in history to score 100 international centuries.",
      "I was the first male cricketer to score a double century in ODI history (200* vs South Africa).",
      "I finished my career with 34,357 international runs across 664 matches.",
    ],
    "ms_dhoni": [
      "I am celebrated as 'Captain Cool' and 'Thala' for my composure under pressure.",
      "I famously hit the winning six to seal the 2011 ICC Cricket World Cup at Wankhede.",
      "I am the only captain in cricket history to win all three ICC white-ball trophies.",
      "I hold the record for the most stumpings in international cricket (195 stumpings).",
      "I scored 10,773 ODI runs with an average over 50 while batting in the lower-middle order.",
    ],
    "rohit_sharma": [
      "I am widely known by the nickname 'Hitman' for my effortless power hitting.",
      "I am the only batter in cricket history to score 3 double centuries in Men's ODIs.",
      "I hold the world record for the highest individual ODI score: 264 against Sri Lanka.",
      "I led India to victory in the 2024 ICC T20 World Cup as captain.",
      "I have struck over 620 international sixes, the most in international cricket history.",
    ],
    "ab_de_villiers": [
      "I earned the iconic nickname 'Mr. 360' for hitting boundaries all around the ground.",
      "I represented South Africa as an electrifying batter and wicket-keeper.",
      "I hold the world record for the fastest ODI fifty (16 balls) and fastest ODI century (31 balls).",
      "I scored 20,014 international runs with an average over 50 in both Tests and ODIs.",
      "I struck 149 off 44 balls in a famous ODI masterclass against the West Indies.",
    ],
    "wasim_akram": [
      "I am universally hailed as the 'Sultan of Swing' for my mastery of reverse swing.",
      "I was named Player of the Match in the 1992 ICC Cricket World Cup Final in Melbourne.",
      "I was the first bowler in history to capture 500 ODI wickets.",
      "I took two international hat-tricks in Tests and two in ODIs.",
      "I took 916 international wickets and scored a Test double-century (257*).",
    ],
    "shane_warne": [
      "I was crowned the 'King of Spin' and bowled the 'Ball of the Century' to Mike Gatting in 1993.",
      "I led Rajasthan Royals to the inaugural IPL championship title in 2008 as captain-coach.",
      "I took 708 Test wickets with my mesmerizing leg-spin and flippers.",
      "I was named Player of the Match in both the semi-final and final of the 1999 World Cup.",
      "I scored 3,154 Test runs with a top score of 99, the most runs without a Test century.",
    ],
    "muttiah_muralitharan": [
      "I am the all-time highest wicket-taker in both Test cricket and ODI cricket history.",
      "I took a staggering 800 wickets in 133 Tests and 534 wickets in ODIs for Sri Lanka.",
      "I claimed an unmatched 67 five-wicket hauls in Test match cricket.",
      "I was a key member of Sri Lanka's 1996 ICC Cricket World Cup winning squad.",
      "I accumulated 1,347 international wickets across my illustrious 19-year career.",
    ],
    "jasprit_bumrah": [
      "I am famous for my unorthodox sling-arm bowling action and pinpoint yorkers.",
      "I was named Player of the Tournament in India's triumphant 2024 ICC T20 World Cup campaign.",
      "I became the fastest Indian pacer to reach 100 Test wickets.",
      "I hold the world record for scoring 35 runs in a single Test over off Stuart Broad.",
      "I have captured over 390 international wickets across all three formats with an elite economy rate.",
    ],
    "brian_lara": [
      "I am famously known as the 'Prince of Trinidad'.",
      "I hold the world record for the highest individual score in Test history (400 not out vs England).",
      "I also hold the world record for the highest first-class score: 501 not out for Warwickshire.",
      "I scored 11,953 Test runs and 10,405 ODI runs for the West Indies.",
      "I scored 28 runs in a single Test over off Robin Peterson in 2003.",
    ],
    "chris_gayle": [
      "I crowned myself the 'Universe Boss' for my destructive boundary-hitting power.",
      "I scored the fastest century in T20 history off just 30 balls (175* for RCB in IPL 2013).",
      "I am one of only two players in history with two Test triple-centuries and an ODI double-century.",
      "I hit 553 international sixes and helped West Indies win two ICC T20 World Cups.",
      "I scored over 19,500 international runs across 483 matches.",
    ],
    "glenn_mcgrath": [
      "I was nicknamed 'Pigeon' and known for relentless metronomic accuracy on the corridor of uncertainty.",
      "I won three consecutive ICC Cricket World Cups with Australia (1999, 2003, 2007).",
      "I hold the all-time record for the most wickets in World Cup history (71 wickets).",
      "I took 563 Test wickets and 381 ODI wickets with a career economy under 3.9.",
      "I claimed best ODI bowling figures of 7/15 against Namibia in the 2003 World Cup.",
    ],
    "mitchell_starc": [
      "I am Australia's premier left-arm fast bowler known for fast, swinging yorkers.",
      "I was named Player of the Tournament at the 2015 ICC Cricket World Cup with 22 wickets.",
      "I hold the record for the most wickets in a single World Cup edition (27 wickets in 2019).",
      "I have taken over 660 international wickets across Tests, ODIs, and T20Is.",
      "I famously bowled Brendon McCullum in the first over of the 2015 World Cup Final.",
    ],
    "shaheen_afridi": [
      "I am Pakistan's premier tall left-arm fast bowler known for opening-over breakthroughs.",
      "I produced a sensational 3-wicket opening spell vs India at the 2021 T20 World Cup in Dubai.",
      "I became the youngest bowler to take a 6-wicket haul in World Cup history (6/35 vs Bangladesh at Lord's).",
      "I was awarded the ICC Men's Cricketer of the Year (Sir Garfield Sobers Trophy) in 2021.",
      "I have crossed 300 international wickets with 113 in Tests and over 100 in ODIs.",
    ],
    "ben_stokes": [
      "I produced two of the most miraculous fourth-innings masterclasses in 2019 at Lord's and Headingley.",
      "I hit 135* to win the Ashes Test at Headingley with a 76-run last-wicket partnership with Jack Leach.",
      "I was named Player of the Match in the dramatic 2019 ICC Cricket World Cup Final.",
      "I captained England in Test cricket under the revolutionary aggressive 'Bazball' philosophy.",
      "I have accumulated over 10,500 international runs and taken over 280 international wickets.",
    ],
    "dale_steyn": [
      "I was nicknamed the 'Steyn Gun' for my searing 150 km/h outswingers and fiery vein-popping celebrations.",
      "I remained the ICC No. 1 ranked Test bowler in the world for a record 263 consecutive weeks.",
      "I captured 439 Test wickets in 93 matches with a sensational strike rate of 42.3.",
      "I took 699 international wickets for South Africa across all formats.",
      "I took 7/51 against India in Nagpur in 2010 to seal a historic Test win in subcontinental conditions.",
    ],
    "ricky_ponting": [
      "I am known by the nickname 'Punter' and was renowned as the finest puller and hooker of fast bowling.",
      "I captained Australia to back-to-back undefeated ICC ODI World Cup championships in 2003 and 2007.",
      "I smashed 140 not out off 121 balls in the 2003 World Cup Final in Johannesburg.",
      "I scored 27,483 international runs with 71 international centuries (41 in Tests, 30 in ODIs).",
      "I am the most successful captain in international cricket history with 220 international wins.",
    ],
    "kumar_sangakkara": [
      "I am a stylish Sri Lankan left-handed batter and wicket-keeper who scored 28,016 international runs.",
      "I scored 4 consecutive centuries in the 2015 ICC Cricket World Cup, an all-time tournament record.",
      "I scored 12,400 Test runs at an extraordinary average of 57.40 with 38 centuries and 11 double-tons.",
      "I helped Sri Lanka win the 2014 ICC World Twenty20, winning Player of the Match in the final.",
      "I share the world record for the highest partnership in Test history (624 runs with Mahela Jayawardene).",
    ],
    "lasith_malinga": [
      "I am famous for my round-arm 'slinga' action and lethal dipping toe-crushers.",
      "I am the only bowler in history to take 4 wickets in 4 consecutive balls twice in international cricket.",
      "I captained Sri Lanka to the ICC Men's T20 World Cup title in 2014.",
      "I took 338 ODI wickets and 107 T20I wickets, including 3 ODI hat-tricks.",
      "I defended 9 runs in the final over of the 2019 IPL final to win the title for Mumbai Indians.",
    ],
    "jacques_kallis": [
      "I am widely considered the greatest all-rounder in the history of modern cricket.",
      "I represented South Africa and scored 13,289 Test runs (45 centuries) and 11,579 ODI runs (17 centuries).",
      "I took 292 Test wickets and 273 ODI wickets with my brisk medium-fast bowling.",
      "I am the only player in history with 10,000+ runs and 250+ wickets in both Tests and ODIs.",
      "I took 338 international catches, standing as a legendary slip fielder.",
    ],
    "kapil_dev": [
      "I captained India to their historic maiden ICC World Cup title at Lord's in 1983.",
      "I famously scored a match-winning 175 not out against Zimbabwe from 17/5 in the 1983 World Cup.",
      "I retired as the world's highest Test wicket-taker with 434 Test wickets.",
      "I never bowled a single no-ball in my entire 16-year international career.",
      "I scored 5,248 Test runs and took 434 wickets as India's greatest pace-bowling all-rounder.",
    ],
    "sunil_gavaskar": [
      "I am known as the 'Little Master' and the original master of classical opening batting.",
      "I scored 774 runs in my debut Test series against the mighty West Indies in 1971.",
      "I was the first batter in cricket history to reach 10,000 Test match runs (1987).",
      "I scored 34 Test centuries without wearing a helmet against the most ferocious fast bowlers.",
      "I finished my Test career with 10,122 runs in 125 matches at an average of 51.12.",
    ],
    "adam_gilchrist": [
      "I revolutionized the role of the wicket-keeper batsman in modern international cricket.",
      "I won three consecutive ICC Cricket World Cups with Australia in 1999, 2003, and 2007.",
      "I famously batted with a squash ball in my left glove while scoring 149 in the 2007 World Cup Final.",
      "I scored 9,619 ODI runs at a blistering strike rate of 96.94 with 16 centuries.",
      "I completed 905 international dismissals (813 catches and 92 stumpings) as wicket-keeper.",
    ],
    "anil_kumble": [
      "I was nicknamed 'Jumbo' for my pace off the pitch and unmatched competitive grit.",
      "I became only the second bowler in Test history to take all 10 wickets in an innings (10/74 vs Pakistan in 1999).",
      "I bowled with a broken, bandaged jaw in Antigua in 2002, famously dismissing Brian Lara.",
      "I am India's all-time leading wicket-taker with 619 Test wickets and 337 ODI wickets.",
      "I finished with 956 international wickets, the fourth-highest in cricket history.",
    ],
    "viv_richards": [
      "I was universally known as 'The Master Blaster' and batted without a helmet with supreme swagger.",
      "I scored a match-winning 138 not out in the 1979 ICC World Cup Final at Lord's.",
      "I smashed a 56-ball Test century against England in 1986, which stood as the fastest for 30 years.",
      "I scored 8,540 Test runs and 6,721 ODI runs at a ferocious strike rate ahead of my era.",
      "I won two World Cups with the West Indies (1975 & 1979) and never lost a Test series as captain.",
    ],
    "brendon_mccullum": [
      "I am the fearless Kiwi captain who ignited the revolutionary aggressive 'Bazball' mindset.",
      "I hold the record for the fastest century in Test cricket history off just 54 balls (vs Australia in 2016).",
      "I scored the first-ever IPL century (158* off 73 balls for KKR) on the tournament's opening night in 2008.",
      "I captained New Zealand to their first-ever ICC Cricket World Cup Final in 2015.",
      "I scored 14,676 international runs with 300+ international sixes across all formats.",
    ],
    "shahid_afridi": [
      "I am beloved across the world as 'Boom Boom' for my explosive batting and quick leg-spin.",
      "I smashed a 37-ball ODI century against Sri Lanka in 1996 in just my second international match.",
      "I was named Player of the Match in both the semi-final and final of the 2009 ICC T20 World Cup.",
      "I hit 476 international sixes and took 395 ODI wickets for Pakistan.",
      "I took 541 international wickets and accumulated over 11,000 international runs.",
    ],
    "courtney_walsh": [
      "I formed one of the most fearsome fast bowling duos in cricket history alongside Curtly Ambrose.",
      "I was the first bowler in cricket history to reach 500 Test wickets (in 2001).",
      "I captured 519 Test wickets in 132 matches for the West Indies.",
      "I famously took 5 wickets for just 1 run (5/1) against Sri Lanka in Sharjah in 1993.",
      "I took 746 international wickets across my marathon 17-year international career.",
    ],
    "james_anderson": [
      "I am the only fast bowler in cricket history to reach 700 Test wickets.",
      "I claimed 704 Test wickets across 188 Test matches for England, bowling with sublime swing and seam.",
      "I played international cricket across four different decades from 2002 to 2024.",
      "I took 991 international wickets across all formats, the most by any pace bowler in history.",
      "I formed an iconic bowling partnership with Stuart Broad, taking over 1,000 Test wickets together.",
    ],
    "pat_cummins": [
      "I captained Australia to victory in the 2023 ICC World Test Championship and 2023 ODI World Cup.",
      "I became the first bowler in history to take hat-tricks in consecutive matches at the 2024 ICC T20 World Cup.",
      "I was named ICC Men's Cricketer of the Year (Sir Garfield Sobers Trophy) in 2023.",
      "I debuted as an 18-year-old taking 6/79 and hitting the winning runs in Johannesburg in 2011.",
      "I have captured over 500 international wickets with elite pace, bounce, and lower-order hitting.",
    ],
    "rashid_khan": [
      "I am the Afghan leg-spin wizard famous for my lightning-fast arm speed and unpickable googlies.",
      "I became the youngest player to captain an international cricket team at age 19.",
      "I became the fastest bowler to reach 100 ODI wickets (in just 44 matches).",
      "I have captured over 380 international wickets while dominating T20 leagues worldwide.",
      "I took a hat-trick in four consecutive balls in a T20I against Ireland in 2019.",
    ],
    "ravichandran_ashwin": [
      "I am the master Indian off-spinner and tactical maestro with over 500 Test wickets.",
      "I have won 11 Player of the Series awards in Test cricket, tied for the second-most in history.",
      "I have claimed 37 five-wicket hauls in Test matches and scored 5 Test centuries.",
      "I was part of India's winning squads in the 2011 ODI World Cup and 2013 ICC Champions Trophy.",
      "I have taken 764 international wickets across all three formats for India.",
    ],
    "sanath_jayasuriya": [
      "I transformed ODI cricket forever with pinch-hitting aggression in the 1996 World Cup.",
      "I was named Player of the Tournament in Sri Lanka's 1996 ICC Cricket World Cup triumph.",
      "I scored 13,430 ODI runs with 28 centuries and took 323 ODI wickets with my left-arm spin.",
      "I scored 340 in a Test match against India in 1997, part of a world-record 952/6 total.",
      "I hit 352 international sixes and claimed 440 international wickets.",
    ],
    "mahela_jayawardene": [
      "I was one of the most elegant and tactical batting captains in Sri Lankan cricket history.",
      "I scored a magnificent century (103*) in the 2011 ICC Cricket World Cup Final in Mumbai.",
      "I shared the highest partnership in Test cricket history: 624 runs with Kumar Sangakkara.",
      "I scored 374 in a Test innings against South Africa in Colombo in 2006.",
      "I scored 25,957 international runs and took 440 catches across my legendary career.",
    ],
    "sourav_ganguly": [
      "I am revered as 'Dada' and the 'Prince of Kolkata' for my fearless leadership.",
      "I scored 131 on my Test debut at Lord's in 1996.",
      "I led India to the 2003 ICC Cricket World Cup Final and a historic Test series draw in Australia.",
      "I scored 11,363 ODI runs (22 centuries) and formed a legendary opening partnership with Sachin.",
      "I won 4 consecutive Man of the Match awards in the 1997 Sahara Cup against Pakistan.",
    ],
    "rahul_dravid": [
      "I earned the iconic moniker 'The Wall' for my impenetrable defensive technique and grit.",
      "I faced 31,258 balls and batted for 44,152 minutes in Test cricket, the most in history.",
      "I scored 13,288 Test runs (36 centuries) and 10,889 ODI runs (12 centuries) for India.",
      "I took 210 catches in Test matches, the world record for a non-wicketkeeper.",
      "I coached India to glory in the 2024 ICC Men's T20 World Cup.",
    ],
    "yuvraj_singh": [
      "I was named Player of the Tournament in India's triumphant 2011 ICC Cricket World Cup campaign.",
      "I smashed 6 sixes in an over off Stuart Broad in the 2007 ICC T20 World Cup in Durban.",
      "I scored 8,701 ODI runs and took 111 wickets as an elite middle-order match-winner.",
      "I scored 362 runs and took 15 wickets in the 2011 World Cup, winning 4 Man of the Match awards.",
      "I hit the fastest fifty in T20 international history off just 12 balls.",
    ],
    "zaheer_khan": [
      "I was the spearhead of India's pace attack and master of the knuckleball and reverse swing.",
      "I was the joint-leading wicket-taker in the 2011 ICC Cricket World Cup with 21 wickets.",
      "I captured 311 Test wickets and 282 ODI wickets across my 14-year international career.",
      "I took 611 international wickets across all formats for India.",
      "I bowled the opening maiden over and set the tone in the 2011 World Cup Final against Sri Lanka.",
    ],
    "steve_waugh": [
      "I was the gritty Australian captain who led the era of 'Mental Disintegration' and undefeated domination.",
      "I captained Australia to victory in the 1999 ICC Cricket World Cup.",
      "I scored 120 not out against South Africa in the 1999 World Cup Super Six thriller.",
      "I scored 10,927 Test runs with 32 centuries and 7,569 ODI runs for Australia.",
      "I led Australia to a world-record 16 consecutive Test match victories.",
    ],
  };

  // Mini Game 2: Higher or Lower
  CricketPlayer? _hlPlayerA;
  CricketPlayer? _hlPlayerB;
  String _hlStatKey = 'odi_runs';
  String _hlStatLabel = 'ODI Runs';
  bool? _hlCorrect;
  final List<String> _seenHlPairs = [];

  static const List<Map<String, dynamic>> _hlCategories = [
    {"key": "odi_runs", "label": "ODI Runs", "roles": ["Batter", "All-Rounder", "Wicket-Keeper"]},
    {"key": "test_runs", "label": "Test Runs", "roles": ["Batter", "All-Rounder", "Wicket-Keeper"]},
    {"key": "test_wickets", "label": "Test Wickets", "roles": ["Bowler", "All-Rounder"]},
    {"key": "odi_wickets", "label": "ODI Wickets", "roles": ["Bowler", "All-Rounder"]},
    {"key": "international_runs", "label": "International Runs", "roles": ["Batter", "All-Rounder", "Wicket-Keeper"]},
    {"key": "international_wickets", "label": "International Wickets", "roles": ["Bowler", "All-Rounder"]},
    {"key": "international_centuries", "label": "International Centuries", "roles": ["Batter", "All-Rounder", "Wicket-Keeper"]},
    {"key": "international_sixes", "label": "International Sixes", "roles": ["Batter", "All-Rounder", "Wicket-Keeper", "Bowler"]},
    {"key": "wk_dismissals", "label": "WK Dismissals", "roles": ["Wicket-Keeper"]},
    {"key": "wk_stumpings", "label": "WK Stumpings", "roles": ["Wicket-Keeper"]},
    {"key": "captaincy_wins", "label": "Captaincy Wins", "roles": ["Batter", "Bowler", "All-Rounder", "Wicket-Keeper"]},
    {"key": "test_five_wickets", "label": "Test 5-Wkt Hauls", "roles": ["Bowler", "All-Rounder"]},
    {"key": "international_catches", "label": "International Catches", "roles": ["Batter", "Bowler", "All-Rounder", "Wicket-Keeper"]},
    {"key": "t20i_runs", "label": "T20I Runs", "roles": ["Batter", "All-Rounder", "Wicket-Keeper"]},
    {"key": "odi_fifties", "label": "ODI Fifties", "roles": ["Batter", "All-Rounder", "Wicket-Keeper"]},
  ];

  // Mini Game 3: Stat or Fiction (65 curated items)
  int _sofIdx = 0;
  bool? _sofAnsweredCorrect;
  List<int> _sofOrder = [];
  int _sofOrderPos = 0;

  final List<Map<String, dynamic>> _sofQuestions = [
    {
      "statement": "Sachin Tendulkar scored a century on his international Test debut against Pakistan in 1989.",
      "is_true": false,
      "explanation": "Sachin made his debut in Karachi at age 16 and scored 15 runs in the first innings before being bowled by Waqar Younis."
    },
    {
      "statement": "Shane Warne was the first bowler in cricket history to reach 800 Test wickets.",
      "is_true": false,
      "explanation": "Muttiah Muralitharan is the only bowler in history to reach 800 Test wickets. Shane Warne retired with 708 Test wickets."
    },
    {
      "statement": "Virat Kohli holds the world record for the highest individual score in Men's T20 Internationals with 175 not out.",
      "is_true": false,
      "explanation": "Chris Gayle scored 175* in the IPL (franchise T20), while Aaron Finch holds the highest Men's T20I score with 172."
    },
    {
      "statement": "Wasim Akram never scored a double-century in Test cricket during his career.",
      "is_true": false,
      "explanation": "Wasim Akram smashed a sensational 257 not out against Zimbabwe in Sheikhupura in 1996 with 12 massive sixes."
    },
    {
      "statement": "Rohit Sharma scored a century in all 9 matches India played during the 2019 ICC Cricket World Cup.",
      "is_true": false,
      "explanation": "Rohit scored a tournament record 5 centuries in 9 matches in 2019 (vs SA, PAK, ENG, BAN, SL)."
    },
    {
      "statement": "Muttiah Muralitharan took exactly 750 wickets in Test Cricket.",
      "is_true": false,
      "explanation": "Muttiah Muralitharan is the all-time leading wicket-taker in Tests with 800 wickets and 67 five-wicket hauls."
    },
    {
      "statement": "Don Bradman finished his Test career with a perfect batting average of 100.00.",
      "is_true": false,
      "explanation": "Bradman was bowled for a duck by Eric Hollies in his final Test innings at The Oval in 1948, finishing with a career average of 99.94."
    },
    {
      "statement": "MS Dhoni scored an ODI century against Australia in the 2011 ICC Cricket World Cup Final.",
      "is_true": false,
      "explanation": "India played Sri Lanka in the 2011 Final at Wankhede, where Dhoni scored a match-winning 91 not out (not a century)."
    },
    {
      "statement": "Jasprit Bumrah has captured over 500 wickets in Test match cricket.",
      "is_true": false,
      "explanation": "Bumrah has taken around 160 Test wickets (and over 390 across all international formats) with an elite average under 21."
    },
    {
      "statement": "AB de Villiers scored 300 runs in a single Test innings for South Africa.",
      "is_true": false,
      "explanation": "AB de Villiers's highest Test score is 278 not out against Pakistan in Abu Dhabi in 2010. Hashim Amla is SA's only Test triple centurion."
    },
    {
      "statement": "Brendon McCullum hit 6 sixes in an over during an international T20 World Cup match.",
      "is_true": false,
      "explanation": "Yuvraj Singh hit 6 sixes in an over in the 2007 T20 World Cup off Stuart Broad. McCullum never hit 6 sixes in an over."
    },
    {
      "statement": "Brian Lara's 400 not out against England is the second-highest individual score in Test history.",
      "is_true": false,
      "explanation": "Brian Lara's 400* at Antigua in 2004 remains the highest individual score in Test cricket history."
    },
    {
      "statement": "Ricky Ponting lost three consecutive ICC World Cup finals as captain of Australia.",
      "is_true": false,
      "explanation": "Ricky Ponting captained Australia to back-to-back undefeated World Cup titles in 2003 and 2007."
    },
    {
      "statement": "Brian Lara scored 400 not out and 375 against two completely different international teams.",
      "is_true": false,
      "explanation": "Both of Lara's world record scores (375 in 1994 and 400* in 2004) were scored against England at the Antigua Recreation Ground."
    },
    {
      "statement": "Shaheen Afridi took a hat-trick in the very first over of a Test match in Karachi.",
      "is_true": false,
      "explanation": "Irfan Pathan of India is the only bowler in cricket history to take a hat-trick in the 1st over of a Test match (vs Pakistan in 2006)."
    },
    {
      "statement": "Sachin Tendulkar scored exactly 99 international centuries across Test and ODI cricket.",
      "is_true": false,
      "explanation": "Sachin Tendulkar is the only player in history to score 100 international centuries (51 Tests + 49 ODIs)."
    },
    {
      "statement": "Jim Laker and Anil Kumble are the only two bowlers to take all 10 wickets in a Test innings.",
      "is_true": false,
      "explanation": "Ajaz Patel of New Zealand also took all 10 wickets in an innings vs India in Mumbai in 2021 (3 bowlers total in Test history)."
    },
    {
      "statement": "Adam Gilchrist scored a century in all three ICC World Cup finals he played (1999, 2003, 2007).",
      "is_true": false,
      "explanation": "Gilchrist scored 54 in 1999, 57 in 2003, and 149 in 2007 (one century across the three finals)."
    },
    {
      "statement": "Yuvraj Singh won Player of the Tournament in both the 2007 T20 World Cup and 2011 ODI World Cup.",
      "is_true": false,
      "explanation": "Shahid Afridi was named Player of the Tournament in the 2007 T20 World Cup; Yuvraj won it in the 2011 ODI World Cup."
    },
    {
      "statement": "Steve Smith made his international Test debut as a specialist opening batter for Australia.",
      "is_true": false,
      "explanation": "Steve Smith debuted batting at No. 8 and bowling leg-spin against Pakistan at Lord's in 2010 before becoming a premier batter."
    },
    {
      "statement": "Pat Cummins is the only captain to win the WTC, ODI World Cup, and T20 World Cup all in the same calendar year.",
      "is_true": false,
      "explanation": "Australia won the WTC and ODI World Cup in 2023 under Cummins, but India won the 2024 T20 World Cup."
    },
    {
      "statement": "Shoaib Akhtar's world-record 161.3 km/h delivery was bowled against Australia in Melbourne.",
      "is_true": false,
      "explanation": "It was bowled against England's Nick Knight during the 2003 ICC World Cup in Cape Town, South Africa."
    },
    {
      "statement": "Shane Warne scored 3 Test centuries during his legendary 145-match international career.",
      "is_true": false,
      "explanation": "Shane Warne holds the world record for the most Test runs (3,154) without ever scoring a century (highest score 99)."
    },
    {
      "statement": "Jacques Kallis bowled at 155 km/h, making him the fastest bowler in South African cricket history.",
      "is_true": false,
      "explanation": "Kallis bowled reliable fast-medium pace around 135-140 km/h; Dale Steyn and Allan Donald were South Africa's express speedsters."
    },
    {
      "statement": "Sunil Gavaskar wore a lightweight carbon-fiber helmet throughout his entire 125-Test career.",
      "is_true": false,
      "explanation": "Gavaskar famously faced the fiercest West Indian pace quartets throughout the 1970s and 80s without ever wearing a helmet."
    },
    {
      "statement": "Don Bradman was dismissed for a duck on his Test debut for Australia against England.",
      "is_true": false,
      "explanation": "Bradman scored 18 & 1 on debut in Brisbane in 1928, was dropped for the second Test, and returned with a century in the third Test."
    },
    {
      "statement": "Virat Kohli has never bowled a single delivery in ICC knockout matches.",
      "is_true": false,
      "explanation": "Kohli bowled in the 2016 T20 World Cup semi-final against the West Indies in Mumbai and took a wicket off his very first delivery!"
    },
    {
      "statement": "Lasith Malinga is the only Sri Lankan bowler to have taken over 800 international wickets.",
      "is_true": false,
      "explanation": "Malinga took 546 international wickets; Muttiah Muralitharan is the Sri Lankan bowler with 1,347 international wickets."
    },
    {
      "statement": "Chris Gayle is the only batter to score a double century in both ODI World Cups and T20 World Cups.",
      "is_true": false,
      "explanation": "Gayle scored 215 in the 2015 ODI World Cup, but no player in cricket history has ever scored a double century in T20 Internationals."
    },
    {
      "statement": "Kapil Dev's legendary 175 not out in the 1983 World Cup was fully recorded and televised live across India.",
      "is_true": false,
      "explanation": "BBC television technicians were on strike that day in Tunbridge Wells, so no official television footage of the innings exists."
    },
    {
      "statement": "Glenn McGrath conceded more than 100 runs in an ODI innings on four separate occasions.",
      "is_true": false,
      "explanation": "McGrath was renowned for metronomic accuracy and never conceded 100 runs in an ODI, finishing with a career economy rate of 3.88."
    },
    {
      "statement": "James Anderson has taken more five-wicket hauls in Test cricket than Muttiah Muralitharan.",
      "is_true": false,
      "explanation": "Anderson took 32 five-wicket hauls in Tests, whereas Muralitharan holds the world record with 67 five-wicket hauls."
    },
    {
      "statement": "Kumar Sangakkara holds the record for the most double centuries in Test cricket history with 14 double tons.",
      "is_true": false,
      "explanation": "Sir Don Bradman holds the world record with 12 Test double centuries; Sangakkara is second with 11 double centuries."
    },
    {
      "statement": "Ben Stokes has captained England to victory in three consecutive ICC World Cup tournaments.",
      "is_true": false,
      "explanation": "Eoin Morgan and Jos Buttler were the white-ball captains who lifted the World Cups; Stokes captains England in Test cricket."
    },
    {
      "statement": "Courtney Walsh was the first bowler to take 800 Test wickets in international cricket history.",
      "is_true": false,
      "explanation": "Courtney Walsh was the first bowler to reach 500 Test wickets (retiring with 519); Muralitharan was first to 800."
    },
    {
      "statement": "Rahul Dravid holds the record for the highest individual score in Men's ODI cricket history.",
      "is_true": false,
      "explanation": "Rohit Sharma holds the ODI record with 264 vs Sri Lanka. Dravid's highest ODI score is 153."
    },
    {
      "statement": "Dale Steyn retired with exactly 300 Test wickets for South Africa.",
      "is_true": false,
      "explanation": "Dale Steyn retired as South Africa's highest Test wicket-taker with 439 wickets in 93 matches."
    },
    {
      "statement": "Anil Kumble is the only Indian captain to lead India to an ICC ODI World Cup victory.",
      "is_true": false,
      "explanation": "Kapil Dev (1983) and MS Dhoni (2011) are the two captains who led India to ODI World Cup titles."
    },
    {
      "statement": "Rohit Sharma is the only batter in cricket history with 3 double centuries in Men's ODIs.",
      "is_true": true,
      "explanation": "Rohit scored 209 vs Australia (2013), 264 vs Sri Lanka (2014), and 208* vs Sri Lanka (2017)."
    },
    {
      "statement": "Virat Kohli scored 50 ODI centuries, breaking Sachin Tendulkar's long-standing record of 49.",
      "is_true": true,
      "explanation": "Virat Kohli reached his 50th ODI century at the 2023 ICC World Cup semi-final at Wankhede Stadium."
    },
    {
      "statement": "Chris Gayle hit the fastest century in T20 cricket history off just 30 balls.",
      "is_true": true,
      "explanation": "Gayle smashed 175* off 66 balls in IPL 2013 for RCB vs PWI, reaching 100 in 30 balls."
    },
    {
      "statement": "AB de Villiers scored the fastest ODI century in history in just 31 balls.",
      "is_true": true,
      "explanation": "AB de Villiers smashed a 31-ball ton against the West Indies in Johannesburg in January 2015."
    },
    {
      "statement": "Wasim Akram was the first bowler in cricket history to reach 500 ODI wickets.",
      "is_true": true,
      "explanation": "Wasim Akram reached the 500-wicket milestone during the 2003 World Cup, finishing with 502 ODI wickets."
    },
    {
      "statement": "MS Dhoni hit a six to finish and win the 2011 ICC Cricket World Cup for India.",
      "is_true": true,
      "explanation": "Dhoni hit Nuwan Kulasekara over long-on for six to seal the 2011 World Cup at Wankhede."
    },
    {
      "statement": "Lasith Malinga is the only bowler to take 4 wickets in 4 consecutive balls twice in international cricket.",
      "is_true": true,
      "explanation": "Malinga achieved 4 in 4 against South Africa (2007 World Cup) and New Zealand (2019 T20I)."
    },
    {
      "statement": "Jacques Kallis scored over 10,000 runs and took over 250 wickets in both Tests and ODIs.",
      "is_true": true,
      "explanation": "Kallis is the only all-rounder in history to achieve the 10,000 run / 250 wicket double in both formats."
    },
    {
      "statement": "Yuvraj Singh hit 6 sixes in an over off Stuart Broad in the 2007 ICC T20 World Cup.",
      "is_true": true,
      "explanation": "Yuvraj achieved the feat in Durban in September 2007, reaching a 12-ball fifty."
    },
    {
      "statement": "Glenn McGrath holds the all-time record for the most wickets in ICC Cricket World Cup history.",
      "is_true": true,
      "explanation": "Glenn McGrath captured 71 wickets in 39 matches across 4 World Cup tournaments."
    },
    {
      "statement": "Shoaib Akhtar delivered the fastest officially recorded ball in cricket history at 161.3 km/h (100.2 mph).",
      "is_true": true,
      "explanation": "Bowled against England during the 2003 World Cup in South Africa to Nick Knight."
    },
    {
      "statement": "Jasprit Bumrah holds the world record for the most runs scored off a single over in Test cricket.",
      "is_true": true,
      "explanation": "Bumrah smashed Stuart Broad for 29 runs off the bat (35 runs total in the over) at Edgbaston in 2022."
    },
    {
      "statement": "Sanath Jayasuriya took more ODI wickets in his career than Shane Warne.",
      "is_true": true,
      "explanation": "Jayasuriya took 323 ODI wickets with his left-arm spin, whereas Warne took 293 ODI wickets."
    },
    {
      "statement": "Ben Stokes was awarded Player of the Match in the 2019 ICC Cricket World Cup Final.",
      "is_true": true,
      "explanation": "Stokes scored 84* in regulation and batted in the Super Over to win the title for England."
    },
    {
      "statement": "Kumar Sangakkara scored 4 consecutive centuries in a single ICC World Cup edition.",
      "is_true": true,
      "explanation": "Achieved at the 2015 World Cup vs Bangladesh, England, Australia, and Scotland."
    },
    {
      "statement": "Dale Steyn was ranked the ICC No. 1 Test bowler in the world for over 5 consecutive years.",
      "is_true": true,
      "explanation": "Steyn held the World No. 1 ranking for a record 263 weeks between 2008 and 2014."
    },
    {
      "statement": "Shahid Afridi scored his fastest 37-ball ODI century using a bat given by Sachin Tendulkar.",
      "is_true": true,
      "explanation": "Afridi borrowed Waqar Younis's kit bag which held a spare bat given by Sachin Tendulkar."
    },
    {
      "statement": "James Anderson is the first and only fast bowler in cricket history to take 700 Test wickets.",
      "is_true": true,
      "explanation": "Anderson finished with 704 Test wickets across 188 matches for England."
    },
    {
      "statement": "Sunil Gavaskar was the first cricketer in history to reach 10,000 Test runs.",
      "is_true": true,
      "explanation": "Gavaskar crossed 10,000 Test runs in March 1987 in Ahmedabad against Pakistan."
    },
    {
      "statement": "Adam Gilchrist batted with a squash ball inside his batting glove in the 2007 World Cup Final.",
      "is_true": true,
      "explanation": "Gilchrist smashed 149 off 104 balls using a squash ball for a firmer top-hand grip."
    },
    {
      "statement": "Brendon McCullum scored the fastest Test century in history off just 54 balls.",
      "is_true": true,
      "explanation": "Scored against Australia in his farewell Test at Christchurch in February 2016."
    },
    {
      "statement": "MS Dhoni is the only captain to win the T20 World Cup, ODI World Cup, and Champions Trophy.",
      "is_true": true,
      "explanation": "Dhoni won the 2007 T20 WC, 2011 ODI WC, and 2013 ICC Champions Trophy for India."
    },
    {
      "statement": "Eoin Morgan hit a world record 17 sixes in a single ODI innings during the 2019 World Cup.",
      "is_true": true,
      "explanation": "Morgan smashed 148 off 71 balls with 17 sixes against Afghanistan at Old Trafford."
    },
    {
      "statement": "Mitchell Starc was the leading wicket-taker in both the 2015 and 2019 ICC World Cups.",
      "is_true": true,
      "explanation": "Starc took 22 wickets in 2015 and a tournament-record 27 wickets in 2019."
    },
    {
      "statement": "Virender Sehwag and Chris Gayle are the only two cricketers with two Test 300s and an ODI 200.",
      "is_true": true,
      "explanation": "Both icons registered two triple-centuries in Tests and a double-century in ODIs."
    },
    {
      "statement": "Pat Cummins took two hat-tricks in consecutive matches during the 2024 ICC T20 World Cup.",
      "is_true": true,
      "explanation": "Cummins took hat-tricks against Bangladesh and Afghanistan in the Super 8 stage."
    },
    {
      "statement": "Chaminda Vaas took 8/19 in an ODI, the best bowling figures in Men's ODI history.",
      "is_true": true,
      "explanation": "Vaas took 8 wickets for 19 runs against Zimbabwe in Colombo in 2001."
    },
    {
      "statement": "Muttiah Muralitharan claimed 67 five-wicket hauls in Test cricket, the most in history.",
      "is_true": true,
      "explanation": "Muralitharan took 67 five-wicket hauls, far ahead of Shane Warne in second place (37)."
    },
    {
      "statement": "Courtney Walsh was the first bowler in cricket history to reach 500 Test wickets.",
      "is_true": true,
      "explanation": "The West Indian fast bowler reached 500 Test wickets in March 2001."
    },
    {
      "statement": "Viv Richards scored a 56-ball Test century against England in 1986.",
      "is_true": true,
      "explanation": "The Master Blaster's 56-ball hundred in Antigua stood as the fastest Test ton for 30 years."
    },
    {
      "statement": "Kapil Dev never bowled a single no-ball in his entire 16-year international career.",
      "is_true": true,
      "explanation": "Kapil Dev bowled over 4,800 overs in international cricket without overstepping the crease once."
    },
    {
      "statement": "India's lowest completed innings total in Test cricket history is 36 all out.",
      "is_true": true,
      "explanation": "Occurred at the Adelaide Oval against Australia in the Day-Night Test in December 2020."
    },
    {
      "statement": "Anil Kumble took 10 wickets in a single Test innings against Pakistan at Feroz Shah Kotla in 1999.",
      "is_true": true,
      "explanation": "Kumble took 10/74 in Delhi, becoming only the second bowler in Test history to take all 10 wickets in an innings."
    },
    {
      "statement": "Ricky Ponting is the only cricketer to feature in over 100 Test match victories as a player.",
      "is_true": true,
      "explanation": "Ponting featured in 108 Test match victories for Australia, the most by any player in history."
    },
    {
      "statement": "Rahul Dravid faced more deliveries (31,258 balls) than any batter in Test match history.",
      "is_true": true,
      "explanation": "Known as 'The Wall', Dravid batted for 44,152 minutes and faced 31,258 balls in Test cricket."
    },
    {
      "statement": "Glenn Maxwell scored the first double century in an ODI run chase (201* vs Afghanistan in 2023).",
      "is_true": true,
      "explanation": "Maxwell smashed 201* off 128 balls battling severe cramps to pull off a miracle chase from 91/7."
    },
    {
      "statement": "Herschelle Gibbs was the first cricketer to hit 6 sixes in an over in an international match.",
      "is_true": true,
      "explanation": "Gibbs smashed Daan van Bunge of Netherlands for 6 sixes in the 2007 ODI World Cup in St. Kitts."
    },
    {
      "statement": "South Africa successfully chased down a world-record 434 runs against Australia in the 2006 Johannesburg ODI.",
      "is_true": true,
      "explanation": "South Africa scored 438/9 with one ball to spare in one of the greatest matches ever played."
    },
    {
      "statement": "MS Dhoni holds the highest individual score by a wicket-keeper in ODI history: 183 not out.",
      "is_true": true,
      "explanation": "Dhoni smashed 183* off 145 balls against Sri Lanka in Jaipur in October 2005."
    },
    {
      "statement": "Brian Lara's 501 not out for Warwickshire in 1994 is the highest score in first-class cricket history.",
      "is_true": true,
      "explanation": "Lara scored 501* against Durham, the only quintuple-century in first-class cricket."
    },
    {
      "statement": "Sachin Tendulkar holds the record for the most dismissals in the nineties (90s) in international cricket.",
      "is_true": true,
      "explanation": "Sachin was out in the 90s a record 28 times in international cricket (18 in ODIs, 10 in Tests)."
    },
    {
      "statement": "Sanath Jayasuriya is the only player in cricket history with over 13,000 runs and 300 wickets in ODIs.",
      "is_true": true,
      "explanation": "Jayasuriya amassed 13,430 runs and 323 wickets in 445 ODIs."
    },
    {
      "statement": "Shakib Al Hasan scored 600+ runs and took 10+ wickets in a single ICC World Cup tournament (2019).",
      "is_true": true,
      "explanation": "Shakib is the only cricketer in World Cup history to achieve this rare all-round double in a single edition."
    },
    {
      "statement": "Allan Border was the first batter in Test cricket history to reach 11,000 career runs.",
      "is_true": true,
      "explanation": "The Australian captain reached the milestone in 1993 before retiring with 11,174 runs."
    },
    {
      "statement": "Clive Lloyd captained the West Indies to back-to-back ICC World Cup victories in 1975 and 1979.",
      "is_true": true,
      "explanation": "Lloyd led the legendary West Indian side that dominated early World Cup cricket."
    },
    {
      "statement": "Martin Guptill's 237 not out against the West Indies is the highest individual score in World Cup history.",
      "is_true": true,
      "explanation": "Guptill smashed 237* off 163 balls in the 2015 World Cup quarter-final in Wellington."
    },
    {
      "statement": "Anil Kumble bowled with a broken jaw against the West Indies in Antigua in 2002.",
      "is_true": true,
      "explanation": "Kumble returned with his face bandaged and famously dismissed Brian Lara in a heroic spell."
    },
  ];

  // Mini Game 4: Career Timeline
  List<CricketPlayer> _timelinePlayers = [];
  bool? _timelineCorrect;
  final List<String> _seenTimelineSets = [];

  static const List<List<String>> _timelineSets = [
    ["sachin_tendulkar", "ricky_ponting", "ms_dhoni", "virat_kohli"],
    ["wasim_akram", "shane_warne", "ab_de_villiers", "jasprit_bumrah"],
    ["brian_lara", "jacques_kallis", "rohit_sharma", "shaheen_afridi"],
    ["glenn_mcgrath", "chris_gayle", "dale_steyn", "pat_cummins"],
    ["muttiah_muralitharan", "kumar_sangakkara", "lasith_malinga", "rashid_khan"],
    ["kapil_dev", "anil_kumble", "yuvraj_singh", "jasprit_bumrah"],
    ["sunil_gavaskar", "wasim_akram", "ms_dhoni", "pat_cummins"],
    ["viv_richards", "brian_lara", "ab_de_villiers", "shaheen_afridi"],
    ["courtney_walsh", "jacques_kallis", "dale_steyn", "rashid_khan"],
    ["steve_waugh", "ricky_ponting", "ben_stokes", "pat_cummins"],
    ["sanath_jayasuriya", "kumar_sangakkara", "lasith_malinga", "shaheen_afridi"],
    ["sourav_ganguly", "ms_dhoni", "virat_kohli", "jasprit_bumrah"],
  ];

  // Mini Game 5: Guess the Player
  CricketPlayer? _guessTarget;
  List<String> _guessOptions = [];
  bool? _guessCorrect;
  final List<String> _seenGuessIds = [];
  final List<String> _seenWhoAmIIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initStatOrFictionOrder();
    _initWhoAmI();
    _initHigherLower();
    _initTimeline();
    _initGuessPlayer();
  }

  void _initStatOrFictionOrder() {
    final rand = Random();
    _sofOrder = List<int>.generate(_sofQuestions.length, (i) => i)..shuffle(rand);
    _sofOrderPos = 0;
    _sofIdx = _sofOrder[_sofOrderPos];
  }

  void _nextStatOrFiction() {
    _sofOrderPos++;
    if (_sofOrderPos >= _sofOrder.length) {
      _initStatOrFictionOrder();
    } else {
      _sofIdx = _sofOrder[_sofOrderPos];
    }
    _sofAnsweredCorrect = null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Career Timeline logic ---
  void _initTimeline() {
    final random = Random();
    var availableSets = _timelineSets.where((s) => !_seenTimelineSets.contains(s.join('_'))).toList();
    if (availableSets.isEmpty) {
      _seenTimelineSets.clear();
      availableSets = _timelineSets;
    }
    final chosenSet = availableSets[random.nextInt(availableSets.length)];
    _seenTimelineSets.add(chosenSet.join('_'));
    if (_seenTimelineSets.length > 50) {
      _seenTimelineSets.removeAt(0);
    }

    final players = chosenSet
        .map((id) => CricketDataset.getPlayerById(id))
        .where((p) => p != null)
        .cast<CricketPlayer>()
        .toList();

    _timelinePlayers = List<CricketPlayer>.from(players)..shuffle(random);
    _timelineCorrect = null;
  }

  int _getStartYear(CricketPlayer p) {
    try {
      final span = p.careerSpan;
      final start = span.split('–')[0].trim();
      return int.parse(start);
    } catch (_) {
      return 2000;
    }
  }

  void _verifyTimeline() {
    if (_timelineCorrect != null) return;
    bool isSorted = true;
    for (int i = 0; i < _timelinePlayers.length - 1; i++) {
      if (_getStartYear(_timelinePlayers[i]) > _getStartYear(_timelinePlayers[i + 1])) {
        isSorted = false;
        break;
      }
    }

    setState(() {
      _timelineCorrect = isSorted;
      if (isSorted) {
        _score += 80;
        _streak += 1;
      } else {
        _streak = 0;
      }
    });
    _recordChallengeActivity(isSorted ? 80 : 0, isSorted);
  }

  void _recordChallengeActivity(int pts, bool success) {
    try {
      final auth = ref.read(authProvider);
      if (!auth.isLoggedIn || auth.userId == null) return;
      ref.read(platformApiServiceProvider).recordGameResult(
        userId: auth.userId!,
        gameId: 'cricket',
        sectionId: 'challenges',
        outcome: success ? 'win' : 'loss',
        score: _score,
        details: {'points': pts, 'success': success, 'total_score': _score},
        extraStatsUpdate: {
          'challenges_completed': success ? 1 : 0,
          'challenge_points': pts,
        },
      );
    } catch (_) {}
  }

  // --- Who Am I logic ---
  List<String> _generateHardDistractors(CricketPlayer target, List<CricketPlayer> allPlayers) {
    // Pick candidates from the exact same country first
    var sameCountry = allPlayers
        .where((p) => p.id != target.id && p.country.toLowerCase() == target.country.toLowerCase())
        .toList()
      ..shuffle();

    List<CricketPlayer> chosen = [];
    // 1. Same country + same role
    for (var p in sameCountry.where((p) => p.role == target.role)) {
      if (chosen.length < 3 && !chosen.any((c) => c.id == p.id)) {
        chosen.add(p);
      }
    }
    // 2. Same country other roles
    for (var p in sameCountry) {
      if (chosen.length < 3 && !chosen.any((c) => c.id == p.id)) {
        chosen.add(p);
      }
    }
    // 3. Fallback: same role other countries
    if (chosen.length < 3) {
      var sameRole = allPlayers
          .where((p) => p.id != target.id && p.role == target.role && !chosen.any((c) => c.id == p.id))
          .toList()
        ..shuffle();
      for (var p in sameRole) {
        if (chosen.length < 3 && !chosen.any((c) => c.id == p.id)) {
          chosen.add(p);
        }
      }
    }
    // 4. Fallback: any other player
    if (chosen.length < 3) {
      var remaining = allPlayers
          .where((p) => p.id != target.id && !chosen.any((c) => c.id == p.id))
          .toList()
        ..shuffle();
      for (var p in remaining) {
        if (chosen.length < 3 && !chosen.any((c) => c.id == p.id)) {
          chosen.add(p);
        }
      }
    }

    final options = [target.name, ...chosen.take(3).map((p) => p.name)]..shuffle();
    return options;
  }

  void _initWhoAmI() {
    final random = Random();
    const all = CricketDataset.allPlayers;
    var candidates = all.where((p) => !_seenWhoAmIIds.contains(p.id)).toList();
    if (candidates.isEmpty) {
      _seenWhoAmIIds.clear();
      candidates = all;
    }

    _whoAmITarget = candidates[random.nextInt(candidates.length)];
    _seenWhoAmIIds.add(_whoAmITarget!.id);
    if (_seenWhoAmIIds.length > 50) {
      _seenWhoAmIIds.removeAt(0);
    }

    _revealedClues = 1;
    _whoAmICorrect = null;

    _whoAmIOptions = _generateHardDistractors(_whoAmITarget!, all);
  }

  List<String> _getWhoAmIClues(CricketPlayer t) {
    if (_whoAmICustomClues.containsKey(t.id)) {
      return _whoAmICustomClues[t.id]!;
    }
    return [
      "I represented ${t.country} on the international stage.",
      "My primary role was ${t.role} (${t.battingStyle}).",
      "My international career span was ${t.careerSpan}.",
      "I scored ${t.internationalRuns} International Runs & took ${t.internationalWickets} Wickets.",
      "In ODIs, I scored ${t.odiRuns} runs with ${t.odiCenturies} centuries.",
    ];
  }

  void _answerWhoAmI(String name) {
    if (_whoAmICorrect != null) return;
    final isCorrect = (name == _whoAmITarget!.name);
    final pts = isCorrect ? ((6 - _revealedClues) * 30) : 0;
    setState(() {
      _whoAmICorrect = isCorrect;
      if (isCorrect) {
        _score += pts;
        _streak += 1;
      } else {
        _streak = 0;
      }
    });
    _recordChallengeActivity(pts, isCorrect);
  }

  // --- Higher or Lower logic ---
  void _initHigherLower() {
    final random = Random();
    final selectedCat = _hlCategories[random.nextInt(_hlCategories.length)];
    _hlStatKey = selectedCat['key'] as String;
    _hlStatLabel = selectedCat['label'] as String;
    final allowedRoles = (selectedCat['roles'] as List<String>?) ?? [];

    const all = CricketDataset.allPlayers;
    final eligible = all.where((p) => allowedRoles.isEmpty || allowedRoles.contains(p.role)).toList();
    final pool = eligible.length >= 2 ? eligible : all;

    CricketPlayer p1 = pool[random.nextInt(pool.length)];
    CricketPlayer p2 = pool[random.nextInt(pool.length)];
    int attempts = 0;
    while ((p2.id == p1.id || _seenHlPairs.contains("${p1.id}_${p2.id}_$_hlStatKey")) && attempts < 30) {
      p1 = pool[random.nextInt(pool.length)];
      p2 = pool[random.nextInt(pool.length)];
      attempts++;
    }

    _hlPlayerA = p1;
    _hlPlayerB = p2;
    _seenHlPairs.add("${p1.id}_${p2.id}_$_hlStatKey");
    if (_seenHlPairs.length > 50) {
      _seenHlPairs.removeAt(0);
    }

    _hlCorrect = null;
  }

  void _answerHigherLower(bool guessedHigher) {
    if (_hlCorrect != null) return;
    final valA = _hlPlayerA!.getStatValue(_hlStatKey);
    final valB = _hlPlayerB!.getStatValue(_hlStatKey);

    final isHigher = valB >= valA;
    final isCorrect = (guessedHigher == isHigher);

    setState(() {
      _hlCorrect = isCorrect;
      if (isCorrect) {
        _score += 50;
        _streak += 1;
      } else {
        _streak = 0;
      }
    });
    _recordChallengeActivity(isCorrect ? 50 : 0, isCorrect);
  }

  // --- Guess the Player logic ---
  void _initGuessPlayer() {
    final random = Random();
    const all = CricketDataset.allPlayers;
    var candidates = all.where((p) => !_seenGuessIds.contains(p.id)).toList();
    if (candidates.isEmpty) {
      _seenGuessIds.clear();
      candidates = all;
    }

    _guessTarget = candidates[random.nextInt(candidates.length)];
    _seenGuessIds.add(_guessTarget!.id);
    if (_seenGuessIds.length > 50) {
      _seenGuessIds.removeAt(0);
    }

    _guessCorrect = null;

    _guessOptions = _generateHardDistractors(_guessTarget!, all);
  }

  void _answerGuessPlayer(String name) {
    if (_guessCorrect != null) return;
    final isCorrect = (name == _guessTarget!.name);
    setState(() {
      _guessCorrect = isCorrect;
      if (isCorrect) {
        _score += 60;
        _streak += 1;
      } else {
        _streak = 0;
      }
    });
    _recordChallengeActivity(isCorrect ? 60 : 0, isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1914),
      appBar: AppBar(
        backgroundColor: const Color(0xFF132B22),
        title: Text("CRICKET CHALLENGE HUB", style: GoogleFonts.dmSerifDisplay(color: const Color(0xFFF1EBDD))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFF1EBDD)),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF48BB78),
          labelColor: const Color(0xFF48BB78),
          unselectedLabelColor: const Color(0xFFA9A396),
          isScrollable: true,
          tabs: const [
            Tab(text: "Who Am I?"),
            Tab(text: "Higher or Lower"),
            Tab(text: "Stat or Fiction"),
            Tab(text: "Career Timeline"),
            Tab(text: "Guess The Legend"),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                // Top Score Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10231C),
                    border: Border(bottom: BorderSide(color: Color(0xFF1F3D30))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars, color: Color(0xFFE5A93C), size: 18),
                          const SizedBox(width: 6),
                          Text("Score: $_score", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Color(0xFFED8936), size: 18),
                          const SizedBox(width: 6),
                          Text("Streak: $_streak", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFED8936))),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildWhoAmIView(),
                      _buildHigherLowerView(),
                      _buildStatFictionView(),
                      _buildTimelineView(),
                      _buildGuessPlayerView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 1: Who Am I? ---
  Widget _buildWhoAmIView() {
    final t = _whoAmITarget;
    if (t == null) return const SizedBox();

    final clues = _getWhoAmIClues(t);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("PROGRESSIVE CLUES (Clue $_revealedClues of 5)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF48BB78))),
          const SizedBox(height: 12),
          ...List.generate(_revealedClues, (idx) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF142B20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF28543A)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: const Color(0xFF48BB78).withOpacity(0.2), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text("${idx + 1}", style: const TextStyle(fontSize: 11, color: Color(0xFF48BB78), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(clues[idx], style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFF1EBDD))),
                  ),
                ],
              ),
            );
          }),

          if (_revealedClues < 5 && _whoAmICorrect == null) ...[
            TextButton.icon(
              onPressed: () => setState(() => _revealedClues += 1),
              icon: const Icon(Icons.help_outline, size: 16, color: Color(0xFFE5A93C)),
              label: Text("Reveal Next Clue (-30 potential pts)", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE5A93C))),
            ),
          ],

          const SizedBox(height: 18),
          Text("WHO AM I?", style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD))),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: _whoAmIOptions.map((opt) {
              final isTarget = opt == t.name;
              Color bg = const Color(0xFF13241B);
              Color borderCol = const Color(0xFF233F30);

              if (_whoAmICorrect != null) {
                if (isTarget) {
                  bg = const Color(0xFF22543D);
                  borderCol = const Color(0xFF48BB78);
                }
              }

              return ElevatedButton(
                onPressed: _whoAmICorrect == null ? () => _answerWhoAmI(opt) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bg,
                  foregroundColor: const Color(0xFFF1EBDD),
                  side: BorderSide(color: borderCol),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(opt, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),

          if (_whoAmICorrect != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _whoAmICorrect! ? const Color(0xFF22543D) : const Color(0xFF742A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _whoAmICorrect! ? "CORRECT! It's ${t.name}!" : "WRONG! It was ${t.name}!",
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _initWhoAmI()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text("NEXT PLAYER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 2: Higher or Lower ---
  Widget _buildHigherLowerView() {
    final pA = _hlPlayerA;
    final pB = _hlPlayerB;
    if (pA == null || pB == null) return const SizedBox();

    final valA = pA.getStatValue(_hlStatKey);
    final valB = pB.getStatValue(_hlStatKey);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            "COMPARE STAT: $_hlStatLabel",
            style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFE5A93C)),
          ),
          const SizedBox(height: 20),

          // Player A Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF142B20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF28543A)),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: pA.avatarColor, child: Text(pA.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pA.name, style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFFF1EBDD))),
                      Text("${pA.country} • ${pA.role}", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF28543A), borderRadius: BorderRadius.circular(8)),
                  child: Text("$valA", style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFE5A93C))),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Icon(Icons.arrow_downward, color: Color(0xFF48BB78), size: 24),
          const SizedBox(height: 16),

          // Player B Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF142B20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF28543A)),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: pB.avatarColor, child: Text(pB.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pB.name, style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFFF1EBDD))),
                      Text("${pB.country} • ${pB.role}", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF28543A), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _hlCorrect != null ? "$valB" : "?",
                    style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFE5A93C)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFF1EBDD), height: 1.4),
              children: [
                const TextSpan(text: "Does "),
                TextSpan(text: pB.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE5A93C))),
                TextSpan(text: " have HIGHER or LOWER $_hlStatLabel than "),
                TextSpan(text: "${pA.name} ($valA)", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF81E6D9))),
                const TextSpan(text: "?"),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hlCorrect == null ? () => _answerHigherLower(true) : null,
                  icon: const Icon(Icons.trending_up),
                  label: const Text("HIGHER", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38A169),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hlCorrect == null ? () => _answerHigherLower(false) : null,
                  icon: const Icon(Icons.trending_down),
                  label: const Text("LOWER", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53E3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),

          if (_hlCorrect != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _hlCorrect! ? const Color(0xFF22543D) : const Color(0xFF742A2A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _hlCorrect! ? const Color(0xFF48BB78) : const Color(0xFFE53E3E)),
              ),
              child: Row(
                children: [
                  Icon(
                    _hlCorrect! ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hlCorrect! ? "CORRECT!" : "INCORRECT!",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          valB > valA
                              ? "${pB.name} ($valB) is HIGHER than ${pA.name} ($valA)."
                              : (valB < valA
                                  ? "${pB.name} ($valB) is LOWER than ${pA.name} ($valA)."
                                  : "${pB.name} and ${pA.name} are EQUAL ($valB)."),
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFF1EBDD)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => setState(() => _initHigherLower()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text("NEXT PAIR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 3: Stat or Fiction ---
  Widget _buildStatFictionView() {
    final q = _sofQuestions[_sofIdx % _sofQuestions.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("STAT OR FICTION? (Question ${_sofIdx + 1} of ${_sofQuestions.length})", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C))),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF142B20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF28543A)),
            ),
            child: Text(
              "\"${q['statement']}\"",
              style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD), height: 1.4),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _sofAnsweredCorrect == null
                      ? () {
                          final isRight = (q['is_true'] == true);
                          setState(() {
                            _sofAnsweredCorrect = isRight;
                            if (isRight) {
                              _score += 50;
                              _streak += 1;
                            } else {
                              _streak = 0;
                            }
                          });
                          _recordChallengeActivity(isRight ? 50 : 0, isRight);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38A169),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("TRUE (STAT)", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: _sofAnsweredCorrect == null
                      ? () {
                          final isRight = (q['is_true'] == false);
                          setState(() {
                            _sofAnsweredCorrect = isRight;
                            if (isRight) {
                              _score += 50;
                              _streak += 1;
                            } else {
                              _streak = 0;
                            }
                          });
                          _recordChallengeActivity(isRight ? 50 : 0, isRight);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53E3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("FALSE (FICTION)", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (_sofAnsweredCorrect != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _sofAnsweredCorrect! ? const Color(0xFF22543D) : const Color(0xFF742A2A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sofAnsweredCorrect! ? "CORRECT!" : "INCORRECT!",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    q['explanation'] as String,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _nextStatOrFiction();
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                        child: const Text("NEXT STATEMENT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 4: Guess The Legend ---
  Widget _buildGuessPlayerView() {
    final t = _guessTarget;
    if (t == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("IDENTIFY THE LEGEND FROM THE PROFILE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF48BB78))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF142B20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF28543A)),
            ),
            child: Column(
              children: [
                _buildProfileRow("Country", t.country),
                const Divider(color: Color(0xFF234432)),
                _buildProfileRow("Role", "${t.role} (${t.battingStyle})"),
                const Divider(color: Color(0xFF234432)),
                _buildProfileRow("Career Span", t.careerSpan),
                const Divider(color: Color(0xFF234432)),
                _buildProfileRow("Int'l Runs / Wickets", "${t.internationalRuns} Runs / ${t.internationalWickets} Wkts"),
                const Divider(color: Color(0xFF234432)),
                _buildProfileRow("ODI Centuries / Sixes", "${t.odiCenturies} Tons / ${t.internationalSixes} Sixes"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text("CHOOSE PLAYER", style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFFF1EBDD))),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: _guessOptions.map((opt) {
              return ElevatedButton(
                onPressed: _guessCorrect == null ? () => _answerGuessPlayer(opt) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13241B),
                  foregroundColor: const Color(0xFFF1EBDD),
                  side: const BorderSide(color: Color(0xFF233F30)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(opt, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
          if (_guessCorrect != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _guessCorrect! ? const Color(0xFF22543D) : const Color(0xFF742A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_guessCorrect! ? "CORRECT! ${t.name}" : "WRONG! It was ${t.name}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ElevatedButton(
                    onPressed: () => setState(() => _initGuessPlayer()),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    child: const Text("NEXT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 4: Career Timeline ---
  Widget _buildTimelineView() {
    if (_timelinePlayers.isEmpty) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ORDER LEGENDS CHRONOLOGICALLY",
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF48BB78)),
          ),
          const SizedBox(height: 6),
          Text(
            "Use the arrow buttons to arrange these 4 cricket legends from EARLIEST international debut to MOST RECENT.",
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
          ),
          const SizedBox(height: 18),

          ...List.generate(_timelinePlayers.length, (idx) {
            final p = _timelinePlayers[idx];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF142B20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF28543A)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: const Color(0xFF234432), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text("${idx + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF48BB78))),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: p.avatarColor,
                    child: Text(p.name[0], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                        Text(
                          _timelineCorrect != null ? "${p.country} • Debut: ${p.careerSpan}" : "${p.country} • ${p.role}",
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396)),
                        ),
                      ],
                    ),
                  ),
                  if (_timelineCorrect == null) ...[
                    if (idx > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_upward, size: 18, color: Color(0xFFE5A93C)),
                        onPressed: () {
                          setState(() {
                            final temp = _timelinePlayers[idx];
                            _timelinePlayers[idx] = _timelinePlayers[idx - 1];
                            _timelinePlayers[idx - 1] = temp;
                          });
                        },
                      ),
                    if (idx < _timelinePlayers.length - 1)
                      IconButton(
                        icon: const Icon(Icons.arrow_downward, size: 18, color: Color(0xFFE5A93C)),
                        onPressed: () {
                          setState(() {
                            final temp = _timelinePlayers[idx];
                            _timelinePlayers[idx] = _timelinePlayers[idx + 1];
                            _timelinePlayers[idx + 1] = temp;
                          });
                        },
                      ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          if (_timelineCorrect == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifyTimeline,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF48BB78),
                  foregroundColor: const Color(0xFF0F1E16),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("SUBMIT ORDER", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),

          if (_timelineCorrect != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _timelineCorrect! ? const Color(0xFF22543D) : const Color(0xFF742A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _timelineCorrect! ? "PERFECT TIMELINE ORDER!" : "INCORRECT ORDER!",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _initTimeline()),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    child: const Text("NEXT SET", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396))),
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
        ],
      ),
    );
  }
}
